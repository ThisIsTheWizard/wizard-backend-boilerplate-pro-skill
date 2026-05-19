import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { errorHandler } from '#core/errorHandler.js';
import healthRouter from '#core/health.js';

export function createApp() {
  const app = express();

  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  app.use(helmet());
  app.use(cors({ origin: process.env.CORS_ORIGINS?.split(',') ?? '*' }));
  app.use(rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS ?? '60000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX ?? '100', 10),
    standardHeaders: true,
    legacyHeaders: false,
  }));

  app.use('/health', healthRouter);
  // auth, users, blog, docs routers wired here by the skill

  app.use(errorHandler);

  return app;
}
