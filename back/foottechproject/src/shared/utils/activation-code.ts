import crypto from 'crypto';
import { env } from '../../config/env.js';

/** Store only a keyed digest of a short-lived OTP in PostgreSQL. */
export function hashActivationCode(userId: number, code: string): string {
  return crypto
    .createHmac('sha256', env.JWT_ACCESS_SECRET)
    .update(`${userId}:${code}`)
    .digest('hex');
}

export function activationCodeMatches(userId: number, code: string, storedDigest: string): boolean {
  const candidate = Buffer.from(hashActivationCode(userId, code), 'hex');
  const stored = Buffer.from(storedDigest, 'hex');
  return candidate.length === stored.length && crypto.timingSafeEqual(candidate, stored);
}
