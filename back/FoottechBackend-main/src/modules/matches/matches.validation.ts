import { z } from 'zod';

export const createMatchSchema = z.object({
  teamId: z.coerce.number().int().positive(),
  seasonId: z.coerce.number().int().positive().optional(),
  adversaire: z.string().min(1).max(150),
  dateHeure: z.coerce.date(),
  lieu: z.string().max(255).optional(),
  isHome: z.boolean().optional(),
  formation: z.string().max(20).optional(),
});

export const updateMatchStatusSchema = z.object({
  matchStatus: z.enum(['SCHEDULED', 'LIVE', 'FINISHED', 'CANCELLED', 'POSTPONED']),
});

const lineupEntrySchema = z.object({
  playerId: z.coerce.number().int().positive(),
  status: z.enum(['STARTER', 'SUBSTITUTE', 'NOT_SELECTED']),
  positionTerrain: z.string().max(10).optional(),
});

export const setLineupSchema = z.object({
  entries: z.array(lineupEntrySchema).min(1),
});

export const generateAiRecommendationsSchema = z.object({
  playerIds: z.array(z.coerce.number().int().positive()).optional(),
});

export const createMatchEventSchema = z.object({
  eventType: z.enum(['GOAL', 'ASSIST', 'YELLOW_CARD', 'RED_CARD', 'SUBSTITUTION_IN', 'SUBSTITUTION_OUT', 'INJURY']),
  minute: z.coerce.number().int().min(0).max(130),
  playerId: z.coerce.number().int().positive().optional(),
  relatedPlayerId: z.coerce.number().int().positive().optional(),
  comment: z.string().max(255).optional(),
});

export const upsertPlayerStatSchema = z.object({
  playerId: z.coerce.number().int().positive(),
  minutesPlayed: z.coerce.number().int().min(0).max(130).optional(),
  goals: z.coerce.number().int().min(0).optional(),
  assists: z.coerce.number().int().min(0).optional(),
  goalsConceded: z.coerce.number().int().min(0).optional(),
  yellowCards: z.coerce.number().int().min(0).max(2).optional(),
  redCards: z.coerce.number().int().min(0).max(1).optional(),
});

export const upsertEvaluationSchema = z.object({
  playerId: z.coerce.number().int().positive(),
  note: z.coerce.number().min(0).max(10).optional(),
  commentaire: z.string().optional(),
});

export const saveMatchReportSchema = z.object({
  pdfUrl: z.string().url().max(500),
});

export const matchIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const listMatchesQuerySchema = z.object({
  teamId: z.coerce.number().int().positive().optional(),
  seasonId: z.coerce.number().int().positive().optional(),
  status: z.enum(['SCHEDULED', 'LIVE', 'FINISHED', 'CANCELLED', 'POSTPONED']).optional(),
});
