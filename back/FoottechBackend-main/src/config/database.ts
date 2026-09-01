import  {Pool}  from 'pg';
import type { PoolClient, QueryResult, QueryResultRow } from 'pg';
import { env } from './env.js';
import { logger } from '../shared/logger/logger.js';

export const pool = new Pool({
  host: env.DB_HOST,
  port: env.DB_PORT,
  database: env.DB_NAME,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  max: env.DB_POOL_MAX,
  ssl: env.DB_SSL ? { rejectUnauthorized: false } : undefined,
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
    logger.error('Query failed', { text, params, error: (error as Error).message });
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
