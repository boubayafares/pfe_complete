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
