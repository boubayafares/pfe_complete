import type{ Response } from 'express';

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface ApiSuccessBody<T> {
  success: true;
  message?: string;
  data: T;
  pagination?: Pagination;
}

export interface ApiErrorBody {
  success: false;
  message: string;
  details?: unknown;
}

export function sendSuccess<T>(
  res: Response, data: T, message?: string, statusCode = 200, pagination?: Pagination
): Response {
  const body: ApiSuccessBody<T> = { success: true, ...(message && { message }), data, ...(pagination && { pagination }) };
  return res.status(statusCode).json(body);
}

export function sendCreated<T>(res: Response, data: T, message = 'Resource created'): Response {
  return sendSuccess(res, data, message, 201);
}

export function sendNoContent(res: Response): Response {
  return res.status(204).send();
}

export function sendError(res: Response, message: string, statusCode = 500, details?: unknown): Response {
  const body: ApiErrorBody = { success: false, message, details };
  return res.status(statusCode).json(body);
}
