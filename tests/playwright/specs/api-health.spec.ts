import { test, expect } from '@playwright/test';

test.describe('FootTech API Health', () => {
  test('GET /health returns ok', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.ok()).toBeTruthy();
    const body = await response.json();
    expect(body.status).toBe('ok');
    expect(body).toHaveProperty('timestamp');
  });

  test('GET /api/v1 returns 404 for unknown route', async ({ request }) => {
    const response = await request.get('/api/v1/nonexistent');
    expect(response.status()).toBe(404);
  });
});

test.describe('Auth Endpoints', () => {
  test('POST /api/v1/auth/login without body returns 400', async ({ request }) => {
    const response = await request.post('/api/v1/auth/login', {
      data: {},
    });
    expect([400, 422]).toContain(response.status());
  });
});

test.describe('AI Insights Service', () => {
  const AI_URL = process.env.AI_URL || 'http://localhost:8300';

  test('health check', async ({ request }) => {
    const response = await request.get(`${AI_URL}/health`);
    expect(response.ok()).toBeTruthy();
  });

  test('trend detect with insufficient data', async ({ request }) => {
    const response = await request.post(`${AI_URL}/api/v1/trend/detect`, {
      data: { playerId: 7, points: [{ date: '2026-01-01T00:00:00', value: 5.0 }] },
    });
    expect(response.status()).toBe(422);
  });
});

test.describe('Lineup Service', () => {
  const LINEUP_URL = process.env.LINEUP_URL || 'http://localhost:8100';

  test('health check', async ({ request }) => {
    const response = await request.get(`${LINEUP_URL}/health`);
    expect(response.ok()).toBeTruthy();
  });
});
