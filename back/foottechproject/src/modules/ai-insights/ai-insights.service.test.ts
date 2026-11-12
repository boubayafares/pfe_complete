import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  getProjectSignals: vi.fn(),
}));

vi.mock('./ai-insights.repository.js', () => ({
  AiInsightsRepository: class {
    getProjectSignals = mocks.getProjectSignals;
  },
}));

vi.mock('../../shared/clients/ai-insights.client.js', () => ({
  analyzeCommentTone: vi.fn(),
  clusterPlayers: vi.fn(),
  detectPlayerTrend: vi.fn(),
}));

import { AiInsightsService } from './ai-insights.service.js';

describe('AiInsightsService expert project model', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.getProjectSignals.mockResolvedValue({
      players: 18,
      staff: 3,
      trainings: 12,
      matches: 8,
      exercises: 15,
      drawings: 10,
      attendanceRows: 120,
      evaluations: 40,
      notifications: 22,
    });
  });

  it('returns explainable capabilities and a bounded maturity score', async () => {
    const model = await new AiInsightsService().getExpertProjectModel(7);

    expect(model.name).toBe('FootTech Expert Coach AI v1');
    expect(model.maturityScore).toBe(100);
    expect(model.capabilities).toEqual(expect.arrayContaining([
      expect.objectContaining({ id: 'TACTICAL_EDITOR', status: 'ACTIVE' }),
      expect.objectContaining({ id: 'PERFORMANCE_ANALYTICS', status: 'ACTIVE' }),
    ]));
    expect(model.recommendations.length).toBeGreaterThan(0);
    expect(model.explainability.length).toBeGreaterThan(0);
    expect(mocks.getProjectSignals).toHaveBeenCalledWith(7);
  });
});
