import { query } from '../../config/database.js';

export class DashboardRepository {
  async getUpcomingTraining(teamId: number) {
    const result = await query(
      `SELECT id, date, start_time, location FROM trainings
       WHERE team_id = $1 AND date >= CURRENT_DATE AND status = 'SCHEDULED'
       ORDER BY date ASC, start_time ASC LIMIT 1`,
      [teamId]
    );
    return result.rows[0] ?? null;
  }

  async getUpcomingMatch(teamId: number) {
    const result = await query(
      `SELECT id, adversaire, date_heure, lieu FROM matches
       WHERE team_id = $1 AND date_heure >= now() AND match_status = 'SCHEDULED'
       ORDER BY date_heure ASC LIMIT 1`,
      [teamId]
    );
    return result.rows[0] ?? null;
  }

  async getPendingProposalsCount(coachId: number) {
    const result = await query<{ count: string }>(
      `SELECT COUNT(*) FROM exercise_proposals ep
       INNER JOIN trainings t ON t.id = ep.training_id
       INNER JOIN teams tm ON tm.id = t.team_id
       WHERE tm.coach_id = $1 AND ep.status = 'PENDING'`,
      [coachId]
    );
    return result.rows[0] ? parseInt(result.rows[0].count, 10) : 0;
  }

  async getUnreadNotificationCount(userId: number) {
    const result = await query<{ count: string }>(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
      [userId]
    );
    return result.rows[0] ? parseInt(result.rows[0].count, 10) : 0;
  }

  async getTeamPlayerCount(teamId: number) {
    const result = await query<{ count: string }>('SELECT COUNT(*) FROM players WHERE team_id = $1', [teamId]);
    return result.rows[0] ? parseInt(result.rows[0].count, 10) : 0;
  }

  async getPlayerNextMatchStatus(playerId: number, matchId: number) {
    const result = await query<{ status: string }>(
      'SELECT status FROM match_lineups WHERE player_id = $1 AND match_id = $2',
      [playerId, matchId]
    );
    return result.rows[0]?.status ?? null;
  }

  /** Directly reproduces the club's Bilan_Cadet_A.xlsx via the player_season_bilan SQL view. */
  async getSeasonBilan(teamId: number, seasonId?: number) {
    const conditions = ['p.team_id = $1'];
    const params: unknown[] = [teamId];
    if (seasonId) {
      params.push(seasonId);
      conditions.push(`b.season_id = $${params.length}`);
    }
    const result = await query(
      `SELECT b.* FROM player_season_bilan b
       INNER JOIN players p ON p.id = b.player_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY b.total_buts DESC NULLS LAST`,
      params
    );
    return result.rows;
  }
}
