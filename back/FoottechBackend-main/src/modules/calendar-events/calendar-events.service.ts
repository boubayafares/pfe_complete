import { CalendarEventsRepository } from './calendar-events.repository.js';
import type{ CreateCalendarEventDto, UpdateCalendarEventDto } from './calendar-events.dto.js';
import type{ CalendarEventRecord, CalendarEventLite } from './calendar-events.interface.js';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';

function toLite(ev: CalendarEventRecord): CalendarEventLite {
  return {
    id: ev.id,
    title: ev.title,
    start_time: ev.start_time,
    end_time: ev.end_time,
    all_day: ev.all_day,
    color: ev.color,
  };
}

export class CalendarEventsService {
  private readonly repo = new CalendarEventsRepository();

  async list(teamId: number, role: string, from?: Date, to?: Date): Promise<CalendarEventRecord[] | CalendarEventLite[]> {
    const events = await this.repo.listForTeam(teamId, from, to);
    return role === 'JOUEUR' ? events.map(toLite) : events;
  }

  async getById(id: number, role: string): Promise<CalendarEventRecord | CalendarEventLite> {
    const ev = await this.repo.findById(id);
    if (!ev) throw new NotFoundError('Calendar event');
    return role === 'JOUEUR' ? toLite(ev) : ev;
  }

  async create(dto: CreateCalendarEventDto, teamId: number, createdBy: number): Promise<CalendarEventRecord> {
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    return this.repo.create({
      team_id: teamId,
      title: dto.title,
      description: dto.description ?? null,
      start_time: dto.startTime,
      end_time: dto.endTime ?? null,
      all_day: dto.allDay ?? false,
      location: dto.location ?? null,
      color: dto.color ?? null,
      created_by: createdBy,
    });
  }

  async update(id: number, dto: UpdateCalendarEventDto): Promise<CalendarEventRecord> {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Calendar event');
    const payload: Record<string, unknown> = {};
    if (dto.title !== undefined) payload.title = dto.title;
    if (dto.description !== undefined) payload.description = dto.description;
    if (dto.startTime !== undefined) payload.start_time = dto.startTime;
    if (dto.endTime !== undefined) payload.end_time = dto.endTime;
    if (dto.allDay !== undefined) payload.all_day = dto.allDay;
    if (dto.location !== undefined) payload.location = dto.location;
    if (dto.color !== undefined) payload.color = dto.color;
    payload.updated_at = new Date();
    const updated = await this.repo.update(id, payload);
    if (!updated) throw new NotFoundError('Calendar event');
    return updated;
  }

  async remove(id: number): Promise<void> {
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Calendar event');
  }
}
