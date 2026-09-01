import { z } from 'zod';

const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/;

export const createTrainingSchema = z
  .object({
    teamId: z.coerce.number().int().positive(),
    date: z.coerce.date(),
    startTime: z.string().regex(timeRegex, 'startTime must be HH:mm'),
    endTime: z.string().regex(timeRegex, 'endTime must be HH:mm'),
    location: z.string().max(255).optional(),
  })
  .refine((data) => data.endTime > data.startTime, { message: 'endTime must be after startTime', path: ['endTime'] });

export const updateTrainingSchema = z.object({
  date: z.coerce.date().optional(),
  startTime: z.string().regex(timeRegex).optional(),
  endTime: z.string().regex(timeRegex).optional(),
  location: z.string().max(255).optional(),
  status: z.enum(['SCHEDULED', 'COMPLETED', 'CANCELLED']).optional(),
});

export const upsertTrainingSheetSchema = z.object({
  objectifs: z.string().optional(),
  effectif: z.string().max(100).optional(),
});

export const createSituationSchema = z.object({
  ordre: z.coerce.number().int().positive().optional(),
  titre: z.string().max(150).optional(),
  description: z.string().optional(),
  dureeTravail: z.string().max(20).optional(),
  dureeRecuperation: z.string().max(20).optional(),
  dureeMinutes: z.coerce.number().int().positive().optional(),
  criteresReussite: z.array(z.string()).optional(),
});

export const updateSituationSchema = createSituationSchema.partial();

export const saveTacticalDrawingSchema = z.object({
  canvasData: z.record(z.string(), z.unknown()),
});

export const trainingIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
export const situationParamSchema = z.object({
  id: z.coerce.number().int().positive(),
  situationId: z.coerce.number().int().positive(),
});
export const listTrainingsQuerySchema = z.object({
  teamId: z.coerce.number().int().positive().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});
