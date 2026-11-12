import { query, withTransaction } from '../../config/database.js';
import type{ PoolClient } from 'pg';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{
  MatchRecord,
  MatchLineupWithPlayer,
  AiLineupRecommendationRecord,
  MatchEventRecord,
  MatchPlayerStatRecord,
  MatchEvaluationRecord,
  MatchReportRecord,
} from './matches.interface.js';
import type{ SetLineupEntryDto } from './matches.dto.js';
import type{ LineUpPlayerInput, LineUpRecommendation } from '../../shared/clients/lineup.client.js';

export class MatchesRepository extends BaseRepository<MatchRecord> {
  constructor() {
    super('matches');
  }

  async findWithFilters(filters: { teamId?: number; seasonId?: number; status?: string }): Promise<MatchRecord[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    if (filters.teamId) {
      params.push(filters.teamId);
      conditions.push(`team_id = $${params.length}`);
    }
    if (filters.seasonId) {
      params.push(filters.seasonId);
      conditions.push(`season_id = $${params.length}`);
    }
    if (filters.status) {
      params.push(filters.status);
      conditions.push(`match_status = $${params.length}`);
    }
    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query<MatchRecord>(`SELECT * FROM matches ${whereClause} ORDER BY date_heure DESC`, params);
    return result.rows;
  }

  async updateStatus(id: number, status: string): Promise<MatchRecord | null> {
    const result = await query<MatchRecord>(
      `UPDATE matches SET match_status = $1 WHERE id = $2 RETURNING *`,
      [status, id]
    );
    return result.rows[0] ?? null;
  }

  async playersBelongToMatchTeam(matchId: number, playerIds: number[]): Promise<boolean> {
    const uniqueIds = [...new Set(playerIds)];
    if (uniqueIds.length === 0) return true;
    const result = await query<{ count: number }>(
      `SELECT COUNT(DISTINCT p.id)::int AS count
       FROM matches m
       INNER JOIN players p ON p.team_id = m.team_id
       WHERE m.id = $1 AND p.id = ANY($2::bigint[])`,
      [matchId, uniqueIds]
    );
    return Number(result.rows[0]?.count ?? 0) === uniqueIds.length;
  }

  // --- Lineup ------------------------------------------------------------

  async setLineup(matchId: number, entries: SetLineupEntryDto[], selectedBy: number): Promise<MatchLineupWithPlayer[]> {
    await withTransaction(async (client: PoolClient) => {
      for (const entry of entries) {
        await client.query(
          `INSERT INTO match_lineups (match_id, player_id, status, position_terrain, selected_by)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (match_id, player_id) DO UPDATE SET
             status = EXCLUDED.status, position_terrain = EXCLUDED.position_terrain, selected_by = EXCLUDED.selected_by`,
          [matchId, entry.playerId, entry.status, entry.positionTerrain ?? null, selectedBy]
        );
      }
    });
    return this.getLineup(matchId);
  }

  async getLineup(matchId: number): Promise<MatchLineupWithPlayer[]> {
    const result = await query<MatchLineupWithPlayer>(
      `SELECT ml.id,
              m.id AS match_id,
              p.id AS player_id,
              COALESCE(ml.status::text, 'NOT_SELECTED') AS status,
              ml.position_terrain,
              ml.selected_by,
              u.first_name,
              u.last_name,
              p.numero_maillot
       FROM matches m
       INNER JOIN players p ON p.team_id = m.team_id
       INNER JOIN users u ON u.id = p.id
       LEFT JOIN match_lineups ml
         ON ml.match_id = m.id AND ml.player_id = p.id
       WHERE m.id = $1
         AND u.account_status <> 'BLOCKED'
       ORDER BY CASE COALESCE(ml.status::text, 'NOT_SELECTED')
                  WHEN 'STARTER' THEN 1
                  WHEN 'SUBSTITUTE' THEN 2
                  ELSE 3
                END,
                p.numero_maillot NULLS LAST,
                u.last_name,
                u.first_name`,
      [matchId]
    );
    return result.rows;
  }

  // --- AI lineup scoring ----------------------------------------------------

