import { Router } from 'express';
import { SeasonsController } from './seasons.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { createSeasonSchema, updateSeasonSchema, seasonIdParamSchema } from './seasons.validation.js';

const router = Router();
const controller = new SeasonsController();

router.use(authMiddleware);

router.get('/', asyncHandler(controller.list));
router.get('/:id', validate({ params: seasonIdParamSchema }), asyncHandler(controller.getById));
router.post('/', requireRole('COACH'), validate({ body: createSeasonSchema }), asyncHandler(controller.create));
router.patch(
  '/:id',
  requireRole('COACH'),
  validate({ params: seasonIdParamSchema, body: updateSeasonSchema }),
  asyncHandler(controller.update)
);
router.delete('/:id', requireRole('COACH'), validate({ params: seasonIdParamSchema }), asyncHandler(controller.remove));

export default router;
