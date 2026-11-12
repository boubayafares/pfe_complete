import type { PoolClient } from 'pg';
import { env } from './env.js';
import { withTransaction } from './database.js';
import { logger } from '../shared/logger/logger.js';

interface Migration {
  id: string;
  run: (client: PoolClient, schema: string) => Promise<void>;
}

function quoteIdentifier(identifier: string): string {
  // DB_SCHEMA is validated at environment load; quoting also keeps the SQL
  // correct if a future valid identifier contains uppercase characters.
  return `"${identifier.replaceAll('"', '""')}"`;
}

const migrations: Migration[] = [
  {
    id: '20260902_activation_code_hmac',
    run: async (client, schema) => {
      const table = `${quoteIdentifier(schema)}."activation_codes"`;
      // Plaintext legacy OTP rows must never become valid again after the
      // column starts storing HMAC-SHA256 digests.
      await client.query(
        `UPDATE ${table}
         SET used = TRUE
         WHERE used = FALSE AND code !~ '^[0-9a-f]{64}$'`
      );
      await client.query(
        `ALTER TABLE ${table}
         ALTER COLUMN code TYPE VARCHAR(64)`
      );
    },
  },
  {
    id: '20260902_team_scoped_seasons',
    run: async (client, schema) => {
      const seasons = `${quoteIdentifier(schema)}."seasons"`;
      const teams = `${quoteIdentifier(schema)}."teams"`;

      // Existing rows intentionally keep a null team_id. They remain visible
      // to every team as legacy reference data, while the API makes them
      // read-only. New rows are always owned by the authenticated team.
      await client.query(
        `ALTER TABLE ${seasons}
         ADD COLUMN IF NOT EXISTS team_id BIGINT REFERENCES ${teams}(id) ON DELETE CASCADE`
      );
      await client.query(`ALTER TABLE ${seasons} DROP CONSTRAINT IF EXISTS seasons_name_key`);
      await client.query(
        `CREATE INDEX IF NOT EXISTS "idx_seasons_team"
         ON ${seasons}(team_id)`
      );
      await client.query(
        `CREATE UNIQUE INDEX IF NOT EXISTS "uq_seasons_team_name"
         ON ${seasons}(team_id, name) WHERE team_id IS NOT NULL`
      );
      await client.query(
        `CREATE UNIQUE INDEX IF NOT EXISTS "uq_seasons_current_per_team"
         ON ${seasons}(team_id) WHERE is_current = TRUE AND team_id IS NOT NULL`
      );
    },
  },
  {
    id: '20260902_team_scoped_exercise_proposals',
    run: async (client, schema) => {
      const proposals = `${quoteIdentifier(schema)}."exercise_proposals"`;
      const trainings = `${quoteIdentifier(schema)}."trainings"`;
      const staff = `${quoteIdentifier(schema)}."team_staff"`;
      const teams = `${quoteIdentifier(schema)}."teams"`;

      await client.query(
        `ALTER TABLE ${proposals}
         ADD COLUMN IF NOT EXISTS team_id BIGINT REFERENCES ${teams}(id) ON DELETE CASCADE`
      );
      // A linked training gives an unambiguous owner for legacy rows.
      await client.query(
        `UPDATE ${proposals} ep
         SET team_id = t.team_id
         FROM ${trainings} t
         WHERE ep.team_id IS NULL AND ep.training_id = t.id`
      );
      // An unlinked legacy proposal can be migrated safely only when the
      // assistant belonged to exactly one team.
      await client.query(
        `UPDATE ${proposals} ep
         SET team_id = membership.team_id
         FROM (
           SELECT adjoint_id, MIN(team_id) AS team_id
           FROM ${staff}
           GROUP BY adjoint_id
           HAVING COUNT(DISTINCT team_id) = 1
         ) membership
         WHERE ep.team_id IS NULL
           AND ep.training_id IS NULL
           AND ep.proposed_by = membership.adjoint_id`
      );
      await client.query(
        `CREATE INDEX IF NOT EXISTS "idx_exerciseproposals_team"
         ON ${proposals}(team_id)`
      );
    },
  },
  {
    id: '20260906_tactical_exercise_library',
    run: async (client, schema) => {
      const proposals = `${quoteIdentifier(schema)}."exercise_proposals"`;

      await client.query(
        `ALTER TABLE ${proposals}
         ADD COLUMN IF NOT EXISTS category VARCHAR(80),
         ADD COLUMN IF NOT EXISTS objectif VARCHAR(200),
         ADD COLUMN IF NOT EXISTS difficulty VARCHAR(30) DEFAULT 'MEDIUM',
         ADD COLUMN IF NOT EXISTS duration_minutes INTEGER,
         ADD COLUMN IF NOT EXISTS visibility VARCHAR(30) DEFAULT 'TEAM',
         ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
         ADD COLUMN IF NOT EXISTS canvas_data JSONB DEFAULT '{}'::jsonb,
         ADD COLUMN IF NOT EXISTS animation_data JSONB DEFAULT '{}'::jsonb,
         ADD COLUMN IF NOT EXISTS ai_model JSONB DEFAULT '{}'::jsonb`
      );
      await client.query(
        `CREATE INDEX IF NOT EXISTS "idx_exerciseproposals_visibility"
         ON ${proposals}(visibility)`
      );
      await client.query(
        `CREATE INDEX IF NOT EXISTS "idx_exerciseproposals_tags"
         ON ${proposals} USING GIN(tags)`
      );
    },
  },
];

/** Run small, idempotently recorded compatibility migrations on startup. */
export async function runDatabaseMigrations(): Promise<void> {
  const schema = env.DB_SCHEMA;
  const migrationTable = `${quoteIdentifier(schema)}."schema_migrations"`;

  await withTransaction(async (client) => {
    // Serialize competing API replicas during a rolling deployment.
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', ['foottech-schema-migrations']);
    await client.query(
      `CREATE TABLE IF NOT EXISTS ${migrationTable} (
         id VARCHAR(150) PRIMARY KEY,
         applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
       )`
    );

    const applied = await client.query<{ id: string }>(`SELECT id FROM ${migrationTable}`);
    const appliedIds = new Set(applied.rows.map((row) => row.id));

    for (const migration of migrations) {
      if (appliedIds.has(migration.id)) continue;
      await migration.run(client, schema);
      await client.query(`INSERT INTO ${migrationTable} (id) VALUES ($1)`, [migration.id]);
      logger.info('Database migration applied', { migration: migration.id });
    }
  });
}
