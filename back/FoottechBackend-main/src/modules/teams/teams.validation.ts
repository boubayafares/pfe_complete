import { z } from 'zod';

export const createTeamSchema = z.object({
  name: z.string().min(1).max(150),
  category: z.string().max(80).optional(),
  logo: z.string().url().max(500).optional(),
  description: z.string().optional(),
});

export const updateTeamSchema = createTeamSchema.partial();

export const addAdjointSchema = z.object({
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  phone: z.string().min(8).max(30),
  email: z.string().email(),
});

export const teamIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const teamAdjointParamSchema = z.object({
  id: z.coerce.number().int().positive(),
  adjointId: z.coerce.number().int().positive(),
});

export const listTeamsQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
  category: z.string().optional(),
  search: z.string().optional(),
});
