import morgan from 'morgan';
import type{ StreamOptions } from 'morgan';
import { logger } from '../shared/logger/logger.js';

const stream: StreamOptions = { write: (message) => logger.info(message.trim()) };

export const loggerMiddleware = morgan(
  ':method :url :status :res[content-length] - :response-time ms',
  { stream }
);
