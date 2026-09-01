import { Router } from 'express';
import { TeamsController } from './teams.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requireTeamAccess } from '../../middleware/team-access.middleware.js';
import {
  createTeamSchema,
  updateTeamSchema,
  addAdjointSchema,
  teamIdParamSchema,
  teamAdjointParamSchema,
  listTeamsQuerySchema,
} from './teams.validation.js';

const router = Router();
const controller = new TeamsController();

router.use(authMiddleware);

router.get('/', validate({ query: listTeamsQuerySchema }), asyncHandler(controller.list));

router.get('/:id', validate({ params: teamIdParamSchema }), requireTeamAccess, asyncHandler(controller.getById));

router.post('/', requireRole('COACH'), validate({ body: createTeamSchema }), asyncHandler(controller.create));

router.patch(
  '/:id',
  requireRole('COACH'),
  validate({ params: teamIdParamSchema, body: updateTeamSchema }),
  requireTeamAccess,
  asyncHandler(controller.update)
);

router.delete('/:id', requireRole('COACH'), validate({ params: teamIdParamSchema }), requireTeamAccess, asyncHandler(controller.remove));

router.get('/:id/staff', validate({ params: teamIdParamSchema }), requireTeamAccess, asyncHandler(controller.getStaff));

router.post(
  '/:id/staff',
  requireRole('COACH'),
  validate({ params: teamIdParamSchema, body: addAdjointSchema }),
  requireTeamAccess,
  asyncHandler(controller.addAdjoint)
);

router.delete(
  '/:id/staff/:adjointId',
  requireRole('COACH'),
  validate({ params: teamAdjointParamSchema }),
  requireTeamAccess,
  asyncHandler(controller.removeAdjoint)
);

export default router;
