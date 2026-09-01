import type  { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { env } from '../config/env.js';
import { verifyAccessToken } from '../shared/utils/jwt.js';
import { logger } from '../shared/logger/logger.js';

let io: Server | undefined;

export function initSocket(httpServer: HttpServer): Server {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN === '*' && env.NODE_ENV === 'production' ? false : env.CORS_ORIGIN,
      credentials: env.CORS_ORIGIN !== '*',
    },
  });

  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) return next(new Error('Missing authentication token'));
    try {
      socket.data.user = verifyAccessToken(token);
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    logger.info('Socket connected', { userId: socket.data.user?.sub, role: socket.data.user?.role });

    // Every user auto-joins their own notification room.
    socket.join(`user:${socket.data.user.sub}`);

    socket.on('match:join', (matchId: number) => socket.join(`match:${matchId}`));
    socket.on('match:leave', (matchId: number) => socket.leave(`match:${matchId}`));

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

/** Pushes a notification to a specific user's private room (paired with the notifications module). */
export function emitNotification(userId: number, payload: unknown): void {
  getIO().to(`user:${userId}`).emit('notification:new', payload);
}
