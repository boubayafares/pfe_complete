import type{ NextFunction, Request, Response } from 'express';
import { AppError } from '../shared/errors/AppError.js';
import { sendError } from '../shared/responses/ApiResponse.js';
import { logger } from '../shared/logger/logger.js';

export function notFoundMiddleware(req: Request, _res: Response, next: NextFunction): void {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
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
  logger.error('Unhandled error', { message: err.message, stack: err.stack, path: req.originalUrl });
  sendError(res, 'Internal server error', 500);
}
