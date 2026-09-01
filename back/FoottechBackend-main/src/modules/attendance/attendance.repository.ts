import { query } from '../../config/database.js';
import type{ AttendanceRecord, AttendanceWithPlayer } from './attendance.interface.js';

export class AttendanceRepository {
  async upsert(trainingId: number, playerId: number, status: string, comment?: string): Promise<AttendanceRecord> {
    const result = await query<AttendanceRecord>(
      `INSERT INTO attendances (training_id, player_id, status, comment)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (training_id, player_id) DO UPDATE SET status = EXCLUDED.status, comment = EXCLUDED.comment
       RETURNING *`,
      [trainingId, playerId, status, comment ?? null]
    );
    return result.rows[0]!;
  }

  async listByTraining(trainingId: number): Promise<AttendanceWithPlayer[]> {
    const result = await query<AttendanceWithPlayer>(
      `SELECT a.*, u.first_name, u.last_name, p.numero_maillot
       FROM attendances a
       INNER JOIN players p ON p.id = a.player_id
       INNER JOIN users u ON u.id = p.id
       WHERE a.training_id = $1 ORDER BY p.numero_maillot NULLS LAST`,
      [trainingId]
    );
    return result.rows;
  }

  async listByPlayer(playerId: number) {
    const result = await query(
      `SELECT a.*, t.date FROM attendances a INNER JOIN trainings t ON t.id = a.training_id
       WHERE a.player_id = $1 ORDER BY t.date DESC`,
      [playerId]
    );
    return result.rows;
  }
}
