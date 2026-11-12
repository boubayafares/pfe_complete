import { Pool, types } from 'pg';
import type { PoolClient, QueryResult, QueryResultRow } from 'pg';
import { env } from './env.js';
import { logger } from '../shared/logger/logger.js';

// PostgreSQL BIGINT/NUMERIC values are strings by default in node-postgres.
// FootTech identifiers remain far below Number.MAX_SAFE_INTEGER, and the
// Flutter contract expects JSON numbers. Normalize once at the DB boundary.
types.setTypeParser(20, (value) => Number.parseInt(value, 10));
types.setTypeParser(1700, (value) => Number.parseFloat(value));

export const pool = new Pool({
  host: env.DB_HOST,
  port: env.DB_PORT,
  database: env.DB_NAME,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  max: env.DB_POOL_MAX,
  ssl: env.DB_SSL ? { rejectUnauthorized: env.DB_SSL_REJECT_UNAUTHORIZED } : undefined,
  options: `-c search_path=${env.DB_SCHEMA}`,
});

pool.on('error', (err) => {
  logger.error('Unexpected PostgreSQL pool error', { error: err.message });
});

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params: unknown[] = []
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const result = await pool.query<T>(text, params as unknown[]);
    if (env.NODE_ENV === 'development') {
      logger.debug('Executed query', { text, duration: Date.now() - start, rows: result.rowCount });
    }
    return result;
  } catch (error) {
    // Never log parameter values: they may contain passwords, OTPs or PII.
    logger.error('Query failed', { text, parameterCount: params.length, error: (error as Error).message });
    throw error;
  }
}

export async function withTransaction<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function checkDatabaseConnection(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    logger.info('PostgreSQL connection OK');
  } finally {
    client.release();
  }
}

export async function closeDatabasePool(): Promise<void> {
  await pool.end();
}
