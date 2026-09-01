import { AttendanceRepository } from './attendance.repository.js';
import type{ MarkAttendanceDto } from './attendance.dto.js';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';
import { query } from '../../config/database.js';

export class AttendanceService {
  private readonly repo = new AttendanceRepository();

  private async assertTrainingExists(trainingId: number) {
    const result = await query('SELECT 1 FROM trainings WHERE id = $1', [trainingId]);
    if ((result.rowCount ?? 0) === 0) throw new NotFoundError('Training');
  }

  private async assertPlayerInTrainingTeam(playerId: number, trainingId: number) {
    const result = await query<{ team_id: number | null }>(
      `SELECT p.team_id FROM players p
       JOIN trainings t ON t.team_id = p.team_id
       WHERE p.id = $1 AND t.id = $2 LIMIT 1`,
      [playerId, trainingId]
    );
    if ((result.rowCount ?? 0) === 0) {
      throw new ForbiddenError('Player is not part of this training team');
    }
  }

  async mark(trainingId: number, dto: MarkAttendanceDto) {
    await this.assertTrainingExists(trainingId);
    await this.assertPlayerInTrainingTeam(dto.playerId, trainingId);
    return this.repo.upsert(trainingId, dto.playerId, dto.status, dto.comment);
  }

  async bulkMark(trainingId: number, entries: MarkAttendanceDto[]) {
    await this.assertTrainingExists(trainingId);
    const results = [];
    for (const entry of entries) {
      await this.assertPlayerInTrainingTeam(entry.playerId, trainingId);
      results.push(await this.repo.upsert(trainingId, entry.playerId, entry.status, entry.comment));
    }
    return results;
  }

  async listByTraining(trainingId: number) {
    await this.assertTrainingExists(trainingId);
    return this.repo.listByTraining(trainingId);
  }

  async listByPlayer(playerId: number) {
    return this.repo.listByPlayer(playerId);
  }
}
