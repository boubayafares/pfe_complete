import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import type { ZodTypeAny } from 'zod';
import { ValidationError } from '../shared/errors/AppError.js';

interface ValidationTargets {
  body?: ZodTypeAny;
  query?: ZodTypeAny;
  params?: ZodTypeAny;
}

export function validate(schemas: ValidationTargets) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      if (schemas.body) req.body = schemas.body.parse(req.body);
      // ✅ لا تعيد تعيين req.query، بل خزن النتيجة في validatedQuery
      if (schemas.query) {
        (req as any).validatedQuery = schemas.query.parse(req.query);
        // يمكنك أيضاً الاحتفاظ بقيم req.query الأصلية، ولكن يُفضّل استخدام validatedQuery
      }
      if (schemas.params) req.params = schemas.params.parse(req.params) as typeof req.params;
      next();
    } catch (error) {
      if (error instanceof ZodError) throw new ValidationError(error.flatten());
      throw error;
    }
  };
}