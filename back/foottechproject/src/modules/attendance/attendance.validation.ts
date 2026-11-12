import{ z } from 'zod';

export const markAttendanceSchema = z.object({
  playerId: z.coerce.number().int().positive(),
  status: z.enum(['PRESENT', 'ABSENT', 'LATE', 'INJURED']),
  comment: z.string().optional(),
});

export const bulkMarkAttendanceSchema = z.object({
  entries: z.array(markAttendanceSchema).min(1).max(200),
}).superRefine((data, ctx) => {
  const playerIds = data.entries.map((entry) => entry.playerId);
  if (new Set(playerIds).size !== playerIds.length) {
    ctx.addIssue({
      code: 'custom',
      message: 'Each player can appear only once',
      path: ['entries'],
    });
  }
});

export const trainingIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
export const playerIdParamSchema = z.object({ playerId: z.coerce.number().int().positive() });
