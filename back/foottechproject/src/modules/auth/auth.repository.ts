import { query, withTransaction } from '../../config/database.js';
import type{ PoolClient } from 'pg';
import type{ UserRecord, RoleRecord, RefreshTokenRecord, ActivationCodeRecord } from './auth.interface.js';

export class AuthRepository {
  async findUserByEmail(email: string): Promise<UserRecord | null> {
    const result = await query<UserRecord>('SELECT * FROM users WHERE email = $1', [email]);
    return result.rows[0] ?? null;
  }

  async findUserByPhone(phone: string): Promise<UserRecord | null> {
    const result = await query<UserRecord>('SELECT * FROM users WHERE phone = $1', [phone]);
    return result.rows[0] ?? null;
  }

  async findUserById(id: number): Promise<UserRecord | null> {
    const result = await query<UserRecord>('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0] ?? null;
  }

  async findRoleByName(name: string): Promise<RoleRecord | null> {
    const result = await query<RoleRecord>('SELECT * FROM roles WHERE name = $1', [name]);
    return result.rows[0] ?? null;
  }

  async getUserRole(userId: number): Promise<'COACH' | 'ADJOINT' | 'JOUEUR' | null> {
    const result = await query<{ name: 'COACH' | 'ADJOINT' | 'JOUEUR' }>(
      `SELECT r.name FROM roles r INNER JOIN user_roles ur ON ur.role_id = r.id WHERE ur.user_id = $1 LIMIT 1`,
      [userId]
    );
    return result.rows[0]?.name ?? null;
  }

  /** Registers a brand new Coach: user row + COACH role, created INACTIVE until they confirm via OTP. */
  async createCoach(params: {
    firstName: string; lastName: string; phone: string; email: string; passwordHash: string;
  }): Promise<UserRecord> {
    return withTransaction(async (client: PoolClient) => {
      const userResult = await client.query<UserRecord>(
        `INSERT INTO users (first_name, last_name, phone, email, password_hash, account_status)
         VALUES ($1, $2, $3, $4, $5, 'INACTIVE') RETURNING *`,
        [params.firstName, params.lastName, params.phone, params.email, params.passwordHash]
      );
      const user = userResult.rows[0]!;
      const roleResult = await client.query<RoleRecord>(`SELECT * FROM roles WHERE name = 'COACH'`);
      await client.query(`INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)`, [user.id, roleResult.rows[0]!.id]);
      return user;
    });
  }

  async setPassword(userId: number, passwordHash: string): Promise<void> {
    await query('UPDATE users SET password_hash = $1 WHERE id = $2', [passwordHash, userId]);
  }

  async isAdjointManagedByCoach(adjointId: number, coachId: number): Promise<boolean> {
    const result = await query(
      `SELECT 1
       FROM team_staff ts
       INNER JOIN teams t ON t.id = ts.team_id
       WHERE ts.adjoint_id = $1 AND t.coach_id = $2
       LIMIT 1`,
      [adjointId, coachId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  async updateAccountStatus(userId: number, status: 'ACTIVE' | 'INACTIVE' | 'BLOCKED'): Promise<void> {
    await query('UPDATE users SET account_status = $1 WHERE id = $2', [status, userId]);
  }

  // --- Refresh tokens ---------------------------------------------------

  async storeRefreshToken(userId: number, tokenHash: string, expiresAt: Date): Promise<RefreshTokenRecord> {
    const result = await query<RefreshTokenRecord>(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3) RETURNING *`,
      [userId, tokenHash, expiresAt]
    );
    return result.rows[0]!;
  }

  async findRefreshTokenByHash(tokenHash: string): Promise<RefreshTokenRecord | null> {
    const result = await query<RefreshTokenRecord>('SELECT * FROM refresh_tokens WHERE token_hash = $1', [tokenHash]);
    return result.rows[0] ?? null;
  }

  async revokeRefreshToken(id: number): Promise<void> {
    await query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [id]);
  }

  async revokeAllUserRefreshTokens(userId: number): Promise<void> {
    await query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1', [userId]);
  }

  // --- OTP / activation codes -------------------------------------------

  async createActivationCode(userId: number, code: string, channel: 'SMS' | 'WHATSAPP', expiresAt: Date): Promise<ActivationCodeRecord> {
    const result = await query<ActivationCodeRecord>(
      `INSERT INTO activation_codes (user_id, code, channel, expires_at) VALUES ($1, $2, $3, $4) RETURNING *`,
      [userId, code, channel, expiresAt]
    );
    return result.rows[0]!;
  }

  async findLatestActivationCode(userId: number): Promise<ActivationCodeRecord | null> {
    const result = await query<ActivationCodeRecord>(
      `SELECT * FROM activation_codes WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );
    return result.rows[0] ?? null;
  }

  async markActivationCodeUsed(id: number): Promise<void> {
    await query('UPDATE activation_codes SET used = TRUE WHERE id = $1', [id]);
  }

  async userHasTeamAccess(
    userId: number,
    role: 'COACH' | 'ADJOINT' | 'JOUEUR',
    teamId: number
  ): Promise<boolean> {
    if (role === 'COACH') {
      const result = await query('SELECT 1 FROM teams WHERE id = $1 AND coach_id = $2', [teamId, userId]);
      return (result.rowCount ?? 0) > 0;
    }
    if (role === 'ADJOINT') {
      const result = await query('SELECT 1 FROM team_staff WHERE team_id = $1 AND adjoint_id = $2', [teamId, userId]);
      return (result.rowCount ?? 0) > 0;
    }
    const result = await query('SELECT 1 FROM players WHERE id = $1 AND team_id = $2', [userId, teamId]);
    return (result.rowCount ?? 0) > 0;
  }

  /** Resolves the default or explicitly selected team for the user. */
  async getTeamIdForUser(
    userId: number,
    role: 'COACH' | 'ADJOINT' | 'JOUEUR',
    preferredTeamId?: number
  ): Promise<number | null> {
    if (preferredTeamId !== undefined) {
      return (await this.userHasTeamAccess(userId, role, preferredTeamId)) ? preferredTeamId : null;
    }
    if (role === 'COACH') {
      const result = await query<{ id: number }>('SELECT id FROM teams WHERE coach_id = $1 ORDER BY created_at ASC, id ASC LIMIT 1', [userId]);
      return result.rows[0]?.id ?? null;
    }
    if (role === 'ADJOINT') {
      const result = await query<{ team_id: number }>(
        'SELECT team_id FROM team_staff WHERE adjoint_id = $1 ORDER BY added_at ASC, team_id ASC LIMIT 1',
        [userId]
      );
      return result.rows[0]?.team_id ?? null;
    }
    const result = await query<{ team_id: number | null }>('SELECT team_id FROM players WHERE id = $1', [userId]);
    return result.rows[0]?.team_id ?? null;
  }
}
