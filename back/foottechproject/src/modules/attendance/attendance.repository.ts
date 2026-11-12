import { query, withTransaction } from '../../config/database.js';
import type{ AttendanceRecord, AttendanceRosterEntry } from './attendance.interface.js';
import type { MarkAttendanceDto } from './attendance.dto.js';

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

  async bulkUpsert(trainingId: number, entries: MarkAttendanceDto[]): Promise<AttendanceRecord[]> {
    return withTransaction(async (client) => {
      const records: AttendanceRecord[] = [];
      for (const entry of entries) {
        const result = await client.query<AttendanceRecord>(
          `INSERT INTO attendances (training_id, player_id, status, comment)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (training_id, player_id) DO UPDATE SET
             status = EXCLUDED.status,
             comment = EXCLUDED.comment
           RETURNING *`,
          [trainingId, entry.playerId, entry.status, entry.comment ?? null]
        );
        records.push(result.rows[0]!);
      }
      return records;
    });
  }

  async listByTraining(trainingId: number): Promise<AttendanceRosterEntry[]> {
    const result = await query<AttendanceRosterEntry>(
      `SELECT a.id,
              t.id AS training_id,
              p.id AS player_id,
              COALESCE(a.status::text, 'UNMARKED') AS status,
              a.comment,
              a.created_at,
              u.first_name,
              u.last_name,
              p.numero_maillot
       FROM trainings t
       INNER JOIN players p ON p.team_id = t.team_id
       INNER JOIN users u ON u.id = p.id
       LEFT JOIN attendances a
         ON a.training_id = t.id AND a.player_id = p.id
       WHERE t.id = $1
         AND u.account_status <> 'BLOCKED'
       ORDER BY p.numero_maillot NULLS LAST, u.last_name, u.first_name`,
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
