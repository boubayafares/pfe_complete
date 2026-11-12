import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './specs',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI
    ? [['line'], ['junit', { outputFile: 'results.xml' }]]
    : [['line']],
  use: {
    baseURL: process.env.BASE_URL || 'http://127.0.0.1:4000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  // HTTP contract tests: the target stack is started explicitly by Compose.
  projects: [{ name: 'api' }],
});
