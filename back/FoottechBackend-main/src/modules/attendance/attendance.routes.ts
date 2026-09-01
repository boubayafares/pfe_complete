import { Router } from 'express';
import { AttendanceController } from './attendance.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireTrainingAccess, requirePlayerAccess } from '../../middleware/resource-access.middleware.js';
import { markAttendanceSchema, bulkMarkAttendanceSchema, trainingIdParamSchema, playerIdParamSchema } from './attendance.validation.js';

const router = Router();
const controller = new AttendanceController();

router.use(authMiddleware);

router.get('/players/:playerId/history', validate({ params: playerIdParamSchema }), requirePlayerAccess('playerId'), asyncHandler(controller.listByPlayer));

router.get('/trainings/:id', validate({ params: trainingIdParamSchema }), requireTrainingAccess(), asyncHandler(controller.listByTraining));

router.post(
  '/trainings/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema, body: markAttendanceSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.mark)
);

router.post(
  '/trainings/:id/bulk',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: trainingIdParamSchema, body: bulkMarkAttendanceSchema }),
  requireTrainingAccess(),
  asyncHandler(controller.bulkMark)
);

export default router;
