import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ WeeklyPlanningRecord, WeeklyPlanningSlotRecord } from './weekly-plannings.interface.js';

export class WeeklyPlanningsRepository extends BaseRepository<WeeklyPlanningRecord> {
  constructor() {
    super('weekly_plannings');
  }

  async findWithFilters(teamId?: number, seasonId?: number): Promise<WeeklyPlanningRecord[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    if (teamId) {
      params.push(teamId);
      conditions.push(`team_id = $${params.length}`);
    }
    if (seasonId) {
      params.push(seasonId);
      conditions.push(`season_id = $${params.length}`);
    }
    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query<WeeklyPlanningRecord>(
      `SELECT * FROM weekly_plannings ${whereClause} ORDER BY date_debut DESC`,
      params
    );
    return result.rows;
  }

  async upsertSlot(weeklyPlanningId: number, data: Record<string, unknown>): Promise<WeeklyPlanningSlotRecord> {
    const result = await query<WeeklyPlanningSlotRecord>(
      `INSERT INTO weekly_planning_slots (weekly_planning_id, jour, moment, training_id, description)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (weekly_planning_id, jour, moment) DO UPDATE SET
         training_id = EXCLUDED.training_id, description = EXCLUDED.description
       RETURNING *`,
      [weeklyPlanningId, data.jour, data.moment, data.training_id ?? null, data.description ?? null]
    );
    return result.rows[0]!;
  }

  async listSlots(weeklyPlanningId: number): Promise<WeeklyPlanningSlotRecord[]> {
    const result = await query<WeeklyPlanningSlotRecord>(
      `SELECT * FROM weekly_planning_slots WHERE weekly_planning_id = $1 ORDER BY jour, moment`,
      [weeklyPlanningId]
    );
    return result.rows;
  }
}
