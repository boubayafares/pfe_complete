import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{
  TrainingRecord,
  TrainingSheetRecord,
  TrainingSituationRecord,
  TacticalDrawingRecord,
} from './trainings.interface.js';

export class TrainingsRepository extends BaseRepository<TrainingRecord> {
  constructor() {
    super('trainings');
  }

  async findWithFilters(teamId?: number, from?: Date, to?: Date): Promise<TrainingRecord[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    if (teamId) {
      params.push(teamId);
      conditions.push(`team_id = $${params.length}`);
    }
    if (from) {
      params.push(from);
      conditions.push(`date >= $${params.length}`);
    }
    if (to) {
      params.push(to);
      conditions.push(`date <= $${params.length}`);
    }
    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query<TrainingRecord>(
      `SELECT * FROM trainings ${whereClause} ORDER BY date ASC, start_time ASC`,
      params
    );
    return result.rows;
  }

  // --- Training sheet (1:1) ---------------------------------------------------

  async upsertSheet(trainingId: number, data: Record<string, unknown>): Promise<TrainingSheetRecord> {
    const result = await query<TrainingSheetRecord>(
      `INSERT INTO training_sheets (training_id, objectifs, effectif, created_by)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (training_id) DO UPDATE SET objectifs = EXCLUDED.objectifs, effectif = EXCLUDED.effectif
       RETURNING *`,
      [trainingId, data.objectifs ?? null, data.effectif ?? null, data.created_by ?? null]
    );
    return result.rows[0]!;
  }

  async findSheetByTrainingId(trainingId: number): Promise<TrainingSheetRecord | null> {
    const result = await query<TrainingSheetRecord>('SELECT * FROM training_sheets WHERE training_id = $1', [trainingId]);
    return result.rows[0] ?? null;
  }

  // --- Situations --------------------------------------------------------------

  async createSituation(sheetId: number, data: Record<string, unknown>): Promise<TrainingSituationRecord> {
    const result = await query<TrainingSituationRecord>(
      `INSERT INTO training_situations
         (training_sheet_id, ordre, titre, description, duree_travail, duree_recuperation, duree_minutes, criteres_reussite)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [
        sheetId, data.ordre ?? 1, data.titre ?? null, data.description ?? null,
        data.duree_travail ?? null, data.duree_recuperation ?? null, data.duree_minutes ?? null,
        data.criteres_reussite ?? null,
      ]
    );
    return result.rows[0]!;
  }

  async updateSituation(situationId: number, data: Record<string, unknown>): Promise<TrainingSituationRecord | null> {
    const columns = Object.keys(data);
    if (columns.length === 0) return null;
    const setClause = columns.map((col, i) => `${col} = $${i + 1}`).join(', ');
    const result = await query<TrainingSituationRecord>(
      `UPDATE training_situations SET ${setClause} WHERE id = $${columns.length + 1} RETURNING *`,
      [...Object.values(data), situationId]
    );
    return result.rows[0] ?? null;
  }

  async listSituations(sheetId: number): Promise<TrainingSituationRecord[]> {
    const result = await query<TrainingSituationRecord>(
      'SELECT * FROM training_situations WHERE training_sheet_id = $1 ORDER BY ordre ASC',
      [sheetId]
    );
    return result.rows;
  }

  async findSituationById(situationId: number): Promise<TrainingSituationRecord | null> {
    const result = await query<TrainingSituationRecord>('SELECT * FROM training_situations WHERE id = $1', [situationId]);
    return result.rows[0] ?? null;
  }

  async deleteSituation(situationId: number): Promise<boolean> {
    const result = await query('DELETE FROM training_situations WHERE id = $1', [situationId]);
    return (result.rowCount ?? 0) > 0;
  }

  // --- Tactical drawing (editeur type TacticalPad) ------------------------------

  async saveDrawingForSituation(situationId: number, canvasData: Record<string, unknown>, createdBy?: number): Promise<TacticalDrawingRecord> {
    const result = await query<TacticalDrawingRecord>(
      `INSERT INTO tactical_drawings (training_situation_id, canvas_data, created_by) VALUES ($1, $2, $3) RETURNING *`,
      [situationId, JSON.stringify(canvasData), createdBy ?? null]
    );
    return result.rows[0]!;
  }

  async findLatestDrawingForSituation(situationId: number): Promise<TacticalDrawingRecord | null> {
    const result = await query<TacticalDrawingRecord>(
      `SELECT * FROM tactical_drawings WHERE training_situation_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [situationId]
    );
    return result.rows[0] ?? null;
  }
}
