import type{ NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../shared/utils/jwt.js';
import { UnauthorizedError } from '../shared/errors/AppError.js';
import { validateAuthenticatedUser } from '../shared/services/access-control.service.js';

export async function authMiddleware(req: Request, _res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing bearer token');
  }
  let payload;
  try {
    payload = verifyAccessToken(header.slice('Bearer '.length));
  } catch {
    throw new UnauthorizedError('Invalid or expired access token');
  }
  // Database/authorization errors must keep their real status (or surface as
  // 500); treating an unavailable database as a bad JWT hides outages.
  req.user = await validateAuthenticatedUser(payload);
  next();
}
