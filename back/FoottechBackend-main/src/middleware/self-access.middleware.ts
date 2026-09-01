import type { NextFunction, Request, Response } from 'express';
import { ForbiddenError, UnauthorizedError } from '../shared/errors/AppError.js';

export function requireSelf(param = 'id') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) throw new UnauthorizedError('Authentication required');
    // `req.user.sub` comes from the JWT and is serialised as a string, while
    // `req.params[param]` is coerced to a number by the Zod param schema.
    // Compare numerically, otherwise the strict `!==` would always reject.
    if (Number(req.user.sub) !== Number(req.params[param])) throw new ForbiddenError('You can only access your own account');
    next();
  };
}
