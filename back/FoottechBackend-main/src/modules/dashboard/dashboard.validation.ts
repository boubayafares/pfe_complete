import { z } from 'zod';

export const seasonBilanQuerySchema = z.object({
  teamId: z.coerce.number().int().positive(),
  seasonId: z.coerce.number().int().positive().optional(),
});
