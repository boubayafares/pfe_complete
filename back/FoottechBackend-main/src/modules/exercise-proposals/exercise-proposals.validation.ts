import { z } from 'zod';

export const createProposalSchema = z.object({
  trainingId: z.coerce.number().int().positive().optional(),
  titre: z.string().min(1).max(150),
  description: z.string().optional(),
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
});
