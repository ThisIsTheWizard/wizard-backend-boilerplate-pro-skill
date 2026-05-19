import { Router } from 'express';
import { readFileSync } from 'fs';
import { join } from 'path';

const router = Router();

let version = '1.0.0';
try {
  const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf-8'));
  version = pkg.version ?? '1.0.0';
} catch {}

router.get('/', (_req, res) => {
  res.json({
    status: 'ok',
    version,
    uptime: Math.floor(process.uptime()),
    env: process.env.NODE_ENV ?? 'development',
    db: 'connected',
  });
});

export default router;