  /**
   * Extracts the per-player features required by lineup-recommendation-service.
   * The scoring itself (weights, thresholds, fatigue model) lives in the Python
   * microservice — single source of truth. Express only gathers the inputs:
   *  - presence                        : attendance rate over the team's last 10 trainings (0-1)
   *  - recentPerformanceRating         : average evaluation note (0-10)
   *  - acuteChronicWorkloadRatio       : 7-day / 28-day playing load ratio (ACWR proxy)
   *  - daysSinceLastMatch              : rest days since the player's previous match
   */
  async getLineUpFeatures(matchId: number, teamId: number, candidatePlayerIds?: number[]): Promise<LineUpPlayerInput[]> {
    const matchResult = await query<MatchRecord>('SELECT * FROM matches WHERE id = $1', [matchId]);
    const match = matchResult.rows[0];
    if (!match) throw new Error('Match not found');

    const playerFilter = candidatePlayerIds && candidatePlayerIds.length
      ? `AND p.id = ANY($2::bigint[])`
      : '';
    const params: unknown[] = [teamId];
    if (candidatePlayerIds && candidatePlayerIds.length) params.push(candidatePlayerIds);

    const squadResult = await query<{ id: number }>(
      `SELECT p.id FROM players p WHERE p.team_id = $1 ${playerFilter}`,
      params
    );

    const targetDate = match.date_heure instanceof Date
      ? match.date_heure
      : new Date(match.date_heure as unknown as string);

    const features: LineUpPlayerInput[] = [];

    for (const player of squadResult.rows) {
      const presenceResult = await query<{ rate: number | null }>(
        `SELECT AVG(CASE WHEN a.status = 'PRESENT' THEN 1 ELSE 0 END)::float AS rate
         FROM attendances a
         INNER JOIN trainings t ON t.id = a.training_id
         WHERE a.player_id = $1 AND t.team_id = $2
         AND t.id IN (SELECT id FROM trainings WHERE team_id = $2 ORDER BY date DESC LIMIT 10)`,
        [player.id, teamId]
      );
      const presenceRate = presenceResult.rows[0]?.rate ?? 0.5;

      const performanceResult = await query<{ avg_note: number | null }>(
        `SELECT AVG(note)::float AS avg_note FROM (
           SELECT me.note FROM match_evaluations me
           INNER JOIN matches m ON m.id = me.match_id
           WHERE me.player_id = $1 AND m.team_id = $2 AND me.note IS NOT NULL
           ORDER BY m.date_heure DESC LIMIT 5
         ) recent`,
        [player.id, teamId]
      );
      const recentPerformanceRating = performanceResult.rows[0]?.avg_note ?? 5.0;

      // ACWR proxy: acute = load over the last 7 days, chronic = load over the last 28 days.
      const loadResult = await query<{ acute_min: number | null; chronic_min: number | null }>(
        `SELECT
           SUM(CASE WHEN m.date_heure >= $2 THEN mps.minutes_played ELSE 0 END)::int AS acute_min,
           SUM(CASE WHEN m.date_heure >= $3 THEN mps.minutes_played ELSE 0 END)::int AS chronic_min
         FROM match_player_stats mps
         INNER JOIN matches m ON m.id = mps.match_id
         WHERE mps.player_id = $1 AND m.date_heure < $4`,
        [player.id, new Date(targetDate.getTime() - 7 * 86_400_000), new Date(targetDate.getTime() - 28 * 86_400_000), targetDate]
      );
      const acute = loadResult.rows[0]?.acute_min ?? 0;
      const chronic = loadResult.rows[0]?.chronic_min ?? 0;
      const acuteChronicWorkloadRatio = chronic > 0 ? Math.min(3, Math.max(0, acute / chronic)) : 1.0;

      const lastMatchResult = await query<{ last_date: Date | null }>(
        `SELECT MAX(m.date_heure) AS last_date
         FROM match_player_stats mps
         INNER JOIN matches m ON m.id = mps.match_id
         WHERE mps.player_id = $1 AND m.date_heure < $2`,
        [player.id, targetDate]
      );
      const lastDate = lastMatchResult.rows[0]?.last_date;
      const daysSinceLastMatch = lastDate
        ? Math.max(0, Math.floor((targetDate.getTime() - new Date(lastDate).getTime()) / 86_400_000))
        : 4;

      features.push({
        playerId: player.id,
        presenceRate,
        recentPerformanceRating,
        acuteChronicWorkloadRatio,
        daysSinceLastMatch,
      });
    }

    return features;
  }

