export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly details?: unknown;

  constructor(message: string, statusCode = 500, details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    this.details = details;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class BadRequestError extends AppError {
  constructor(message = 'Bad request', details?: unknown) { super(message, 400, details); }
}
export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') { super(message, 401); }
}
export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') { super(message, 403); }
}
export class NotFoundError extends AppError {
  constructor(resource = 'Resource') { super(`${resource} not found`, 404); }
}
export class ConflictError extends AppError {
  constructor(message = 'Conflict', details?: unknown) { super(message, 409, details); }
}
export class ValidationError extends AppError {
  constructor(details: unknown) { super('Validation failed', 422, details); }
}
export class BadGatewayError extends AppError {
  constructor(message = 'Bad gateway', details?: unknown) { super(message, 502, details); }
}
export class ServiceUnavailableError extends AppError {
  constructor(message = 'Service unavailable', details?: unknown) { super(message, 503, details); }
}
export class GatewayTimeoutError extends AppError {
  constructor(message = 'Gateway timeout', details?: unknown) { super(message, 504, details); }
}
