import { Router } from 'express';
import { UsersController } from './users.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { uploadSingle } from '../../middleware/upload.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireSelf } from '../../middleware/self-access.middleware.js';
import { updateUserSchema, userIdParamSchema } from './users.validation.js';

const router = Router();
const controller = new UsersController();

router.use(authMiddleware);

router.get('/:id', validate({ params: userIdParamSchema }), requireSelf(), asyncHandler(controller.getById));
router.patch('/:id', validate({ params: userIdParamSchema, body: updateUserSchema }), requireSelf(), asyncHandler(controller.update));
router.post('/:id/avatar', validate({ params: userIdParamSchema }), requireSelf(), uploadSingle('avatar'), asyncHandler(controller.uploadAvatar));

export default router;
