import { Router } from 'express';
import { MatchesController } from './matches.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireMatchAccess } from '../../middleware/resource-access.middleware.js';
import {
  createMatchSchema,
  updateMatchStatusSchema,
  setLineupSchema,
  generateAiRecommendationsSchema,
  createMatchEventSchema,
  upsertPlayerStatSchema,
  upsertEvaluationSchema,
  saveMatchReportSchema,
  matchIdParamSchema,
  listMatchesQuerySchema,
} from './matches.validation.js';

const router = Router();
const controller = new MatchesController();

router.use(authMiddleware);

router.get('/', validate({ query: listMatchesQuerySchema }), asyncHandler(controller.list));
router.get('/:id', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.getById));

router.post('/', requireRole('COACH', 'ADJOINT'), validate({ body: createMatchSchema }), asyncHandler(controller.create));

router.patch(
  '/:id/status',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: updateMatchStatusSchema }),
  requireMatchAccess(),
  asyncHandler(controller.updateStatus)
);

router.delete('/:id', requireRole('COACH'), validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.remove));

// --- Composition ---

router.get('/:id/lineup', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.getLineup));
router.put(
  '/:id/lineup',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: setLineupSchema }),
  requireMatchAccess(),
  asyncHandler(controller.setLineup)
);

// --- Recommandation IA ---

router.post(
  '/:id/ai-recommendations',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: generateAiRecommendationsSchema }),
  requireMatchAccess(),
  asyncHandler(controller.generateRecommendations)
);
router.get('/:id/ai-recommendations', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.getRecommendations));

// --- Live ---

router.get('/:id/events', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.listEvents));
router.post(
  '/:id/events',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: createMatchEventSchema }),
  requireMatchAccess(),
  asyncHandler(controller.createEvent)
);

// --- Stats / evaluations / report ---

router.get('/:id/stats', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.listPlayerStats));
router.put(
  '/:id/stats',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: upsertPlayerStatSchema }),
  requireMatchAccess(),
  asyncHandler(controller.upsertPlayerStat)
);

router.get('/:id/evaluations', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.listEvaluations));
router.put(
  '/:id/evaluations',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: upsertEvaluationSchema }),
  requireMatchAccess(),
  asyncHandler(controller.upsertEvaluation)
);

router.get('/:id/report', validate({ params: matchIdParamSchema }), requireMatchAccess(), asyncHandler(controller.getReport));
router.post(
  '/:id/report/generate',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema }),
  requireMatchAccess(),
  asyncHandler(controller.generateReport)
);
router.post(
  '/:id/report',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: matchIdParamSchema, body: saveMatchReportSchema }),
  requireMatchAccess(),
  asyncHandler(controller.saveReport)
);

export default router;
