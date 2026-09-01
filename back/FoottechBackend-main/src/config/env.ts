import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: parseInt(process.env.PORT ?? '4000', 10),

  DB_HOST: process.env.DB_HOST ?? 'localhost',
  DB_PORT: parseInt(process.env.DB_PORT ?? '5432', 10),
  DB_NAME: process.env.DB_NAME ?? 'foottech',
  DB_USER: process.env.DB_USER ?? 'postgres',
  DB_PASSWORD: process.env.DB_PASSWORD ?? '',
  DB_SCHEMA: process.env.DB_SCHEMA ?? 'platform',
  DB_SSL: process.env.DB_SSL === 'true',
  DB_POOL_MAX: parseInt(process.env.DB_POOL_MAX ?? '20', 10),

  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET ?? '',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET ?? '',
  JWT_ACCESS_EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d',

  CORS_ORIGIN: process.env.CORS_ORIGIN ?? '*',

  UPLOAD_DIR: process.env.UPLOAD_DIR ?? path.resolve(process.cwd(), 'src/uploads'),
  MAX_UPLOAD_MB: parseInt(process.env.MAX_UPLOAD_MB ?? '20', 10),

  BCRYPT_SALT_ROUNDS: parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '12', 10),

  OTP_LENGTH: parseInt(process.env.OTP_LENGTH ?? '6', 10),
  OTP_EXPIRES_MIN: parseInt(process.env.OTP_EXPIRES_MIN ?? '10', 10),

  SMS_PROVIDER_API_KEY: process.env.SMS_PROVIDER_API_KEY ?? '',

  // ─── Redis ──────────────────────────────────────────────
  REDIS_URL: process.env.REDIS_URL ?? '',

  // ─── Twilio SMS ─────────────────────────────────────────
  TWILIO_ACCOUNT_SID: process.env.TWILIO_ACCOUNT_SID ?? '',
  TWILIO_AUTH_TOKEN: process.env.TWILIO_AUTH_TOKEN ?? '',
  TWILIO_PHONE_NUMBER: process.env.TWILIO_PHONE_NUMBER ?? '',

  // ─── Firebase Push Notifications ────────────────────────
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID ?? '',
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY ?? '',
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL ?? '',

  // ─── AI Microservices ───────────────────────────────────
  // Lineup Recommendation Service (FastAPI, port 8100).
  // localhost en dev, nom de service Docker sinon (docker-compose).
  LINEUP_SERVICE_URL: process.env.LINEUP_SERVICE_URL ?? 'http://localhost:8100',
  // Timeout d'appel (ms) — 5s demandé, ne jamais bloquer une requête Express.
  LINEUP_SERVICE_TIMEOUT_MS: parseInt(process.env.LINEUP_SERVICE_TIMEOUT_MS ?? '5000', 10),
  // AI Insights Service (FastAPI, port 8300).
  AI_INSIGHTS_SERVICE_URL: process.env.AI_INSIGHTS_SERVICE_URL ?? 'http://localhost:8300',
};


if (!env.JWT_ACCESS_SECRET || !env.JWT_REFRESH_SECRET) {
  throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be set in .env');
}

if (env.NODE_ENV === 'production') {
  if (env.JWT_ACCESS_SECRET.length < 32 || env.JWT_REFRESH_SECRET.length < 32) {
    throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be set to strong secrets (>= 32 chars) in production');
  }
}

export type Env = typeof env;
