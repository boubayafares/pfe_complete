import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createServer, type Server } from 'http';
import type { AddressInfo } from 'net';

interface MockedRepo {
  findById: ReturnType<typeof vi.fn>;
  getLineUpFeatures: ReturnType<typeof vi.fn>;
  storeLineUpRecommendations: ReturnType<typeof vi.fn>;
}

const { mockedRepoInstances } = vi.hoisted(() => ({ mockedRepoInstances: [] as unknown[] }));

vi.mock('./matches.repository.js', () => {
  return {
    MatchesRepository: class {
      findById = vi.fn();
      getLineUpFeatures = vi.fn();
      storeLineUpRecommendations = vi.fn();

      constructor() {
        mockedRepoInstances.push(this);
      }
    },
  };
});

import { MatchesService } from './matches.service.js';
import { env } from '../../config/env.js';
import { NotFoundError, ServiceUnavailableError, GatewayTimeoutError, BadGatewayError, BadRequestError } from '../../shared/errors/AppError.js';

/** Helper: create a service and return its injected (mocked) repository. */
function makeService(): { service: MatchesService; repo: MockedRepo } {
  const service = new MatchesService();
  return { service, repo: mockedRepoInstances[mockedRepoInstances.length - 1] as MockedRepo };
}

const VALID_RESPONSE = {
  matchId: 42,
  weightsVersion: 'equal-defaults',
  recommendations: [
    { playerId: 1, presenceScore: 82, performanceScore: 76, fatigueScore: 64, finalScore: 74.2, recommendedStatus: 'STARTER' },
    { playerId: 2, presenceScore: 55, performanceScore: 48, fatigueScore: 72, finalScore: 58.3, recommendedStatus: 'SUBSTITUTE' },
  ],
};

const FEATURES = [
  { playerId: 1, presenceRate: 0.9, recentPerformanceRating: 8.1, acuteChronicWorkloadRatio: 1.2, daysSinceLastMatch: 5 },
  { playerId: 2, presenceRate: 0.4, recentPerformanceRating: 5.0, acuteChronicWorkloadRatio: 0.8, daysSinceLastMatch: 3 },
];

const STORED = [
  { id: 1, match_id: 42, player_id: 1, presence_score: 0.82, performance_score: 0.76, fatigue_score: 0.64, final_score: 0.742, recommended_status: 'STARTER' },
  { id: 2, match_id: 42, player_id: 2, presence_score: 0.55, performance_score: 0.48, fatigue_score: 0.72, final_score: 0.583, recommended_status: 'SUBSTITUTE' },
];

let originalUrl: string;
let originalTimeout: number;

beforeEach(() => {
  originalUrl = env.LINEUP_SERVICE_URL;
  originalTimeout = env.LINEUP_SERVICE_TIMEOUT_MS;
  vi.clearAllMocks();
});

async function withServer(handler: (req: import('http').IncomingMessage, res: import('http').ServerResponse) => void, run: (url: string) => Promise<void>): Promise<void> {
  const server: Server = createServer(handler);
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address() as AddressInfo;
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise<void>((resolve) => {
      server.close(() => resolve());
      server.closeAllConnections?.();
      setTimeout(resolve, 2000);
    });
  }
}

describe('MatchesService.generateRecommendations — INT', () => {
  it('INT-01: nominal flow — features sent to the AI service, response stored', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(VALID_RESPONSE));
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;
      env.LINEUP_SERVICE_TIMEOUT_MS = 1000;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue(FEATURES);
      repo.storeLineUpRecommendations.mockResolvedValue(STORED);

      const result = await service.generateRecommendations(42);

      expect(repo.getLineUpFeatures).toHaveBeenCalledWith(42, 7, undefined);
      expect(repo.storeLineUpRecommendations).toHaveBeenCalledWith(42, VALID_RESPONSE.recommendations);
      expect(result).toEqual(STORED);
    });
  });

  it('INT-04: match not found → 404, nothing is computed', async () => {
    const { service, repo } = makeService();
    repo.findById.mockResolvedValue(null);

    await expect(service.generateRecommendations(999)).rejects.toBeInstanceOf(NotFoundError);
    expect(repo.getLineUpFeatures).not.toHaveBeenCalled();
    expect(repo.storeLineUpRecommendations).not.toHaveBeenCalled();
  });

  it('INT-02: AI service unreachable → 503, nothing stored', async () => {
    const { service, repo } = makeService();
    repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
    repo.getLineUpFeatures.mockResolvedValue(FEATURES);

    env.LINEUP_SERVICE_URL = 'http://127.0.0.1:1';
    env.LINEUP_SERVICE_TIMEOUT_MS = 500;

    await expect(service.generateRecommendations(42)).rejects.toBeInstanceOf(ServiceUnavailableError);
    expect(repo.storeLineUpRecommendations).not.toHaveBeenCalled();
  });

  it('INT-03: AI service timeout → 504 (request never blocks)', async () => {
    await withServer((_req, _res) => {
      // never answers
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;
      env.LINEUP_SERVICE_TIMEOUT_MS = 300;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue(FEATURES);

      await expect(service.generateRecommendations(42)).rejects.toBeInstanceOf(GatewayTimeoutError);
      expect(repo.storeLineUpRecommendations).not.toHaveBeenCalled();
    });
  });

  it('INT-05: malformed AI response → 502', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ matchId: 42, recommendations: 'oops' }));
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue(FEATURES);

      await expect(service.generateRecommendations(42)).rejects.toBeInstanceOf(BadGatewayError);
    });
  });

  it('INT-06: AI service rejects the payload → 400', async () => {
    await withServer((_req, res) => {
      res.writeHead(422, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ detail: 'players must not be empty' }));
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue([]);

      await expect(service.generateRecommendations(42)).rejects.toBeInstanceOf(BadRequestError);
    });
  });

  it('INT-07: persistence failure → error surfaces instead of being swallowed', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(VALID_RESPONSE));
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue(FEATURES);
      repo.storeLineUpRecommendations.mockRejectedValue(new Error('relation ai_lineup_recommendations does not exist'));

      await expect(service.generateRecommendations(42)).rejects.toThrow('ai_lineup_recommendations');
    });
  });

  it('INT-01b: candidate playerIds are forwarded to the feature extractor', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(VALID_RESPONSE));
    }, async (url) => {
      env.LINEUP_SERVICE_URL = url;

      const { service, repo } = makeService();
      repo.findById.mockResolvedValue({ id: 42, team_id: 7 });
      repo.getLineUpFeatures.mockResolvedValue([FEATURES[0]!]);
      repo.storeLineUpRecommendations.mockResolvedValue([STORED[0]!]);

      await service.generateRecommendations(42, [1]);

      expect(repo.getLineUpFeatures).toHaveBeenCalledWith(42, 7, [1]);
    });
  });
});