  /**
   * Persists the recommendations returned by lineup-recommendation-service.
   * The service scores on a 0-100 scale; the schema stores 0-1, so scores are
   * normalized (score/100) on insert. recommended_status comes from FastAPI.
   */
  async storeLineUpRecommendations(matchId: number, recommendations: LineUpRecommendation[]): Promise<AiLineupRecommendationRecord[]> {
    const results: AiLineupRecommendationRecord[] = [];

    for (const rec of recommendations) {
      const insertResult = await query<AiLineupRecommendationRecord>(
        `INSERT INTO ai_lineup_recommendations
           (match_id, player_id, presence_score, performance_score, fatigue_score, final_score, recommended_status)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (match_id, player_id) DO UPDATE SET
           presence_score = EXCLUDED.presence_score, performance_score = EXCLUDED.performance_score,
           fatigue_score = EXCLUDED.fatigue_score, final_score = EXCLUDED.final_score,
           recommended_status = EXCLUDED.recommended_status, generated_at = now()
         RETURNING *`,
        [
          matchId,
          rec.playerId,
          normalizeScore(rec.presenceScore),
          normalizeScore(rec.performanceScore),
          normalizeScore(rec.fatigueScore),
          normalizeScore(rec.finalScore),
          rec.recommendedStatus,
        ]
      );
      if (insertResult.rows[0]) {
        results.push(insertResult.rows[0]);
      }
    }

    return results.sort((a, b) => (b.final_score ?? 0) - (a.final_score ?? 0));
  }

  async listRecommendations(matchId: number): Promise<AiLineupRecommendationRecord[]> {
    const result = await query<AiLineupRecommendationRecord>(
      `SELECT * FROM ai_lineup_recommendations WHERE match_id = $1 ORDER BY final_score DESC NULLS LAST`,
      [matchId]
    );
    return result.rows;
  }

  // --- Live events ---------------------------------------------------------------

