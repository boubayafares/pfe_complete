import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: process.env.BASE_URL || 'http://127.0.0.1:4000',
    specPattern: 'e2e/**/*.cy.{js,ts}',
    supportFile: 'support/e2e.ts',
    video: false,
    screenshotOnRunFailure: true,
    retries: { runMode: 2, openMode: 0 },
    env: {
      API_URL: process.env.API_URL || 'http://127.0.0.1:4000',
    },
    setupNodeEvents(on, config) {
      on('task', {
        log(message) {
          console.log(message);
          return null;
        },
      });
      return config;
    },
  },
});
