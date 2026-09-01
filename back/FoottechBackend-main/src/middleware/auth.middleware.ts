import type{ NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../shared/utils/jwt.js';
import { UnauthorizedError } from '../shared/errors/AppError.js';

export function authMiddleware(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing bearer token');
  }
  try {
    req.user = verifyAccessToken(header.slice('Bearer '.length));
    next();
  } catch {
    throw new UnauthorizedError('Invalid or expired access token');
  }
}
