import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ NotificationRecord } from './notifications.interface.js';

export class NotificationsRepository extends BaseRepository<NotificationRecord> {
  constructor() {
    super('notifications');
  }

  async listForUser(userId: number): Promise<NotificationRecord[]> {
    const result = await query<NotificationRecord>(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100',
      [userId]
    );
    return result.rows;
  }

  async markAsRead(id: number, userId: number): Promise<void> {
    await query('UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2', [id, userId]);
  }

  async markAllAsRead(userId: number): Promise<void> {
    await query('UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE', [userId]);
  }

  /** All players + adjoints attached to a team (used for match/training broadcasts). */
  async getTeamMemberIds(teamId: number): Promise<number[]> {
    const result = await query<{ id: number }>(
      `SELECT id FROM players WHERE team_id = $1
       UNION
       SELECT adjoint_id AS id FROM team_staff WHERE team_id = $1`,
      [teamId]
    );
    return result.rows.map((r) => r.id);
  }

  async getTeamMemberContacts(teamId: number): Promise<Array<{ id: number; email: string | null; phone: string }>> {
    const result = await query<{ id: number; email: string | null; phone: string }>(
      `SELECT u.id, u.email, u.phone
       FROM users u
       WHERE u.id IN (
         SELECT id FROM players WHERE team_id = $1
         UNION
         SELECT adjoint_id AS id FROM team_staff WHERE team_id = $1
       )
       AND u.account_status <> 'BLOCKED'`,
      [teamId]
    );
    return result.rows;
  }

  async targetBelongsToTeam(
    targetType: 'MATCH' | 'TRAINING',
    targetId: number,
    teamId: number
  ): Promise<boolean> {
    const table = targetType === 'MATCH' ? 'matches' : 'trainings';
    const result = await query(
      `SELECT 1 FROM ${table} WHERE id = $1 AND team_id = $2 LIMIT 1`,
      [targetId, teamId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  async registerPushToken(userId: number, token: string, platform?: string): Promise<void> {
    await query(
      `INSERT INTO push_tokens (user_id, token, platform) VALUES ($1, $2, $3)
       ON CONFLICT (token) DO UPDATE SET user_id = EXCLUDED.user_id, platform = EXCLUDED.platform`,
      [userId, token, platform ?? null]
    );
  }

  async getPushTokensForUser(userId: number): Promise<string[]> {
    const result = await query<{ token: string }>(
      'SELECT token FROM push_tokens WHERE user_id = $1',
      [userId]
    );
    return result.rows.map((r) => r.token);
  }

  async getPushTokensForUsers(userIds: number[]): Promise<string[]> {
    if (userIds.length === 0) return [];
    const result = await query<{ token: string }>(
      'SELECT DISTINCT token FROM push_tokens WHERE user_id = ANY($1)',
      [userIds]
    );
    return result.rows.map((r) => r.token);
  }
}
