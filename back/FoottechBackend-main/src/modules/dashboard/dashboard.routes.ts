import { Router } from 'express';
import { DashboardController } from './dashboard.controller.js';
import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/utils/asyncHandler.js';
import { seasonBilanQuerySchema } from './dashboard.validation.js';

const router = Router();
const controller = new DashboardController();

router.use(authMiddleware);

router.get('/me', asyncHandler(controller.getMyDashboard));
router.get('/season-bilan', validate({ query: seasonBilanQuerySchema }), asyncHandler(controller.getSeasonBilan));

export default router;
