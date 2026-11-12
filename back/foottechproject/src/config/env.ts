import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

dotenv.config({ path: path.join(projectRoot, '.env') });

function integerFromEnv(name: string, fallback: number, options: { min?: number; max?: number } = {}): number {
  const value = Number.parseInt(process.env[name] ?? String(fallback), 10);
  if (!Number.isInteger(value) || (options.min !== undefined && value < options.min) || (options.max !== undefined && value > options.max)) {
    throw new Error(`${name} must be an integer${options.min !== undefined ? ` >= ${options.min}` : ''}${options.max !== undefined ? ` and <= ${options.max}` : ''}`);
  }
  return value;
}

const nodeEnv = process.env.NODE_ENV ?? 'development';
if (!['development', 'test', 'production'].includes(nodeEnv)) {
  throw new Error('NODE_ENV must be development, test, or production');
}

const dbSchema = process.env.DB_SCHEMA ?? 'platform';
if (!/^[a-z_][a-z0-9_]*$/i.test(dbSchema)) {
  throw new Error('DB_SCHEMA must be a valid PostgreSQL identifier');
}

export const env = {
  NODE_ENV: nodeEnv,
  PORT: integerFromEnv('PORT', 4000, { min: 1, max: 65535 }),

  DB_HOST: process.env.DB_HOST ?? 'localhost',
  DB_PORT: integerFromEnv('DB_PORT', 5432, { min: 1, max: 65535 }),
  DB_NAME: process.env.DB_NAME ?? 'foottech',
  DB_USER: process.env.DB_USER ?? 'postgres',
  DB_PASSWORD: process.env.DB_PASSWORD ?? '',
  DB_SCHEMA: dbSchema,
  DB_SSL: process.env.DB_SSL === 'true',
  DB_SSL_REJECT_UNAUTHORIZED: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
  DB_POOL_MAX: integerFromEnv('DB_POOL_MAX', 20, { min: 1, max: 100 }),

  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET ?? '',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET ?? '',
  JWT_ACCESS_EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d',
  JWT_ISSUER: process.env.JWT_ISSUER ?? 'foottech-api',
  JWT_AUDIENCE: process.env.JWT_AUDIENCE ?? 'foottech-app',

  CORS_ORIGIN: process.env.CORS_ORIGIN ?? '*',
  TRUST_PROXY: process.env.TRUST_PROXY === 'true',

  UPLOAD_DIR: process.env.UPLOAD_DIR
    ? path.resolve(projectRoot, process.env.UPLOAD_DIR)
    : path.join(projectRoot, 'src/uploads'),
  MAX_UPLOAD_MB: integerFromEnv('MAX_UPLOAD_MB', 10, { min: 1, max: 25 }),

  BCRYPT_SALT_ROUNDS: integerFromEnv('BCRYPT_SALT_ROUNDS', 12, { min: 10, max: 15 }),

  OTP_LENGTH: integerFromEnv('OTP_LENGTH', 6, { min: 6, max: 8 }),
  OTP_EXPIRES_MIN: integerFromEnv('OTP_EXPIRES_MIN', 10, { min: 2, max: 30 }),
  OTP_DEV_CODE: process.env.OTP_DEV_CODE?.trim() ?? '',

  SMS_PROVIDER_API_KEY: process.env.SMS_PROVIDER_API_KEY ?? '',

  // ─── Redis ──────────────────────────────────────────────
  REDIS_URL: process.env.REDIS_URL ?? '',

  // ─── Twilio SMS ─────────────────────────────────────────
  TWILIO_ACCOUNT_SID: process.env.TWILIO_ACCOUNT_SID ?? '',
  TWILIO_AUTH_TOKEN: process.env.TWILIO_AUTH_TOKEN ?? '',
  TWILIO_PHONE_NUMBER: process.env.TWILIO_PHONE_NUMBER ?? '',

  // ─── SMTP email convocations ────────────────────────────
  SMTP_HOST: process.env.SMTP_HOST ?? '',
  SMTP_PORT: integerFromEnv('SMTP_PORT', 587, { min: 1, max: 65535 }),
  SMTP_USER: process.env.SMTP_USER ?? '',
  SMTP_PASSWORD: process.env.SMTP_PASSWORD ?? '',
  SMTP_FROM: process.env.SMTP_FROM ?? '',
  SMTP_SECURE: process.env.SMTP_SECURE === 'true',

  // ─── Firebase Push Notifications ────────────────────────
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID ?? '',
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY ?? '',
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL ?? '',

  // ─── AI Microservices ───────────────────────────────────
  // Lineup Recommendation Service (FastAPI, port 8100).
  // localhost en dev, nom de service Docker sinon (docker-compose).
  LINEUP_SERVICE_URL: process.env.LINEUP_SERVICE_URL ?? 'http://localhost:8100',
  // Timeout d'appel (ms) — 5s demandé, ne jamais bloquer une requête Express.
  LINEUP_SERVICE_TIMEOUT_MS: integerFromEnv('LINEUP_SERVICE_TIMEOUT_MS', 5000, { min: 500, max: 30000 }),
  // AI Insights Service (FastAPI, port 8300).
  AI_INSIGHTS_SERVICE_URL: process.env.AI_INSIGHTS_SERVICE_URL ?? 'http://localhost:8300',
  AI_INSIGHTS_SERVICE_TIMEOUT_MS: integerFromEnv('AI_INSIGHTS_SERVICE_TIMEOUT_MS', 5000, { min: 500, max: 30000 }),
  AI_SERVICE_TOKEN: process.env.AI_SERVICE_TOKEN ?? '',
};


if (!env.JWT_ACCESS_SECRET || !env.JWT_REFRESH_SECRET) {
  throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be set in .env');
}

if (env.OTP_DEV_CODE && !/^\d{6,8}$/.test(env.OTP_DEV_CODE)) {
  throw new Error('OTP_DEV_CODE must contain between 6 and 8 digits');
}

if (env.NODE_ENV === 'production' && env.OTP_DEV_CODE) {
  throw new Error('OTP_DEV_CODE must never be enabled in production');
}

if (env.NODE_ENV === 'production') {
  if (env.JWT_ACCESS_SECRET.length < 32 || env.JWT_REFRESH_SECRET.length < 32) {
    throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be set to strong secrets (>= 32 chars) in production');
  }
  if (!env.DB_PASSWORD) {
    throw new Error('DB_PASSWORD must be set in production');
  }
  if (env.AI_SERVICE_TOKEN.length < 32) {
    throw new Error('AI_SERVICE_TOKEN must be at least 32 characters in production');
  }
}

export type Env = typeof env;
