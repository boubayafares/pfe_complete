import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { requirePlayerAccess } from '../../middleware/resource-access.middleware.js';
import { validate } from '../../middleware/validation.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { AiInsightsController } from './ai-insights.controller.js';
import { analyzeToneSchema, playerTrendParamsSchema, teamClustersQuerySchema } from './ai-insights.validation.js';

const router = Router();
const controller = new AiInsightsController();

router.use(authMiddleware);

router.get(
  '/players/:id/trend',
  validate({ params: playerTrendParamsSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.playerTrend)
);
router.get(
  '/clusters',
  requireRole('COACH', 'ADJOINT'),
  validate({ query: teamClustersQuerySchema }),
  asyncHandler(controller.teamClusters)
);
router.post(
  '/tone',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: analyzeToneSchema }),
  asyncHandler(controller.analyzeTone)
);
router.get(
  '/expert-project-model',
  requireRole('COACH', 'ADJOINT'),
  asyncHandler(controller.expertProjectModel)
);

export default router;
