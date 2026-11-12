import { z } from 'zod';

export const seasonBilanQuerySchema = z.object({
  seasonId: z.coerce.number().int().positive().optional(),
});
