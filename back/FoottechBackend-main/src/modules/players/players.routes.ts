import { Router } from 'express';
import { PlayersController } from './players.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { requirePlayerAccess } from '../../middleware/resource-access.middleware.js';
import {
  createPlayerSchema,
  updatePlayerSchema,
  upsertGuardianSchema,
  upsertAddressSchema,
  upsertSchoolInfoSchema,
  upsertSeasonProfileSchema,
  createInjurySchema,
  updateInjurySchema,
  playerIdParamSchema,
  playerInjuryParamSchema,
  listPlayersQuerySchema,
} from './players.validation.js';

const router = Router();
const controller = new PlayersController();

router.use(authMiddleware);

router.get('/', validate({ query: listPlayersQuerySchema }), asyncHandler(controller.list));

router.get('/:id', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.getProfile));

router.post(
  '/',
  requireRole('COACH', 'ADJOINT'),
  validate({ body: createPlayerSchema }),
  asyncHandler(controller.create)
);

router.patch(
  '/:id',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: updatePlayerSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.update)
);

// --- Fiche complete : parents / adresse / scolarite / profil saison / blessures ---

router.get('/:id/guardians', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.listGuardians));
router.put(
  '/:id/guardians',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: upsertGuardianSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.upsertGuardian)
);

router.get('/:id/address', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.getAddress));
router.put(
  '/:id/address',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: upsertAddressSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.upsertAddress)
);

router.get('/:id/school-info', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.getSchoolInfo));
router.put(
  '/:id/school-info',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: upsertSchoolInfoSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.upsertSchoolInfo)
);

router.get('/:id/season-profile', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.listSeasonProfiles));
router.put(
  '/:id/season-profile',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: upsertSeasonProfileSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.upsertSeasonProfile)
);

router.get('/:id/injuries', validate({ params: playerIdParamSchema }), requirePlayerAccess(), asyncHandler(controller.listInjuries));
router.post(
  '/:id/injuries',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerIdParamSchema, body: createInjurySchema }),
  requirePlayerAccess(),
  asyncHandler(controller.createInjury)
);
router.patch(
  '/:id/injuries/:injuryId',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerInjuryParamSchema, body: updateInjurySchema }),
  requirePlayerAccess(),
  asyncHandler(controller.updateInjury)
);
router.delete(
  '/:id/injuries/:injuryId',
  requireRole('COACH', 'ADJOINT'),
  validate({ params: playerInjuryParamSchema }),
  requirePlayerAccess(),
  asyncHandler(controller.deleteInjury)
);

export default router;
