import jwt from 'jsonwebtoken';
import { describe, expect, it } from 'vitest';
import { env } from '../../config/env.js';
import { activationCodeMatches, hashActivationCode } from './activation-code.js';
import { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken } from './jwt.js';

describe('authentication primitives', () => {
  it('stores OTPs as keyed digests and compares them safely', () => {
    const digest = hashActivationCode(42, '123456');
    expect(digest).not.toContain('123456');
    expect(activationCodeMatches(42, '123456', digest)).toBe(true);
    expect(activationCodeMatches(42, '654321', digest)).toBe(false);
    expect(activationCodeMatches(43, '123456', digest)).toBe(false);
  });

  it('round-trips issuer/audience-bound access and refresh tokens', () => {
    expect(verifyAccessToken(signAccessToken({ sub: 7, role: 'COACH', teamId: 3 }))).toEqual({
      sub: 7,
      role: 'COACH',
      teamId: 3,
    });
    expect(verifyRefreshToken(signRefreshToken({ sub: 7, tokenId: 9, teamId: 3 }))).toEqual({
      sub: 7,
      tokenId: 9,
      teamId: 3,
    });
  });

  it('rejects a correctly signed token without the expected issuer/audience', () => {
    const unboundToken = jwt.sign({ sub: 7, role: 'COACH' }, env.JWT_ACCESS_SECRET, { algorithm: 'HS256' });
    expect(() => verifyAccessToken(unboundToken)).toThrow();
  });
});
