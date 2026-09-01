import{ z } from 'zod';

export const markAttendanceSchema = z.object({
  playerId: z.coerce.number().int().positive(),
  status: z.enum(['PRESENT', 'ABSENT', 'LATE', 'INJURED']),
  comment: z.string().optional(),
});

export const bulkMarkAttendanceSchema = z.object({
  entries: z.array(markAttendanceSchema).min(1),
});

export const trainingIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
export const playerIdParamSchema = z.object({ playerId: z.coerce.number().int().positive() });
