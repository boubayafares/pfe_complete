import { createClient, type RedisClientType } from 'redis';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let client: RedisClientType | null = null;
let isConnected = false;

export async function initRedis(): Promise<void> {
  if (!env.REDIS_URL) {
    logger.warn('REDIS_URL not set — caching disabled');
    return;
  }

  try {
    client = createClient({ url: env.REDIS_URL });

    client.on('error', (err) => {
      logger.error('Redis error', { error: err.message });
      isConnected = false;
    });

    client.on('connect', () => {
      isConnected = true;
      logger.info('Redis connected');
    });

    client.on('disconnect', () => {
      isConnected = false;
      logger.warn('Redis disconnected');
    });

    await client.connect();
  } catch (error) {
    logger.error('Failed to connect to Redis', {
      error: error instanceof Error ? error.message : error,
    });
    client = null;
    isConnected = false;
  }
}

export async function closeRedis(): Promise<void> {
  if (client) {
    await client.quit();
    client = null;
    isConnected = false;
  }
}

export async function cacheGet<T>(key: string): Promise<T | null> {
  if (!client || !isConnected) return null;

  try {
    const raw = await client.get(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export async function cacheSet(
  key: string,
  value: unknown,
  ttlSeconds: number = 300
): Promise<void> {
  if (!client || !isConnected) return;

  try {
    await client.set(key, JSON.stringify(value), { EX: ttlSeconds });
  } catch {
    // Silently fail — caching is best-effort
  }
}

export async function cacheDel(pattern: string): Promise<void> {
  if (!client || !isConnected) return;

  try {
    if (pattern.includes('*')) {
      const keys = await client.keys(pattern);
      if (keys.length > 0) {
        await client.del(keys);
      }
    } else {
      await client.del(pattern);
    }
  } catch {
    // Silently fail
  }
}

export function isRedisConnected(): boolean {
  return isConnected;
}
