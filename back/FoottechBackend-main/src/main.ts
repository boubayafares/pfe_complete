import http from 'http';
import fs from 'fs';
import { createApp } from './app.js';
import { env } from './config/env.js';
import {
  checkDatabaseConnection,
  closeDatabasePool,
} from './config/database.js';
import { initSocket } from './socket/socket.js';
import { logger } from './shared/logger/logger.js';
import { initRedis, closeRedis } from './shared/services/cache.service.js';
import { initFirebase } from './shared/services/firebase.service.js';

async function bootstrap(): Promise<void> {
  try {
    logger.info('1. Checking database...');
    await checkDatabaseConnection();

    logger.info('2. Creating app...');
    const app = createApp();

    logger.info('2b. Ensuring upload directory exists...');
    fs.mkdirSync(env.UPLOAD_DIR, { recursive: true });

    logger.info('2c. Initializing Redis...');
    await initRedis();

    logger.info('2d. Initializing Firebase...');
    initFirebase();

    logger.info('3. Creating HTTP server...');
    const httpServer = http.createServer(app);

    logger.info('4. Initializing socket...');
    initSocket(httpServer);

    const shutdown = async (signal: string) => {
      logger.info(`Received ${signal}, shutting down gracefully...`);

      try {
        await new Promise<void>((resolve) => {
          httpServer.close(() => resolve());
          setTimeout(() => resolve(), 5000);
        });
      } catch (error) {
        logger.error('Error while closing HTTP server', { error });
      }

      try {
        await closeRedis();
      } catch (error) {
        logger.error('Error while closing Redis', { error });
      }

      try {
        await closeDatabasePool();
      } catch (error) {
        logger.error('Error while closing database pool', { error });
      }
      process.exit(0);
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));

    logger.info('5. Starting server...');

    httpServer.listen(env.PORT, () => {
      logger.info(
        `FootTech v2 API listening on port ${env.PORT} (${env.NODE_ENV})`
      );

      logger.info(
        `Swagger docs available at http://localhost:${env.PORT}/docs`
      );
    });
  } catch (error) {
    logger.error('Bootstrap failed', {
      error: error instanceof Error ? error.stack : error,
    });

    throw error;
  }
}

bootstrap().catch((error) => {
  logger.error('Fatal error during bootstrap', {
    error: error instanceof Error ? error.message : error,
  });

  process.exit(1);
});
