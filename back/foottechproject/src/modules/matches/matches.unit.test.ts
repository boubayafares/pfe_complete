import { describe, it, expect } from 'vitest';

import { normalizeScore } from './matches.repository.js';
import { generateAiRecommendationsSchema, createMatchSchema, setLineupSchema } from './matches.validation.js';
import { signAccessToken, verifyAccessToken } from '../../shared/utils/jwt.js';

describe('normalizeScore (0-100 IA scale → 0-1 schema scale)', () => {
  it('converts a 0-100 score into NUMERIC(4,3) 0-1 bucket', () => {
    expect(normalizeScore(82)).toBe(0.82);
    expect(normalizeScore(0)).toBe(0);
    expect(normalizeScore(100)).toBe(1);
  });

  it('clamps out-of-range values', () => {
    expect(normalizeScore(-5)).toBe(0);
    expect(normalizeScore(123)).toBe(1);
  });

  it('rounds to 3 decimals to satisfy NUMERIC(4,3)', () => {
    expect(normalizeScore(74.25)).toBe(0.743);
  });
});

describe('generateAiRecommendationsSchema', () => {
  it('accepts an empty body (optional playerIds)', () => {
    expect(generateAiRecommendationsSchema.safeParse({}).success).toBe(true);
  });

  it('accepts a list of positive player ids', () => {
    expect(generateAiRecommendationsSchema.safeParse({ playerIds: [1, 2, 3] }).success).toBe(true);
  });

  it('rejects non-array or negative ids', () => {
    expect(generateAiRecommendationsSchema.safeParse({ playerIds: '1' }).success).toBe(false);
    expect(generateAiRecommendationsSchema.safeParse({ playerIds: [-1] }).success).toBe(false);
  });
});

describe('createMatchSchema', () => {
  it('derives the team from authentication and accepts the match fields', () => {
    const ok = createMatchSchema.safeParse({ adversaire: 'OM', dateHeure: new Date().toISOString(), lieu: 'Stade', isHome: true });
    expect(ok.success).toBe(true);
    expect(createMatchSchema.safeParse({}).success).toBe(false);
  });
});

describe('setLineupSchema', () => {
  it('requires a non-empty entries array with playerId + status', () => {
    expect(setLineupSchema.safeParse({ entries: [] }).success).toBe(false);
    expect(
      setLineupSchema.safeParse({ entries: [{ playerId: 1, status: 'STARTER' }] }).success
    ).toBe(true);
    expect(
      setLineupSchema.safeParse({ entries: [{ playerId: 1 }] }).success
    ).toBe(false);
  });
});

describe('signAccessToken / verifyAccessToken', () => {
  it('round-trips a COACH token', () => {
    const token = signAccessToken({ sub: 7, role: 'COACH', teamId: 3 });
    const payload = verifyAccessToken(token);
    expect(payload.sub).toBe(7);
    expect(payload.role).toBe('COACH');
    expect(payload.teamId).toBe(3);
  });
});
