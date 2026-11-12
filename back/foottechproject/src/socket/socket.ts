import type  { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { env } from '../config/env.js';
import { verifyAccessToken } from '../shared/utils/jwt.js';
import { logger } from '../shared/logger/logger.js';
import { validateAuthenticatedUser } from '../shared/services/access-control.service.js';
import { query } from '../config/database.js';

let io: Server | undefined;

export function initSocket(httpServer: HttpServer): Server {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN === '*' && env.NODE_ENV === 'production' ? false : env.CORS_ORIGIN,
      credentials: env.CORS_ORIGIN !== '*',
    },
  });

  io.use(async (socket: Socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) return next(new Error('Missing authentication token'));
    try {
      socket.data.user = await validateAuthenticatedUser(verifyAccessToken(token));
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    logger.info('Socket connected', { userId: socket.data.user?.sub, role: socket.data.user?.role });

    // Every user auto-joins their own notification room.
    socket.join(`user:${socket.data.user.sub}`);

    socket.on('match:join', async (rawMatchId: unknown, acknowledge?: (result: { ok: boolean; error?: string }) => void) => {
      const matchId = Number(rawMatchId);
      if (!Number.isSafeInteger(matchId) || matchId <= 0) {
        acknowledge?.({ ok: false, error: 'Invalid match id' });
        return;
      }
      try {
        const result = await query<{ team_id: number }>(
          'SELECT team_id FROM matches WHERE id = $1 LIMIT 1',
          [matchId]
        );
        const match = result.rows[0];
        if (!match || Number(match.team_id) !== Number(socket.data.user.teamId)) {
          acknowledge?.({ ok: false, error: 'Access denied' });
          return;
        }
        await socket.join(`match:${matchId}`);
        acknowledge?.({ ok: true });
      } catch (error) {
        logger.error('Socket match room authorization failed', {
          userId: socket.data.user?.sub,
          matchId,
          error: error instanceof Error ? error.message : error,
        });
        acknowledge?.({ ok: false, error: 'Unable to join match' });
      }
    });
    socket.on('match:leave', (rawMatchId: unknown) => {
      const matchId = Number(rawMatchId);
      if (Number.isSafeInteger(matchId) && matchId > 0) {
        void socket.leave(`match:${matchId}`);
      }
    });
    socket.on('attendance:join', async (rawTrainingId: unknown, acknowledge?: (result: { ok: boolean; error?: string }) => void) => {
      const trainingId = Number(rawTrainingId);
      if (!Number.isSafeInteger(trainingId) || trainingId <= 0) {
        acknowledge?.({ ok: false, error: 'Invalid training id' });
        return;
      }
      try {
        const result = await query<{ team_id: number }>(
          'SELECT team_id FROM trainings WHERE id = $1 LIMIT 1',
          [trainingId]
        );
        const training = result.rows[0];
        if (!training || Number(training.team_id) !== Number(socket.data.user.teamId)) {
          acknowledge?.({ ok: false, error: 'Access denied' });
          return;
        }
        await socket.join(`attendance:${trainingId}`);
        acknowledge?.({ ok: true });
      } catch (error) {
        logger.error('Socket attendance room authorization failed', {
          userId: socket.data.user?.sub,
          trainingId,
          error: error instanceof Error ? error.message : error,
        });
        acknowledge?.({ ok: false, error: 'Unable to join attendance room' });
      }
    });
    socket.on('attendance:leave', (rawTrainingId: unknown) => {
      const trainingId = Number(rawTrainingId);
      if (Number.isSafeInteger(trainingId) && trainingId > 0) {
        void socket.leave(`attendance:${trainingId}`);
      }
    });

    socket.on('disconnect', () => {
      logger.info('Socket disconnected', { userId: socket.data.user?.sub });
    });
  });

  return io;
}

export function getIO(): Server {
  if (!io) throw new Error('Socket.io has not been initialized yet. Call initSocket(httpServer) first.');
  return io;
}

/** Broadcasts a live match update (score, event, lineup) to every client watching that match. */
export function emitMatchUpdate(matchId: number, payload: unknown): void {
  getIO().to(`match:${matchId}`).emit('match:update', payload);
}

/** Broadcasts a live attendance change to every client watching the training. */
export function emitAttendanceUpdate(trainingId: number, payload: unknown): void {
  if (!io) return;
  io.to(`attendance:${trainingId}`).emit('attendance:update', payload);
}

/** Pushes a notification to a specific user's private room (paired with the notifications module). */
export function emitNotification(userId: number, payload: unknown): void {
  getIO().to(`user:${userId}`).emit('notification:new', payload);
}
