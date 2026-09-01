import { z } from 'zod';

export const createSeasonSchema = z.object({
  name: z.string().min(4).max(20),
  startDate: z.coerce.date(),
  endDate: z.coerce.date(),
  isCurrent: z.boolean().optional(),
});

export const updateSeasonSchema = createSeasonSchema.partial();

export const seasonIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
