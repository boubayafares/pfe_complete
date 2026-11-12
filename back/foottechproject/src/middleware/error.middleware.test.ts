import { describe, expect, it } from 'vitest';
import { databaseErrorToAppError } from './error.middleware.js';

function databaseError(code: string): Error {
  return Object.assign(new Error('internal database detail'), { code });
}

describe('databaseErrorToAppError', () => {
  it.each([
    ['23505', 409, 'Resource already exists'],
    ['23503', 422, 'Referenced resource does not exist'],
    ['23514', 422, 'Data violates a business rule'],
    ['23502', 422, 'A required value is missing'],
    ['22001', 422, 'Invalid data format'],
    ['22P02', 422, 'Invalid data format'],
  ])('maps PostgreSQL %s without leaking database details', (code, statusCode, message) => {
    expect(databaseErrorToAppError(databaseError(code))).toMatchObject({ statusCode, message });
  });

  it('leaves unknown failures to the generic 500 handler', () => {
    expect(databaseErrorToAppError(databaseError('08006'))).toBeNull();
  });
});
