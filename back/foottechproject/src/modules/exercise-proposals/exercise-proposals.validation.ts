import { z } from 'zod';

export const createProposalSchema = z.object({
  trainingId: z.coerce.number().int().positive().optional(),
  titre: z.string().min(1).max(150),
  description: z.string().optional(),
  category: z.string().max(80).optional(),
  objectif: z.string().max(200).optional(),
  difficulty: z.enum(['EASY', 'MEDIUM', 'HARD', 'ELITE']).optional(),
  durationMinutes: z.coerce.number().int().min(1).max(180).optional(),
  visibility: z.enum(['PRIVATE', 'TEAM', 'COMMUNITY']).optional(),
  tags: z.array(z.string().min(1).max(40)).max(12).optional(),
  canvasData: z.record(z.string(), z.unknown()).optional(),
  animationData: z.record(z.string(), z.unknown()).optional(),
});

export const reviewProposalSchema = z.object({
  status: z.enum(['VALIDATED', 'REJECTED']),
  reviewComment: z.string().optional(),
});

export const proposalIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const listProposalsQuerySchema = z.object({
  trainingId: z.coerce.number().int().positive().optional(),
  status: z.enum(['PENDING', 'VALIDATED', 'REJECTED']).optional(),
  proposedBy: z.coerce.number().int().positive().optional(),
  visibility: z.enum(['PRIVATE', 'TEAM', 'COMMUNITY']).optional(),
  tag: z.string().max(40).optional(),
});
