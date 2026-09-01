import { Router } from 'express';
import { CalendarEventsController } from './calendar-events.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireCalendarEventAccess } from '../../middleware/resource-access.middleware.js';
import {
  createCalendarEventSchema,
  patchCalendarEventSchema,
  calendarEventIdParamSchema,
  listCalendarEventsQuerySchema,
} from './calendar-events.validation.js';

const router = Router();
const controller = new CalendarEventsController();

router.use(authMiddleware);

// READ — shared by every member of the team (COACH, ADJOINT, JOUEUR).
// JOUEUR only receives a title-only projection (see service).
router.get('/', validate({ query: listCalendarEventsQuerySchema }), asyncHandler(controller.list));
router.get('/:id', validate({ params: calendarEventIdParamSchema }), requireCalendarEventAccess(), asyncHandler(controller.getById));

// WRITE:
// - COACH : full CRUD (create / read / update / delete)
// - ADJOINT : create + update (not delete)
// - JOUEUR : read-only (title only)
router.post('/', requireRole('COACH', 'ADJOINT'), validate({ body: createCalendarEventSchema }), asyncHandler(controller.create));
router.patch(
  '/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: calendarEventIdParamSchema, body: patchCalendarEventSchema }),
  requireCalendarEventAccess(),
  asyncHandler(controller.update)
);
router.delete(
  '/:id',
  requireRole('COACH'),
  validate({ params: calendarEventIdParamSchema }),
  requireCalendarEventAccess(),
  asyncHandler(controller.remove)
);

export default router;