  async createEvent(matchId: number, data: Record<string, unknown>): Promise<MatchEventRecord> {
    return withTransaction(async (client: PoolClient) => {
      const result = await client.query<MatchEventRecord>(
        `INSERT INTO match_events (match_id, event_type, minute, player_id, related_player_id, comment, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [matchId, data.event_type, data.minute, data.player_id ?? null, data.related_player_id ?? null, data.comment ?? null, data.created_by ?? null]
      );

      if (data.event_type === 'GOAL') {
        const match = await client.query<Pick<MatchRecord, 'is_home'>>(
          'SELECT is_home FROM matches WHERE id = $1 FOR UPDATE',
          [matchId]
        );
        const column = match.rows[0]?.is_home ? 'home_score' : 'away_score';
        await client.query(`UPDATE matches SET ${column} = ${column} + 1 WHERE id = $1`, [matchId]);
      }

      return result.rows[0]!;
    });
  }

  async listEvents(matchId: number): Promise<MatchEventRecord[]> {
    const result = await query<MatchEventRecord>(
      'SELECT * FROM match_events WHERE match_id = $1 ORDER BY minute ASC',
      [matchId]
    );
    return result.rows;
  }

  // --- Player stats (feeds the season bilan view) --------------------------------

  async upsertPlayerStat(matchId: number, data: Record<string, unknown>): Promise<MatchPlayerStatRecord> {
    const result = await query<MatchPlayerStatRecord>(
      `INSERT INTO match_player_stats (match_id, player_id, minutes_played, goals, assists, goals_conceded, yellow_cards, red_cards)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (match_id, player_id) DO UPDATE SET
         minutes_played = EXCLUDED.minutes_played, goals = EXCLUDED.goals, assists = EXCLUDED.assists,
         goals_conceded = EXCLUDED.goals_conceded, yellow_cards = EXCLUDED.yellow_cards, red_cards = EXCLUDED.red_cards
       RETURNING *`,
      [
        matchId, data.player_id, data.minutes_played ?? 0, data.goals ?? 0, data.assists ?? 0,
        data.goals_conceded ?? 0, data.yellow_cards ?? 0, data.red_cards ?? 0,
      ]
    );
    return result.rows[0]!;
  }

  async listPlayerStats(matchId: number): Promise<MatchPlayerStatRecord[]> {
    const result = await query<MatchPlayerStatRecord>('SELECT * FROM match_player_stats WHERE match_id = $1', [matchId]);
    return result.rows;
  }

  // --- Evaluations --------------------------------------------------------------------

  async upsertEvaluation(matchId: number, evaluatedBy: number, data: Record<string, unknown>): Promise<MatchEvaluationRecord> {
    const result = await query<MatchEvaluationRecord>(
      `INSERT INTO match_evaluations (match_id, player_id, note, commentaire, evaluated_by)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (match_id, player_id, evaluated_by) DO UPDATE SET
         note = EXCLUDED.note, commentaire = EXCLUDED.commentaire, evaluated_at = now()
       RETURNING *`,
      [matchId, data.player_id, data.note ?? null, data.commentaire ?? null, evaluatedBy]
    );
    return result.rows[0]!;
  }

  async listEvaluations(matchId: number): Promise<MatchEvaluationRecord[]> {
    const result = await query<MatchEvaluationRecord>('SELECT * FROM match_evaluations WHERE match_id = $1', [matchId]);
    return result.rows;
  }

  // --- Report -------------------------------------------------------------------------------

  async saveReport(matchId: number, pdfUrl: string): Promise<MatchReportRecord> {
    const result = await query<MatchReportRecord>(
      `INSERT INTO match_reports (match_id, pdf_url) VALUES ($1, $2)
       ON CONFLICT (match_id) DO UPDATE SET pdf_url = EXCLUDED.pdf_url, generated_at = now()
       RETURNING *`,
      [matchId, pdfUrl]
    );
    return result.rows[0]!;
  }

  async getReport(matchId: number): Promise<MatchReportRecord | null> {
    const result = await query<MatchReportRecord>('SELECT * FROM match_reports WHERE match_id = $1', [matchId]);
    return result.rows[0] ?? null;
  }

  async getReportData(matchId: number): Promise<{
    match: MatchRecord;
    lineup: Array<{ firstName: string; lastName: string; numeroMaillot: number | null; status: string }>;
    events: Array<{ eventType: string; minute: number; playerName: string | null; comment: string | null }>;
    stats: Array<{
      playerName: string;
      minutesPlayed: number;
      goals: number;
      assists: number;
      goalsConceded: number;
      yellowCards: number;
      redCards: number;
    }>;
    evaluations: Array<{ playerName: string; note: number | null; commentaire: string | null }>;
  }> {
    const matchResult = await query<MatchRecord>('SELECT * FROM matches WHERE id = $1', [matchId]);
    const match = matchResult.rows[0];
    if (!match) throw new Error('Match not found');

    const lineupResult = await query<{ firstName: string; lastName: string; numeroMaillot: number | null; status: string }>(
      `SELECT u.first_name AS "firstName", u.last_name AS "lastName", p.numero_maillot AS "numeroMaillot", ml.status
       FROM match_lineups ml
       INNER JOIN players p ON p.id = ml.player_id
       INNER JOIN users u ON u.id = p.id
       WHERE ml.match_id = $1
       ORDER BY CASE ml.status WHEN 'STARTER' THEN 0 WHEN 'SUBSTITUTE' THEN 1 ELSE 2 END`,
      [matchId]
    );

    const eventsResult = await query<{ eventType: string; minute: number; playerName: string | null; comment: string | null }>(
      `SELECT me.event_type AS "eventType", me.minute, u.first_name || ' ' || u.last_name AS "playerName", me.comment
       FROM match_events me
       LEFT JOIN users u ON u.id = me.player_id
       WHERE me.match_id = $1
       ORDER BY me.minute ASC`,
      [matchId]
    );

    const statsResult = await query<{
      playerName: string;
      minutesPlayed: number;
      goals: number;
      assists: number;
      goalsConceded: number;
      yellowCards: number;
      redCards: number;
    }>(
      `SELECT u.first_name || ' ' || u.last_name AS "playerName",
              mps.minutes_played AS "minutesPlayed", mps.goals, mps.assists,
              mps.goals_conceded AS "goalsConceded", mps.yellow_cards AS "yellowCards", mps.red_cards AS "redCards"
       FROM match_player_stats mps
       INNER JOIN users u ON u.id = mps.player_id
       WHERE mps.match_id = $1
       ORDER BY u.last_name ASC`,
      [matchId]
    );

    const evaluationsResult = await query<{ playerName: string; note: number | null; commentaire: string | null }>(
      `SELECT u.first_name || ' ' || u.last_name AS "playerName", me.note, me.commentaire
       FROM match_evaluations me
       INNER JOIN users u ON u.id = me.player_id
       WHERE me.match_id = $1
       ORDER BY u.last_name ASC`,
      [matchId]
    );

    return {
      match,
      lineup: lineupResult.rows,
      events: eventsResult.rows,
      stats: statsResult.rows,
      evaluations: evaluationsResult.rows,
    };
  }
}

/**
 * The lineup-recommendation-service scores on a 0-100 scale while the
 * `ai_lineup_recommendations` columns are NUMERIC(4,3) CHECK (...) BETWEEN 0 AND 1.
 * Clamp + rescale onto the [0, 1] bucket before persisting.
 */
export function normalizeScore(score100: number): number {
  const clamped = Math.min(100, Math.max(0, score100));
  return Math.round((clamped / 100) * 1000) / 1000;
}
