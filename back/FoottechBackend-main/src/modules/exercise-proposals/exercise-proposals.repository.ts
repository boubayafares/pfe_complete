import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type { ExerciseProposalRecord } from './exercise-proposals.interface.js';

export class ExerciseProposalsRepository extends BaseRepository<ExerciseProposalRecord> {
  constructor() {
    super('exercise_proposals');
  }

  async findWithFilters(filters: { trainingId?: number; status?: string; proposedBy?: number }): Promise<ExerciseProposalRecord[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    if (filters.trainingId) {
      params.push(filters.trainingId);
      conditions.push(`training_id = $${params.length}`);
    }
    if (filters.status) {
      params.push(filters.status);
      conditions.push(`status = $${params.length}`);
    }
    if (filters.proposedBy) {
      params.push(filters.proposedBy);
      conditions.push(`proposed_by = $${params.length}`);
    }
    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query<ExerciseProposalRecord>(
      `SELECT * FROM exercise_proposals ${whereClause} ORDER BY created_at DESC`,
      params
    );
    return result.rows;
  }

  async review(id: number, status: 'VALIDATED' | 'REJECTED', reviewedBy: number, comment?: string): Promise<ExerciseProposalRecord | null> {
    const result = await query<ExerciseProposalRecord>(
      `UPDATE exercise_proposals SET status = $1, reviewed_by = $2, reviewed_at = now(), review_comment = $3
       WHERE id = $4 RETURNING *`,
      [status, reviewedBy, comment ?? null, id]
    );
    return result.rows[0] ?? null;
  }
}
