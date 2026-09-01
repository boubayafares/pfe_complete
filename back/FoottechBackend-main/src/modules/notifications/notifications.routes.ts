import { Router } from 'express';
import { NotificationsController } from './notifications.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import {
  createNotificationSchema,
  broadcastNotificationSchema,
  registerPushTokenSchema,
  notificationIdParamSchema,
} from './notifications.validation.js';

const router = Router();
const controller = new NotificationsController();

router.use(authMiddleware);

router.get('/', asyncHandler(controller.listMine));

router.post(
  '/',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: createNotificationSchema }),
  asyncHandler(controller.create)
);

router.post(
  '/broadcast',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: broadcastNotificationSchema }),
  asyncHandler(controller.broadcast)
);

router.patch('/:id/read', validate({ params: notificationIdParamSchema }), asyncHandler(controller.markAsRead));
router.patch('/read-all', asyncHandler(controller.markAllAsRead));

router.post('/push-token', validate({ body: registerPushTokenSchema }), asyncHandler(controller.registerPushToken));

export default router;
