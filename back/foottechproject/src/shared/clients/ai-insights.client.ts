import { z } from 'zod';
import { env } from '../../config/env.js';
import {
  BadGatewayError,
  BadRequestError,
  GatewayTimeoutError,
  ServiceUnavailableError,
} from '../errors/AppError.js';

export const trendResponseSchema = z.object({
  playerId: z.number().int().positive(),
  direction: z.enum(['PROGRESSING', 'STABLE', 'DECLINING']),
  slopePerMonth: z.number(),
  rSquared: z.number(),
  dataPointsUsed: z.number().int().min(3),
});

export const clusteringResponseSchema = z.object({
  assignments: z.array(z.object({
    playerId: z.number().int().positive(),
    clusterId: z.number().int().min(0),
    distanceToCentroid: z.number().min(0),
  })),
  nClusters: z.number().int().min(2).max(10),
  inertia: z.number().min(0),
});

export const toneResponseSchema = z.object({
  flag: z.enum(['OK', 'TOO_HARSH', 'TOO_GENERIC', 'EMPTY']),
  matchedTerms: z.array(z.string()),
  suggestion: z.string().nullable(),
});

export type TrendResponse = z.infer<typeof trendResponseSchema>;
export type ClusteringResponse = z.infer<typeof clusteringResponseSchema>;
export type ToneResponse = z.infer<typeof toneResponseSchema>;

async function postInsight<T>(path: string, payload: unknown, schema: z.ZodType<T>): Promise<T> {
  const baseUrl = env.AI_INSIGHTS_SERVICE_URL.replace(/\/+$/, '');
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), env.AI_INSIGHTS_SERVICE_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(env.AI_SERVICE_TOKEN && { 'X-Service-Token': env.AI_SERVICE_TOKEN }),
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
  } catch (error) {
    if (controller.signal.aborted) {
      throw new GatewayTimeoutError(`AI insights service timeout after ${env.AI_INSIGHTS_SERVICE_TIMEOUT_MS}ms`);
    }
    throw new ServiceUnavailableError(`Cannot reach AI insights service: ${(error as Error).message}`);
  } finally {
    clearTimeout(timer);
  }

  let body: unknown;
  try {
    body = await response.json();
  } catch {
    body = undefined;
  }
  if (response.status === 400 || response.status === 422) {
    throw new BadRequestError('AI insights service rejected the payload', body);
  }
  if (!response.ok) {
    throw new BadGatewayError(`AI insights service returned ${response.status}`, body);
  }
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    throw new BadGatewayError('Malformed AI insights response', parsed.error.flatten());
  }
  return parsed.data;
}

export function detectPlayerTrend(payload: unknown): Promise<TrendResponse> {
  return postInsight('/api/v1/trend/detect', payload, trendResponseSchema);
}

export function clusterPlayers(payload: unknown): Promise<ClusteringResponse> {
  return postInsight('/api/v1/clustering/players', payload, clusteringResponseSchema);
}

export function analyzeCommentTone(comment: string): Promise<ToneResponse> {
  return postInsight('/api/v1/tone/analyze', { comment }, toneResponseSchema);
}
