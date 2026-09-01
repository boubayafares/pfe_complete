import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ CalendarEventRecord } from './calendar-events.interface.js';

export class CalendarEventsRepository extends BaseRepository<CalendarEventRecord> {
  constructor() {
    super('calendar_events');
  }

  async listForTeam(teamId: number, from?: Date, to?: Date): Promise<CalendarEventRecord[]> {
    const conditions: string[] = ['team_id = $1'];
    const params: unknown[] = [teamId];
    if (from) {
      params.push(from);
      conditions.push(`start_time >= $${params.length}`);
    }
    if (to) {
      params.push(to);
      conditions.push(`start_time <= $${params.length}`);
    }
    const result = await query<CalendarEventRecord>(
      `SELECT * FROM calendar_events WHERE ${conditions.join(' AND ')} ORDER BY start_time ASC, id ASC`,
      params
    );
    return result.rows;
  }
}
