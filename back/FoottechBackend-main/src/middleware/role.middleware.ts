import type { NextFunction, Request, Response } from 'express';

import {
  ForbiddenError,
  UnauthorizedError,
} from '../shared/errors/AppError.js';

export function requireRole(...allowedRoles: string[]) {
  return (
    req: Request,
    _res: Response,
    next: NextFunction,
  ): void => {
    if (!req.user) {
      throw new UnauthorizedError('Authentication required');
    }

    if (!allowedRoles.includes(req.user.role)) {
      throw new ForbiddenError(
        'Insufficient role to perform this action',
      );
    }

    next();
  };
}