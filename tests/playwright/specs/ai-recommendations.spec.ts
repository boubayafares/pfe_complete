import { test, expect } from '@playwright/test';

test.describe('AI routes — public access boundary', () => {
  test('lineup generation requires authentication', async ({ request }) => {
    const response = await request.post('/api/v1/matches/1/ai-recommendations', {
      data: { playerIds: [1] },
    });
    expect(response.status()).toBe(401);
  });

  test('team clustering requires authentication', async ({ request }) => {
    const response = await request.get('/api/v1/ai-insights/clusters?nClusters=2');
    expect(response.status()).toBe(401);
  });
});
