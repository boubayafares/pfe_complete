import type{ QueryResultRow } from 'pg';
import { query } from '../../config/database.js';
import type{ ParsedPagination } from '../utils/pagination.js';

export class BaseRepository<T extends QueryResultRow> {
  constructor(
    protected readonly table: string,
    protected readonly primaryKey: string = 'id'
  ) {}

  async findAll(pagination?: ParsedPagination, orderBy = `${this.primaryKey} DESC`): Promise<T[]> {
    if (pagination) {
      const result = await query<T>(
        `SELECT * FROM ${this.table} ORDER BY ${orderBy} LIMIT $1 OFFSET $2`,
        [pagination.limit, pagination.offset]
      );
      return result.rows;
    }
    const result = await query<T>(`SELECT * FROM ${this.table} ORDER BY ${orderBy}`);
    return result.rows;
  }

  async count(): Promise<number> {
    const result = await query<{ count: string }>(`SELECT COUNT(*) FROM ${this.table}`);
    return parseInt(result.rows[0]?.count ?? '0', 10);
  }

  async findById(id: number | string): Promise<T | null> {
    const result = await query<T>(`SELECT * FROM ${this.table} WHERE ${this.primaryKey} = $1 LIMIT 1`, [id]);
    return result.rows[0] ?? null;
  }

  async findOneBy(column: string, value: unknown): Promise<T | null> {
    const result = await query<T>(`SELECT * FROM ${this.table} WHERE ${column} = $1 LIMIT 1`, [value]);
    return result.rows[0] ?? null;
  }

  async findManyBy(column: string, value: unknown, pagination?: ParsedPagination): Promise<T[]> {
    if (pagination) {
      const result = await query<T>(
        `SELECT * FROM ${this.table} WHERE ${column} = $1 ORDER BY ${this.primaryKey} DESC LIMIT $2 OFFSET $3`,
        [value, pagination.limit, pagination.offset]
      );
      return result.rows;
    }
    const result = await query<T>(
      `SELECT * FROM ${this.table} WHERE ${column} = $1 ORDER BY ${this.primaryKey} DESC`,
      [value]
    );
    return result.rows;
  }

  async create(data: Record<string, unknown>): Promise<T> {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
    const result = await query<T>(
      `INSERT INTO ${this.table} (${columns.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
    );
    return result.rows[0]!;
  }

  async update(id: number | string, data: Record<string, unknown>): Promise<T | null> {
    const columns = Object.keys(data);
    if (columns.length === 0) return this.findById(id);
    const values = Object.values(data);
    const setClause = columns.map((col, i) => `${col} = $${i + 1}`).join(', ');
    const result = await query<T>(
      `UPDATE ${this.table} SET ${setClause} WHERE ${this.primaryKey} = $${columns.length + 1} RETURNING *`,
      [...values, id]
    );
    return result.rows[0] ?? null;
  }

  async delete(id: number | string): Promise<boolean> {
    const result = await query(`DELETE FROM ${this.table} WHERE ${this.primaryKey} = $1`, [id]);
    return (result.rowCount ?? 0) > 0;
  }

  /** Upsert on a unique constraint — used a lot here (guardians, season profile, attendance...). */
  async upsert(data: Record<string, unknown>, conflictColumns: string[]): Promise<T> {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
    const updateSet = columns
      .filter((c) => !conflictColumns.includes(c))
      .map((c) => `${c} = EXCLUDED.${c}`)
      .join(', ');
    const result = await query<T>(
      `INSERT INTO ${this.table} (${columns.join(', ')}) VALUES (${placeholders})
       ON CONFLICT (${conflictColumns.join(', ')}) DO UPDATE SET ${updateSet}
       RETURNING *`,
      values
    );
    return result.rows[0]!;
  }
}
