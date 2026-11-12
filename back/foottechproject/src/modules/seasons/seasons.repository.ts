import { query, withTransaction } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ SeasonRecord } from './seasons.interface.js';

export class SeasonsRepository extends BaseRepository<SeasonRecord> {
  constructor() {
    super('seasons');
  }

  async findAccessible(teamId: number): Promise<SeasonRecord[]> {
    const result = await query<SeasonRecord>(
      `SELECT * FROM seasons
       WHERE team_id = $1 OR team_id IS NULL
       ORDER BY start_date DESC, id DESC`,
      [teamId]
    );
    return result.rows;
  }

  async findAccessibleById(id: number, teamId: number): Promise<SeasonRecord | null> {
    const result = await query<SeasonRecord>(
      `SELECT * FROM seasons
       WHERE id = $1 AND (team_id = $2 OR team_id IS NULL)
       LIMIT 1`,
      [id, teamId]
    );
    return result.rows[0] ?? null;
  }

  async findOwnedById(id: number, teamId: number): Promise<SeasonRecord | null> {
    const result = await query<SeasonRecord>(
      'SELECT * FROM seasons WHERE id = $1 AND team_id = $2 LIMIT 1',
      [id, teamId]
    );
    return result.rows[0] ?? null;
  }

  async findByName(name: string, teamId: number): Promise<SeasonRecord | null> {
    const result = await query<SeasonRecord>(
      'SELECT * FROM seasons WHERE name = $1 AND team_id = $2 LIMIT 1',
      [name, teamId]
    );
    return result.rows[0] ?? null;
  }

  async isAccessible(id: number, teamId: number): Promise<boolean> {
    const result = await query(
      'SELECT 1 FROM seasons WHERE id = $1 AND (team_id = $2 OR team_id IS NULL) LIMIT 1',
      [id, teamId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  /** Atomically keeps at most one current season for the selected team. */
  async setCurrent(id: number, teamId: number): Promise<SeasonRecord | null> {
    return withTransaction(async (client) => {
      await client.query(
        'UPDATE seasons SET is_current = FALSE WHERE team_id = $1 AND is_current = TRUE',
        [teamId]
      );
      const result = await client.query<SeasonRecord>(
        `UPDATE seasons SET is_current = TRUE
         WHERE id = $1 AND team_id = $2
         RETURNING *`,
        [id, teamId]
      );
      return result.rows[0] ?? null;
    });
  }
}
