import { Router } from 'express';
import { WeeklyPlanningsController } from './weekly-plannings.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireWeeklyPlanningAccess } from '../../middleware/resource-access.middleware.js';
import {
  createWeeklyPlanningSchema,
  updateWeeklyPlanningSchema,
  upsertSlotSchema,
  weeklyPlanningIdParamSchema,
  listWeeklyPlanningsQuerySchema,
} from './weekly-plannings.validation.js';

const router = Router();
const controller = new WeeklyPlanningsController();

router.use(authMiddleware);

router.get('/', validate({ query: listWeeklyPlanningsQuerySchema }), asyncHandler(controller.list));
router.get('/:id', validate({ params: weeklyPlanningIdParamSchema }), requireWeeklyPlanningAccess(), asyncHandler(controller.getById));

router.post(
  '/',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: createWeeklyPlanningSchema }),
  asyncHandler(controller.create)
);

router.patch(
  '/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: weeklyPlanningIdParamSchema, body: updateWeeklyPlanningSchema }),
  requireWeeklyPlanningAccess(),
  asyncHandler(controller.update)
);

router.delete(
  '/:id',
  requireRole('COACH'),
  validate({ params: weeklyPlanningIdParamSchema }),
  requireWeeklyPlanningAccess(),
  asyncHandler(controller.remove)
);

router.get('/:id/slots', validate({ params: weeklyPlanningIdParamSchema }), requireWeeklyPlanningAccess(), asyncHandler(controller.listSlots));

router.put(
  '/:id/slots',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: weeklyPlanningIdParamSchema, body: upsertSlotSchema }),
  requireWeeklyPlanningAccess(),
  asyncHandler(controller.upsertSlot)
);

export default router;
