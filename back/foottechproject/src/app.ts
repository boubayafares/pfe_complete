import express from 'express';
import type { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import swaggerUi from 'swagger-ui-express';

import { env } from './config/env.js';
import { swaggerSpec } from './config/swagger.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import { notFoundMiddleware, errorMiddleware } from './middleware/error.middleware.js';
import { apiRateLimit } from './middleware/auth-rate-limit.middleware.js';

import authRoutes from './modules/auth/auth.routes.js';
import usersRoutes from './modules/users/users.routes.js';
import teamsRoutes from './modules/teams/teams.routes.js';
import playersRoutes from './modules/players/players.routes.js';
import seasonsRoutes from './modules/seasons/seasons.routes.js';
import weeklyPlanningsRoutes from './modules/weekly-plannings/weekly-plannings.routes.js';
import trainingsRoutes from './modules/trainings/trainings.routes.js';
import exerciseProposalsRoutes from './modules/exercise-proposals/exercise-proposals.routes.js';
import attendanceRoutes from './modules/attendance/attendance.routes.js';
import matchesRoutes from './modules/matches/matches.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import dashboardRoutes from './modules/dashboard/dashboard.routes.js';
import calendarEventsRoutes from './modules/calendar-events/calendar-events.routes.js';
import aiInsightsRoutes from './modules/ai-insights/ai-insights.routes.js';

export function createApp(): Application {
  const app = express();

  if (env.TRUST_PROXY) app.set('trust proxy', 1);
  app.disable('x-powered-by');

  const allowedOrigins = env.CORS_ORIGIN === '*'
    ? '*'
    : env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean);

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  // Authentication uses bearer tokens, not cookies, so credentialed CORS is
  // unnecessary and wildcard development origins remain standards-compliant.
  app.use(cors({ origin: allowedOrigins, credentials: false }));
  app.use(compression());
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(loggerMiddleware);
  // Match reports are served only through their team-authorized API endpoint.
  app.use('/uploads/reports', (_req, res) => res.sendStatus(404));
  app.use('/uploads', express.static(env.UPLOAD_DIR, { dotfiles: 'deny', index: false, maxAge: '1h' }));

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  if (env.NODE_ENV !== 'production') {
    app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  }

  const api = express.Router();
  api.use(apiRateLimit);
  api.use('/auth', authRoutes);
  api.use('/users', usersRoutes);
  api.use('/teams', teamsRoutes);
  api.use('/players', playersRoutes);
  api.use('/seasons', seasonsRoutes);
  api.use('/weekly-plannings', weeklyPlanningsRoutes);
  api.use('/trainings', trainingsRoutes);
  api.use('/exercise-proposals', exerciseProposalsRoutes);
  api.use('/attendance', attendanceRoutes);
  api.use('/matches', matchesRoutes);
  api.use('/notifications', notificationsRoutes);
  api.use('/dashboard', dashboardRoutes);
  api.use('/calendar-events', calendarEventsRoutes);
  api.use('/ai-insights', aiInsightsRoutes);

  app.use('/api/v1', api);

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}
