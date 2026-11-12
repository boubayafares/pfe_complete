import { AttendanceRepository } from './attendance.repository.js';
import type{ MarkAttendanceDto } from './attendance.dto.js';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';
import { query } from '../../config/database.js';
import { emitAttendanceUpdate } from '../../socket/socket.js';

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

  private async assertPlayersInTrainingTeam(playerIds: number[], trainingId: number) {
    const uniquePlayerIds = [...new Set(playerIds)];
    const result = await query<{ id: number }>(
      `SELECT p.id FROM players p
       JOIN trainings t ON t.team_id = p.team_id
       WHERE p.id = ANY($1::bigint[]) AND t.id = $2`,
      [uniquePlayerIds, trainingId]
    );
    const foundIds = new Set(result.rows.map((row) => Number(row.id)));
    if (uniquePlayerIds.some((id) => !foundIds.has(Number(id)))) {
      throw new ForbiddenError('Every player must belong to this training team');
    }
  }

  async mark(trainingId: number, dto: MarkAttendanceDto) {
    await this.assertTrainingExists(trainingId);
    await this.assertPlayerInTrainingTeam(dto.playerId, trainingId);
    const record = await this.repo.upsert(trainingId, dto.playerId, dto.status, dto.comment);
    emitAttendanceUpdate(trainingId, { type: 'ATTENDANCE', trainingId, records: [record] });
    return record;
  }

  async bulkMark(trainingId: number, entries: MarkAttendanceDto[]) {
    await this.assertTrainingExists(trainingId);
    await this.assertPlayersInTrainingTeam(entries.map((entry) => entry.playerId), trainingId);
    const records = await this.repo.bulkUpsert(trainingId, entries);
    emitAttendanceUpdate(trainingId, { type: 'ATTENDANCE', trainingId, records });
    return records;
  }

  async listByTraining(trainingId: number) {
    await this.assertTrainingExists(trainingId);
    return this.repo.listByTraining(trainingId);
  }

  async listByPlayer(playerId: number) {
    return this.repo.listByPlayer(playerId);
  }
}
