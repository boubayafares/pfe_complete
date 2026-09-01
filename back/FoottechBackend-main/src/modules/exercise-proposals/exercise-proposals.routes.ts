import { Router } from 'express';
import { ExerciseProposalsController } from './exercise-proposals.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import {
  createProposalSchema,
  reviewProposalSchema,
  proposalIdParamSchema,
  listProposalsQuerySchema,
} from './exercise-proposals.validation.js';

const router = Router();
const controller = new ExerciseProposalsController();

router.use(authMiddleware);

router.get('/', validate({ query: listProposalsQuerySchema }), asyncHandler(controller.list));
router.get('/:id', validate({ params: proposalIdParamSchema }), asyncHandler(controller.getById));

router.post(
  '/',
  requireRole('ADJOINT'),
  validate({ body: createProposalSchema }),
  asyncHandler(controller.create)
);

router.patch(
  '/:id/review',
  requireRole('COACH'),
  validate({ params: proposalIdParamSchema, body: reviewProposalSchema }),
  asyncHandler(controller.review)
);

export default router;
