import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type { ExerciseProposalRecord } from './exercise-proposals.interface.js';

export class ExerciseProposalsRepository extends BaseRepository<ExerciseProposalRecord> {
  constructor() {
    super('exercise_proposals');
  }

  async findWithFilters(filters: { teamId: number; trainingId?: number; status?: string; proposedBy?: number; visibility?: string; tag?: string }): Promise<ExerciseProposalRecord[]> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    params.push(filters.teamId);
    conditions.push('team_id = $1');
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
    if (filters.visibility) {
      params.push(filters.visibility);
      conditions.push(`visibility = $${params.length}`);
    }
    if (filters.tag) {
      params.push(filters.tag);
      conditions.push(`$${params.length} = ANY(tags)`);
    }
    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const result = await query<ExerciseProposalRecord>(
      `SELECT * FROM exercise_proposals ${whereClause} ORDER BY created_at DESC`,
      params
    );
    return result.rows;
  }

  async findLibrary(teamId: number): Promise<ExerciseProposalRecord[]> {
    const result = await query<ExerciseProposalRecord>(
      `SELECT * FROM exercise_proposals
       WHERE status = 'VALIDATED'
         AND (team_id = $1 OR visibility = 'COMMUNITY')
       ORDER BY
         CASE visibility WHEN 'COMMUNITY' THEN 0 ELSE 1 END,
         created_at DESC
       LIMIT 100`,
      [teamId]
    );
    return result.rows;
  }

  async belongsToTeam(id: number, teamId: number): Promise<boolean> {
    const result = await query(
      `SELECT 1 FROM exercise_proposals
       WHERE id = $1 AND team_id = $2 LIMIT 1`,
      [id, teamId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  async trainingBelongsToTeam(trainingId: number, teamId: number): Promise<boolean> {
    const result = await query(
      'SELECT 1 FROM trainings WHERE id = $1 AND team_id = $2 LIMIT 1',
      [trainingId, teamId]
    );
    return (result.rowCount ?? 0) > 0;
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
