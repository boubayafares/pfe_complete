import { z } from 'zod';

const seasonFields = z.object({
  name: z.string().min(4).max(20),
  startDate: z.coerce.date(),
  endDate: z.coerce.date(),
  isCurrent: z.boolean().optional(),
});

export const createSeasonSchema = seasonFields.refine(
  (data) => data.endDate > data.startDate,
  { message: 'endDate must be after startDate', path: ['endDate'] }
);

export const updateSeasonSchema = seasonFields.partial().refine(
  (data) => !data.startDate || !data.endDate || data.endDate > data.startDate,
  { message: 'endDate must be after startDate', path: ['endDate'] }
);

export const seasonIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
