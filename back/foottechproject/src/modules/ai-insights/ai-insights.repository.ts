import { query } from '../../config/database.js';

export interface TrendPoint {
  date: Date;
  value: number;
}

export interface ClusterPlayerFeature {
  playerId: number;
  goalsPerMatch: number;
  assistsPerMatch: number;
  minutesPerMatch: number;
  heightCm: number;
  weightKg: number;
}

export interface ProjectAiSignals {
  players: number;
  staff: number;
  trainings: number;
  matches: number;
  exercises: number;
  drawings: number;
  attendanceRows: number;
  evaluations: number;
  notifications: number;
}

export class AiInsightsRepository {
  async getPlayerTrendPoints(playerId: number): Promise<TrendPoint[]> {
    const result = await query<TrendPoint>(
      `SELECT evaluated_at AS date, note::float AS value
       FROM (
         SELECT evaluated_at, note
         FROM match_evaluations
         WHERE player_id = $1 AND note IS NOT NULL
         ORDER BY evaluated_at DESC
         LIMIT 24
       ) recent
       ORDER BY evaluated_at ASC`,
      [playerId]
    );
    return result.rows;
  }

  async getTeamClusterFeatures(teamId: number): Promise<ClusterPlayerFeature[]> {
    const result = await query<ClusterPlayerFeature>(
      `WITH roster AS (
         SELECT p.*,
                AVG(p.taille_cm) OVER () AS team_avg_height,
                AVG(p.poids_kg) OVER () AS team_avg_weight
         FROM players p
         WHERE p.team_id = $1
       )
       SELECT r.id AS "playerId",
              COALESCE(SUM(mps.goals)::float / NULLIF(COUNT(mps.match_id), 0), 0) AS "goalsPerMatch",
              COALESCE(SUM(mps.assists)::float / NULLIF(COUNT(mps.match_id), 0), 0) AS "assistsPerMatch",
              COALESCE(AVG(mps.minutes_played)::float, 0) AS "minutesPerMatch",
              COALESCE(r.taille_cm, r.team_avg_height, 175)::float AS "heightCm",
              COALESCE(r.poids_kg, r.team_avg_weight, 70)::float AS "weightKg"
       FROM roster r
       LEFT JOIN match_player_stats mps ON mps.player_id = r.id
       GROUP BY r.id, r.taille_cm, r.poids_kg, r.team_avg_height, r.team_avg_weight
       ORDER BY r.id`,
      [teamId]
    );
    return result.rows;
  }

  async getProjectSignals(teamId: number): Promise<ProjectAiSignals> {
    const result = await query<ProjectAiSignals>(
      `SELECT
         (SELECT COUNT(*)::int FROM players WHERE team_id = $1) AS players,
         (SELECT COUNT(*)::int FROM team_staff WHERE team_id = $1) AS staff,
         (SELECT COUNT(*)::int FROM trainings WHERE team_id = $1) AS trainings,
         (SELECT COUNT(*)::int FROM matches WHERE team_id = $1) AS matches,
         (SELECT COUNT(*)::int FROM exercise_proposals WHERE team_id = $1 OR visibility = 'COMMUNITY') AS exercises,
         (SELECT COUNT(*)::int FROM tactical_drawings td
          LEFT JOIN training_situations ts ON ts.id = td.training_situation_id
          LEFT JOIN training_sheets sh ON sh.id = ts.training_sheet_id
          LEFT JOIN trainings tr ON tr.id = sh.training_id
          LEFT JOIN matches m ON m.id = td.match_id
          WHERE tr.team_id = $1 OR m.team_id = $1) AS drawings,
         (SELECT COUNT(*)::int FROM attendances a
          INNER JOIN trainings tr ON tr.id = a.training_id
          WHERE tr.team_id = $1) AS "attendanceRows",
         (SELECT COUNT(*)::int FROM match_evaluations me
          INNER JOIN matches m ON m.id = me.match_id
          WHERE m.team_id = $1) AS evaluations,
         (SELECT COUNT(*)::int FROM notifications n
          WHERE n.user_id IN (
            SELECT id FROM players WHERE team_id = $1
            UNION
            SELECT adjoint_id AS id FROM team_staff WHERE team_id = $1
          )) AS notifications`,
      [teamId]
    );
    return result.rows[0] ?? {
      players: 0,
      staff: 0,
      trainings: 0,
      matches: 0,
      exercises: 0,
      drawings: 0,
      attendanceRows: 0,
      evaluations: 0,
      notifications: 0,
    };
  }
}
