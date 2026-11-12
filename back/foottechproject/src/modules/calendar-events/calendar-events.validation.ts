import { z } from 'zod';

export const createCalendarEventSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  startTime: z.coerce.date(),
  endTime: z.coerce.date().optional(),
  allDay: z.boolean().optional(),
  location: z.string().max(255).optional(),
  color: z.string().max(20).optional(),
});

export const updateCalendarEventSchema = createCalendarEventSchema.partial();

// idempotent: a full update is allowed to change the title, but PATCH should
// let any subset of fields change too.
export const patchCalendarEventSchema = updateCalendarEventSchema;

export const calendarEventIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const listCalendarEventsQuerySchema = z.object({
  teamId: z.coerce.number().int().positive().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});
