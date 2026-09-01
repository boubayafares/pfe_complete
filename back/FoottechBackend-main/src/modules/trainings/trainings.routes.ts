import { Router } from 'express';
import { TrainingsController } from './trainings.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireTrainingAccess } from '../../middleware/resource-access.middleware.js';
import {
  createTrainingSchema,
  updateTrainingSchema,
  upsertTrainingSheetSchema,
  createSituationSchema,
  updateSituationSchema,
  saveTacticalDrawingSchema,
  trainingIdParamSchema,
  situationParamSchema,
  listTrainingsQuerySchema,
} from './trainings.validation.js';

const router = Router();
const controller = new TrainingsController();

router.use(authMiddleware);

router.get('/', validate({ query: listTrainingsQuerySchema }), asyncHandler(controller.list));
router.get('/:id', validate({ params: trainingIdParamSchema }), requireTrainingAccess(), asyncHandler(controller.getById));

router.post(
  '/',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: createTrainingSchema }),
  asyncHandler(controller.create)
);

router.patch(
  '/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema, body: updateTrainingSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.update)
);

router.delete(
  '/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.remove)
);

// --- Fiche technique (objectifs / effectif) ---

router.get('/:id/sheet', validate({ params: trainingIdParamSchema }), requireTrainingAccess(), asyncHandler(controller.getSheet));
router.put(
  '/:id/sheet',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema, body: upsertTrainingSheetSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.upsertSheet)
);

// --- Situations / exercices ---

router.get('/:id/situations', validate({ params: trainingIdParamSchema }), requireTrainingAccess(), asyncHandler(controller.listSituations));
router.post(
  '/:id/situations',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema, body: createSituationSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.createSituation)
);
router.patch(
  '/:id/situations/:situationId',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: situationParamSchema, body: updateSituationSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.updateSituation)
);
router.delete(
  '/:id/situations/:situationId',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: situationParamSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.deleteSituation)
);

// --- Schema tactique (editeur type TacticalPad) sur une situation ---

router.get(
  '/:id/situations/:situationId/drawing',
  validate({ params: situationParamSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.getDrawing)
);
router.post(
  '/:id/situations/:situationId/drawing',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: situationParamSchema, body: saveTacticalDrawingSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.saveDrawing)
);

export default router;
