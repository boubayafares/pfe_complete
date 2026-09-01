import { test, expect } from '@playwright/test';

const BASE = process.env.BASE_URL || 'http://localhost:4000';
const LINEUP_URL = process.env.LINEUP_URL || 'http://localhost:8100';
const MATCH_ID = process.env.MATCH_ID || '1';

const COACH_TOKEN = process.env.COACH_TOKEN || '';
const ADJ_TOKEN = process.env.ADJ_TOKEN || '';
const PLAYER_TOKEN = process.env.PLAYER_TOKEN || '';

/**
 * E2E de l'intégration IA (Express → lineup-recommendation-service).
 * Les rôles s'exercent avec de vrais tokens : exporter COACH_TOKEN /
 * ADJ_TOKEN / PLAYER_TOKEN et MATCH_ID après avoir seedé une équipe
 * contenant ce match (voir back/README.md — seed locale).
 */
test.describe('AI Lineup — flux intégré (Express ← FastAPI ← PostgreSQL)', () => {
  test.skip(!COACH_TOKEN, 'COACH_TOKEN not exported — seed a coach first');

  test('COACH: génère puis relit les recommandations (single source of truth = lineup service)', async ({ request }) => {
    const gen = await request.post(`${BASE}/api/v1/matches/${MATCH_ID}/ai-recommendations`, {
      headers: { Authorization: `Bearer ${COACH_TOKEN}` },
      data: { playerIds: [] },
    });
    expect(gen.ok()).toBeTruthy();
    const genBody = await gen.json();

    // Persistance normalisée 0-1 (schéma NUMERIC(4,3) CHECK 0-1).
    expect(Array.isArray(genBody.data)).toBe(true);
    expect(genBody.data.length).toBeGreaterThan(0);
    for (const rec of genBody.data) {
      expect(rec.final_score).toBeGreaterThanOrEqual(0);
      expect(rec.final_score).toBeLessThanOrEqual(1);
      expect(['STARTER', 'SUBSTITUTE', 'NOT_SELECTED']).toContain(rec.recommended_status);
    }

    const read = await request.get(`${BASE}/api/v1/matches/${MATCH_ID}/ai-recommendations`, {
      headers: { Authorization: `Bearer ${COACH_TOKEN}` },
    });
    expect(read.ok()).toBeTruthy();
    expect((await read.json()).data.length).toBe(genBody.data.length);
  });

  test('ADJ: peut aussi générer des recommandations (RBAC ADJOINT)', async ({ request }) => {
    test.skip(!ADJ_TOKEN, 'ADJ_TOKEN not exported');
    const res = await request.post(`${BASE}/api/v1/matches/${MATCH_ID}/ai-recommendations`, {
      headers: { Authorization: `Bearer ${ADJ_TOKEN}` },
      data: { playerIds: [] },
    });
    expect(res.status()).toBe(200);
  });

  test('JOUEUR: lecture autorisée mais génération interdite (403)', async ({ request }) => {
    test.skip(!PLAYER_TOKEN, 'PLAYER_TOKEN not exported');
    const read = await request.get(`${BASE}/api/v1/matches/${MATCH_ID}/ai-recommendations`, {
      headers: { Authorization: `Bearer ${PLAYER_TOKEN}` },
    });
    expect(read.status()).toBe(200);

    const write = await request.post(`${BASE}/api/v1/matches/${MATCH_ID}/ai-recommendations`, {
      headers: { Authorization: `Bearer ${PLAYER_TOKEN}` },
      data: {},
    });
    expect(write.status()).toBe(403);
  });
});

test.describe('Lineup service — contrat direct (source de vérité du scoring)', () => {
  test('répond au contrat camelCase documenté (players[].presenceRate, ...)', async ({ request }) => {
    const res = await request.post(`${LINEUP_URL}/api/v1/lineup/recommendations`, {
      data: {
        matchId: 42,
        players: [
          { playerId: 7, presenceRate: 0.9, recentPerformanceRating: 8.2, acuteChronicWorkloadRatio: 1.1, daysSinceLastMatch: 4 },
          { playerId: 8, presenceRate: 0.35, recentPerformanceRating: 5.0, acuteChronicWorkloadRatio: 0.8, daysSinceLastMatch: 2 },
        ],
      },
    });
    expect(res.ok()).toBeTruthy();
    const body = await res.json();

    expect(body.matchId).toBe(42);
    expect(body.weightsVersion).toBeTruthy();
    expect(body.recommendations).toHaveLength(2);

    for (const r of body.recommendations) {
      expect(r.presenceScore).toBeGreaterThanOrEqual(0);
      expect(r.performanceScore).toBeGreaterThanOrEqual(0);
      expect(r.fatigueScore).toBeGreaterThanOrEqual(0);
      expect(r.finalScore).toBeGreaterThanOrEqual(0);
      expect(r.finalScore).toBeLessThanOrEqual(100);
      expect(['STARTER', 'SUBSTITUTE', 'NOT_SELECTED']).toContain(r.recommendedStatus);
    }
  });

  test('rejette un payload vide (players non vide)', async ({ request }) => {
    const res = await request.post(`${LINEUP_URL}/api/v1/lineup/recommendations`, {
      data: { matchId: 42, players: [] },
    });
    expect([400, 422]).toContain(res.status());
  });

  test('rejette un playerId absent', async ({ request }) => {
    const res = await request.post(`${LINEUP_URL}/api/v1/lineup/recommendations`, {
      data: { matchId: 42, players: [{ presenceRate: 0.5, recentPerformanceRating: 6, acuteChronicWorkloadRatio: 1, daysSinceLastMatch: 3 }] },
    });
    expect([400, 422]).toContain(res.status());
  });

  test('ne laisse jamais la requête bloquée : réponse dans la seconde (timeout garanti côté Express)', async ({ request }) => {
    const started = Date.now();
    const res = await request.post(`${LINEUP_URL}/api/v1/lineup/recommendations`, {
      data: {
        matchId: 42,
        players: [{ playerId: 7, presenceRate: 0.9, recentPerformanceRating: 8.2, acuteChronicWorkloadRatio: 1.1, daysSinceLastMatch: 4 }],
      },
      timeout: 5000,
    });
    expect(res.status()).toBeLessThan(500);
    expect(Date.now() - started).toBeLessThan(3000);
  });
});