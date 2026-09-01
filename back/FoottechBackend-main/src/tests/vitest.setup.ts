// Executed once per test file, BEFORE any module is imported, so that
// env.ts (which throws without JWT secrets) evaluates with sane values.
process.env.NODE_ENV = process.env.NODE_ENV ?? 'test';
process.env.JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET ?? 'test-access-secret-0123456789abcdef';
process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET ?? 'test-refresh-secret-0123456789abcdef';
process.env.JWT_ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN ?? '15m';
process.env.JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN ?? '30d';
process.env.LINEUP_SERVICE_URL = process.env.LINEUP_SERVICE_URL ?? 'http://127.0.0.1:8100';
process.env.LINEUP_SERVICE_TIMEOUT_MS = process.env.LINEUP_SERVICE_TIMEOUT_MS ?? '5000';
process.env.DB_PASSWORD = process.env.DB_PASSWORD ?? 'test-nopassword';