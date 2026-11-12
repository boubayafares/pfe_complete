import { Router } from 'express';

import { AuthController } from './auth.controller.js';

import { validate } from '../../middleware/validation.middleware.js';
import { authMiddleware } from '../../middleware/auth.middleware.js';
import { requireRole } from '../../middleware/role.middleware.js';

import { asyncHandler } from '../../shared/utils/asyncHandler.js';

import {
  authRateLimit,
  otpRateLimit,
} from '../../middleware/auth-rate-limit.middleware.js';

import {
  registerCoachSchema,
  loginSchema,
  requestPlayerOtpSchema,
  verifyPlayerOtpSchema,
  requestCoachOtpSchema,
  verifyCoachOtpSchema,
  refreshSchema,
  setAdjointPasswordSchema,
  activateAdjointByPhoneSchema,
  requestAdjointOtpSchema,
  selectTeamSchema,
} from './auth.validation.js';

const router = Router();

const controller = new AuthController();

/**
 * ============================================================
 * PUBLIC AUTH
 * ============================================================
 */

/**
 * Register Coach
 *
 * POST /auth/register-coach
 */
router.post(
  '/register-coach',
  authRateLimit,
  validate({ body: registerCoachSchema }),
  asyncHandler(controller.registerCoach)
);

/**
 * Login Coach / Adjoint
 *
 * POST /auth/login
 */
router.post(
  '/login',
  authRateLimit,
  validate({ body: loginSchema }),
  asyncHandler(controller.login)
);

/**
 * Refresh access token
 *
 * POST /auth/refresh
 */
router.post(
  '/refresh',
  validate({ body: refreshSchema }),
  asyncHandler(controller.refresh)
);

/**
 * ============================================================
 * ADJOINT
 * ============================================================
 */

/**
 * Set Adjoint password
 *
 * IMPORTANT:
 * Only an authenticated COACH can perform this action.
 *
 * POST /auth/set-adjoint-password
 */
router.post(
  '/set-adjoint-password',
  authMiddleware,
  requireRole('COACH'),
  validate({ body: setAdjointPasswordSchema }),
  asyncHandler(controller.setAdjointPassword)
);

/**
 * Request an activation OTP for an Adjoint by phone.
 *
 * POST /auth/adjoint/request-otp
 */
router.post(
  '/adjoint/request-otp',
  otpRateLimit,
  validate({ body: requestAdjointOtpSchema }),
  asyncHandler(controller.requestAdjointOtp)
);

/**
 * Activate Adjoint account from the device (phone + code + password).
 *
 * IMPORTANT: Public. Lets the freshly-added Adjoint set their own password
 * and activate without the Coach being signed in.
 *
 * POST /auth/adjoint/activate
 */
router.post(
  '/adjoint/activate',
  otpRateLimit,
  validate({ body: activateAdjointByPhoneSchema }),
  asyncHandler(controller.activateAdjointByPhone)
);

/**
 * ============================================================
 * PLAYER OTP
 * ============================================================
 */

/**
 * Request Player OTP
 *
 * POST /auth/player/request-otp
 */
router.post(
  '/player/request-otp',
  otpRateLimit,
  validate({ body: requestPlayerOtpSchema }),
  asyncHandler(controller.requestPlayerOtp)
);

/**
 * Verify Player OTP
 *
 * POST /auth/player/verify-otp
 */
router.post(
  '/player/verify-otp',
  otpRateLimit,
  validate({ body: verifyPlayerOtpSchema }),
  asyncHandler(controller.verifyPlayerOtp)
);

/**
 * ============================================================
 * COACH / ADJOINT OTP
 * ============================================================
 */

/**
 * Request OTP for an INACTIVE Coach / Adjoint (email + password flow).
 *
 * POST /auth/coach/request-otp
 */
router.post(
  '/coach/request-otp',
  otpRateLimit,
  validate({ body: requestCoachOtpSchema }),
  asyncHandler(controller.requestCoachOtp)
);

/**
 * Verify OTP to activate an INACTIVE Coach / Adjoint and log them in.
 *
 * POST /auth/coach/verify-otp
 */
router.post(
  '/coach/verify-otp',
  otpRateLimit,
  validate({ body: verifyCoachOtpSchema }),
  asyncHandler(controller.verifyCoachOtp)
);

/**
 * ============================================================
 * AUTHENTICATED USER
 * ============================================================
 */

/**
 * Logout
 *
 * POST /auth/logout
 */
router.post(
  '/select-team',
  authMiddleware,
  validate({ body: selectTeamSchema }),
  asyncHandler(controller.selectTeam)
);

router.post(
  '/logout',
  authMiddleware,
  asyncHandler(controller.logout)
);

/**
 * Current authenticated user
 *
 * GET /auth/me
 */
router.get(
  '/me',
  authMiddleware,
  asyncHandler(controller.me)
);

export default router;
