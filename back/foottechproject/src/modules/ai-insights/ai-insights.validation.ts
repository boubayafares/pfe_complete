import { z } from 'zod';

export const playerTrendParamsSchema = z.object({ id: z.coerce.number().int().positive() });
export const teamClustersQuerySchema = z.object({
  nClusters: z.coerce.number().int().min(2).max(10).default(3),
});
export const analyzeToneSchema = z.object({ comment: z.string().max(2000) });
