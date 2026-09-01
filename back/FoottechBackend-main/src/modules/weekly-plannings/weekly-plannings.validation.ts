import { z } from 'zod';

export const createWeeklyPlanningSchema = z.object({
  teamId: z.coerce.number().int().positive(),
  seasonId: z.coerce.number().int().positive().optional(),
  semaineNumero: z.coerce.number().int().positive().optional(),
  dateDebut: z.coerce.date(),
  dateFin: z.coerce.date(),
  nombreSeances: z.coerce.number().int().min(0).optional(),
  intensite: z.string().max(50).optional(),
  volume: z.string().max(50).optional(),
  matchPrevu: z.boolean().optional(),
});

export const updateWeeklyPlanningSchema = createWeeklyPlanningSchema.omit({ teamId: true }).partial();

export const upsertSlotSchema = z.object({
  jour: z.coerce.date(),
  moment: z.enum(['MATIN', 'APRES_MIDI', 'SOIR']),
  trainingId: z.coerce.number().int().positive().optional(),
  description: z.string().max(255).optional(),
});

export const weeklyPlanningIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const listWeeklyPlanningsQuerySchema = z.object({
  teamId: z.coerce.number().int().positive().optional(),
  seasonId: z.coerce.number().int().positive().optional(),
});
