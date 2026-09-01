import { z } from 'zod';
import { env } from '../../config/env.js';
import {
  BadGatewayError,
  BadRequestError,
  GatewayTimeoutError,
  NotFoundError,
  ServiceUnavailableError,
} from '../errors/AppError.js';

/**
 * Contrat du microservice lineup-recommendation-service (FastAPI, :8100).
 * cf. lineup-recommendation-service/README.md — endpoint POST /api/v1/lineup/recommendations.
 */

export const lineUpPlayerInputSchema = z.object({
  playerId: z.number().int().positive(),
  presenceRate: z.number().min(0).max(1),
  recentPerformanceRating: z.number().min(0).max(10),
  acuteChronicWorkloadRatio: z.number().min(0),
  daysSinceLastMatch: z.number().int().min(0),
});

export const lineUpRecommendationSchema = z.object({
  playerId: z.number(),
  presenceScore: z.number(),
  performanceScore: z.number(),
  fatigueScore: z.number(),
  finalScore: z.number(),
  recommendedStatus: z.enum(['STARTER', 'SUBSTITUTE', 'NOT_SELECTED']),
});

export const lineupResponseSchema = z.object({
  matchId: z.number(),
  weightsVersion: z.string(),
  recommendations: z.array(lineUpRecommendationSchema),
});

export type LineUpPlayerInput = z.infer<typeof lineUpPlayerInputSchema>;
export type LineUpRecommendation = z.infer<typeof lineUpRecommendationSchema>;
export type LineUpRecommendationsResponse = z.infer<typeof lineupResponseSchema>;

export interface LineUpRequestPayload {
  matchId: number;
  players: LineUpPlayerInput[];
}

function buildRequestUrl(baseUrl: string): string {
  const normalized = baseUrl.replace(/\/+$/, '');
  return `${normalized}/api/v1/lineup/recommendations`;
}

/**
 * Appelle lineup-recommendation-service et valide la réponse.
 *
 * Gestion d'erreurs :
 *  - service injoignable / test : ServiceUnavailableError (503)
 *  - timeout (5s par défaut)     : GatewayTimeoutError   (504)
 *  - HTTP 400                    : BadRequestError       (400)
 *  - HTTP 404                    : NotFoundError         (404)
 *  - HTTP 5xx                    : BadGatewayError       (502)
 *  - JSON invalide / contrat violé : BadGatewayError / BadRequestError
 *
 * Une requête Express ne doit jamais rester bloquée : timeout garanti.
 */
export async function fetchLineUpRecommendations(
  payload: LineUpRequestPayload,
  overrides?: { baseUrl?: string; timeoutMs?: number }
): Promise<LineUpRecommendationsResponse> {
  const baseUrl = overrides?.baseUrl ?? env.LINEUP_SERVICE_URL;
  const timeoutMs = overrides?.timeoutMs ?? env.LINEUP_SERVICE_TIMEOUT_MS;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response: Response;
  try {
    response = await fetch(buildRequestUrl(baseUrl), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
  } catch (error) {
    if (controller.signal.aborted) {
      throw new GatewayTimeoutError(`Lineup service timeout after ${timeoutMs}ms`);
    }
    throw new ServiceUnavailableError(
      `Cannot reach lineup-recommendation-service at ${baseUrl}: ${(error as Error).message}`
    );
  } finally {
    clearTimeout(timer);
  }

  if (response.status === 404) {
    throw new NotFoundError('Lineup recommendation endpoint');
  }

  if (response.status === 400 || response.status === 422) {
    let detail = await safeReadBody(response);
    throw new BadRequestError(`Lineup service rejected the payload (${response.status})`, detail);
  }

  if (response.status >= 500) {
    let detail = await safeReadBody(response);
    throw new BadGatewayError(`Lineup service internal error (${response.status})`, detail);
  }

  if (!response.ok) {
    throw new BadGatewayError(`Unexpected lineup service status ${response.status}`);
  }

  let raw: unknown;
  try {
    raw = await response.json();
  } catch {
    throw new BadGatewayError('Invalid JSON response from lineup service');
  }

  const parsed = lineupResponseSchema.safeParse(raw);
  if (!parsed.success) {
    throw new BadGatewayError('Malformed lineup service response', parsed.error.flatten());
  }

  return parsed.data;
}

async function safeReadBody(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch {
    try {
      return await response.text();
    } catch {
      return undefined;
    }
  }
}