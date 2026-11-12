import type{ Pagination } from '../responses/ApiResponse.js';

export interface PaginationQuery { page?: string | number; limit?: string | number; }
export interface ParsedPagination { page: number; limit: number; offset: number; }

export const DEFAULT_PAGE = 1;
export const DEFAULT_LIMIT = 20;
export const MAX_LIMIT = 100;

export function parsePagination(query: PaginationQuery): ParsedPagination {
  const page = Math.max(1, parseInt(String(query.page ?? DEFAULT_PAGE), 10) || DEFAULT_PAGE);
  const rawLimit = parseInt(String(query.limit ?? DEFAULT_LIMIT), 10) || DEFAULT_LIMIT;
  const limit = Math.min(Math.max(1, rawLimit), MAX_LIMIT);
  return { page, limit, offset: (page - 1) * limit };
}

export function buildPaginationMeta(page: number, limit: number, total: number): Pagination {
  return { page, limit, total, totalPages: Math.max(1, Math.ceil(total / limit)) };
}
