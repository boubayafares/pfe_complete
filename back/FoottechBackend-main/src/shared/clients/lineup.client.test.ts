import { describe, it, expect } from 'vitest';
import { createServer, type Server } from 'http';
import type { AddressInfo } from 'net';

import {
  fetchLineUpRecommendations,
  type LineUpRequestPayload,
  type LineUpRecommendationsResponse,
} from './lineup.client.js';
import {
  BadGatewayError,
  BadRequestError,
  GatewayTimeoutError,
  NotFoundError,
  ServiceUnavailableError,
} from '../errors/AppError.js';

const VALID_DTO: LineUpRecommendationsResponse = {
  matchId: 42,
  weightsVersion: 'equal-defaults',
  recommendations: [
    { playerId: 1, presenceScore: 82, performanceScore: 76, fatigueScore: 64, finalScore: 74.2, recommendedStatus: 'STARTER' },
    { playerId: 2, presenceScore: 55, performanceScore: 48, fatigueScore: 72, finalScore: 58.3, recommendedStatus: 'SUBSTITUTE' },
    { playerId: 3, presenceScore: 30, performanceScore: 25, fatigueScore: 40, finalScore: 31.7, recommendedStatus: 'NOT_SELECTED' },
  ],
};

const PAYLOAD: LineUpRequestPayload = {
  matchId: 42,
  players: [
    { playerId: 1, presenceRate: 0.9, recentPerformanceRating: 8.1, acuteChronicWorkloadRatio: 1.2, daysSinceLastMatch: 5 },
  ],
};

/** Serves a single canned response then closes. */
function fakeLineupServer(handler: (req: import('http').IncomingMessage, res: import('http').ServerResponse) => void): Promise<{ server: Server; url: string }> {
  return new Promise((resolve) => {
    const server = createServer(handler);
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address() as AddressInfo;
      resolve({ server, url: `http://127.0.0.1:${port}` });
    });
  });
}

async function withServer(
  handler: (req: import('http').IncomingMessage, res: import('http').ServerResponse) => void,
  run: (url: string) => Promise<void>
): Promise<void> {
  const { server, url } = await fakeLineupServer(handler);
  try {
    await run(url);
  } finally {
    await new Promise<void>((resolve) => {
      server.close(() => resolve());
      server.closeAllConnections?.();
      setTimeout(resolve, 2000);
    });
  }
}

describe('fetchLineUpRecommendations', () => {
  it('POSTs the camelCase payload to /api/v1/lineup/recommendations and parses the response', async () => {
    let receivedUrl = '';
    let receivedBody: unknown = null;
    await withServer((req, res) => {
      receivedUrl = req.url ?? '';
      let raw = '';
      req.on('data', (c) => { raw += c; });
      req.on('end', () => {
        receivedBody = JSON.parse(raw);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(VALID_DTO));
      });
    }, async (url) => {
      const result = await fetchLineUpRecommendations(PAYLOAD, { baseUrl: url });
      expect(receivedUrl).toBe('/api/v1/lineup/recommendations');
      expect(receivedBody).toEqual(PAYLOAD);
      expect(result.weightsVersion).toBe('equal-defaults');
      expect(result.recommendations).toHaveLength(3);
    });
  });

  it('(INT-01) returns 503 ServiceUnavailableError when the service is unreachable', async () => {
    await expect(
      fetchLineUpRecommendations(PAYLOAD, { baseUrl: 'http://127.0.0.1:1', timeoutMs: 500 })
    ).rejects.toBeInstanceOf(ServiceUnavailableError);
  });

  it('(INT-02) returns 504 GatewayTimeoutError when the service exceeds the 5s budget', async () => {
    await withServer((_req, _res) => {
      // never respond — the client must abort
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url, timeoutMs: 300 })
      ).rejects.toBeInstanceOf(GatewayTimeoutError);
    });
  });

  it('(INT-03) returns 502 BadGatewayError on invalid JSON body', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end('not json at all');
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url })
      ).rejects.toBeInstanceOf(BadGatewayError);
    });
  });

  it('(INT-03b) returns 502 BadGatewayError when the response violates the contract', async () => {
    await withServer((_req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ matchId: 42, weightsVersion: 'x', recommendations: [{ playerId: 1, finalScore: 'NaN' }] }));
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url })
      ).rejects.toBeInstanceOf(BadGatewayError);
    });
  });

  it('(INT-04) returns 400 BadRequestError when the service rejects the payload', async () => {
    await withServer((_req, res) => {
      res.writeHead(422, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ detail: 'players must not be empty' }));
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url })
      ).rejects.toBeInstanceOf(BadRequestError);
    });
  });

  it('(INT-04b) returns 404 NotFoundError when the service has no such route', async () => {
    await withServer((_req, res) => {
      res.writeHead(404);
      res.end();
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url })
      ).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  it('(INT-05) returns 502 BadGatewayError on an internal 500 from the service', async () => {
    await withServer((_req, res) => {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ detail: 'boom' }));
    }, async (url) => {
      await expect(
        fetchLineUpRecommendations(PAYLOAD, { baseUrl: url })
      ).rejects.toBeInstanceOf(BadGatewayError);
    });
  });
});