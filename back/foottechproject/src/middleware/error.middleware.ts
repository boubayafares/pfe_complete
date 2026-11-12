import type{ NextFunction, Request, Response } from 'express';
import { AppError, ConflictError } from '../shared/errors/AppError.js';
import { sendError } from '../shared/responses/ApiResponse.js';
import { logger } from '../shared/logger/logger.js';

export function notFoundMiddleware(req: Request, _res: Response, next: NextFunction): void {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
}

interface DatabaseError extends Error {
  code?: string;
  constraint?: string;
}

/** Converts expected PostgreSQL rejections into stable, non-sensitive API errors. */
export function databaseErrorToAppError(error: Error): AppError | null {
  const code = (error as DatabaseError).code;
  switch (code) {
    case '23505':
      return new ConflictError('Resource already exists');
    case '23503':
      return new AppError('Referenced resource does not exist', 422);
    case '23514':
      return new AppError('Data violates a business rule', 422);
    case '23502':
      return new AppError('A required value is missing', 422);
    case '22001':
    case '22P02':
      return new AppError('Invalid data format', 422);
    default:
      return null;
  }
}

export function errorMiddleware(
  err: Error, req: Request, res: Response, _next: NextFunction
): void {
  if (err instanceof AppError) {
    if (!err.isOperational || err.statusCode >= 500) {
      logger.error(err.message, { stack: err.stack, path: req.originalUrl });
    }
    sendError(res, err.message, err.statusCode, err.details);
    return;
  }
  const databaseError = databaseErrorToAppError(err);
  if (databaseError) {
    logger.warn('Database rejected request', {
      code: (err as DatabaseError).code,
      constraint: (err as DatabaseError).constraint,
      path: req.originalUrl,
    });
    sendError(res, databaseError.message, databaseError.statusCode);
    return;
  }
  logger.error('Unhandled error', { message: err.message, stack: err.stack, path: req.originalUrl });
  sendError(res, 'Internal server error', 500);
}
