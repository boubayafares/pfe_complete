import { query, withTransaction } from '../../config/database.js';
import type { PoolClient } from 'pg';
import  { BaseRepository } from '../../shared/database/BaseRepository.js';
import type { ParsedPagination } from '../../shared/utils/pagination.js';
import type { TeamRecord, TeamStaffWithUser } from './teams.interface.js';
import type{ TeamListFilters } from './teams.types.js';
import type{ AddAdjointDto } from './teams.dto.js';
import { ConflictError, NotFoundError } from '../../shared/errors/AppError.js';

export class TeamsRepository extends BaseRepository<TeamRecord> {
  constructor() {
    super('teams');
  }

  async findWithFilters(
    filters: TeamListFilters,
    pagination: ParsedPagination
  ): Promise<{ rows: TeamRecord[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (filters.id) {
      params.push(filters.id);
      conditions.push(`id = $${params.length}`);
    }
    if (filters.coachId) {
      params.push(filters.coachId);
      conditions.push(`coach_id = $${params.length}`);
    }
    if (filters.category) {
      params.push(filters.category);
      conditions.push(`category = $${params.length}`);
    }
    if (filters.search) {
      params.push(`%${filters.search}%`);
      conditions.push(`name ILIKE $${params.length}`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const countResult = await query<{ count: string }>(`SELECT COUNT(*) FROM teams ${whereClause}`, params);

    params.push(pagination.limit, pagination.offset);
    const rowsResult = await query<TeamRecord>(
      `SELECT * FROM teams ${whereClause} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return { rows: rowsResult.rows, total: parseInt(countResult.rows[0]?.count ?? '0', 10) };
  }

  async getStaff(teamId: number): Promise<TeamStaffWithUser[]> {
    const result = await query<TeamStaffWithUser>(
      `SELECT ts.*, u.first_name, u.last_name, u.email, u.phone, u.account_status
       FROM team_staff ts INNER JOIN users u ON u.id = ts.adjoint_id
       WHERE ts.team_id = $1 ORDER BY ts.added_at DESC`,
      [teamId]
    );
    return result.rows;
  }

  /**
   * Creates the Adjoint's user account (INACTIVE, no password yet — they
   * activate via POST /auth/set-adjoint-password) and links them to the
   * team, in one transaction.
   */
  async addAdjoint(teamId: number, addedBy: number, dto: AddAdjointDto): Promise<TeamStaffWithUser> {
    const existingEmail = await query('SELECT 1 FROM users WHERE email = $1', [dto.email]);
    if ((existingEmail.rowCount ?? 0) > 0) {
      throw new ConflictError('An account with this email already exists');
    }
    const existingPhone = await query('SELECT 1 FROM users WHERE phone = $1', [dto.phone]);
    if ((existingPhone.rowCount ?? 0) > 0) {
      throw new ConflictError('An account with this phone number already exists');
    }

    return withTransaction(async (client: PoolClient) => {
      const userResult = await client.query(
        `INSERT INTO users (first_name, last_name, phone, email, account_status)
         VALUES ($1, $2, $3, $4, 'INACTIVE') RETURNING id`,
        [dto.firstName, dto.lastName, dto.phone, dto.email]
      );
      const adjointId = userResult.rows[0].id as number;

      const roleResult = await client.query(`SELECT id FROM roles WHERE name = 'ADJOINT'`);
      await client.query(`INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)`, [adjointId, roleResult.rows[0].id]);

      const staffResult = await client.query(
        `INSERT INTO team_staff (team_id, adjoint_id, added_by) VALUES ($1, $2, $3) RETURNING *`,
        [teamId, adjointId, addedBy]
      );

      return {
        ...staffResult.rows[0],
        first_name: dto.firstName,
        last_name: dto.lastName,
        email: dto.email,
        phone: dto.phone,
        account_status: 'INACTIVE',
      } as TeamStaffWithUser;
    });
  }

  async removeAdjoint(teamId: number, adjointId: number): Promise<void> {
    const result = await query(
      'DELETE FROM team_staff WHERE team_id = $1 AND adjoint_id = $2',
      [teamId, adjointId]
    );
    if ((result.rowCount ?? 0) === 0) throw new NotFoundError('Team staff assignment');
  }
}
