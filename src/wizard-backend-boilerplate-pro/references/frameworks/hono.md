# Hono — Reference

**Language:** Node.js / TypeScript (also Deno, Bun, Cloudflare Workers, etc.)
**Version:** 4.x (use `hono@latest`)
**Package registry:** https://www.npmjs.com/package/hono

## Directory structure (after scaffold)

```
<APP_NAME>/
├── src/
│   ├── index.ts            # Entry point + server listen (Node.js adapter)
│   ├── app.ts              # Hono app factory
│   ├── routes/             # Route handlers per module
│   │   ├── health.ts
│   │   ├── auth.ts
│   │   ├── users.ts
│   │   └── files.ts
│   ├── middleware/         # Custom middleware
│   ├── lib/                # Shared utilities (db client, auth, etc.)
│   └── types/              # Shared TypeScript types
├── prisma/ or drizzle/
├── .env
├── tsconfig.json
└── package.json
```

## Init commands

```bash
# Use the official starter
$PM create hono@latest "$APP_NAME" -- --template nodejs
cd "$APP_NAME"

# Additional dependencies
$PM add zod @hono/zod-validator @hono/swagger-ui hono-rate-limiter
```

## package.json scripts

```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src --ext .ts"
  }
}
```

Add `tsx`:
```bash
$PM add -D tsx @types/node
```

## src/app.ts (factory)

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';
import { rateLimiter } from 'hono-rate-limiter';

export function createApp() {
  const app = new Hono();

  app.use('*', logger());
  app.use('*', secureHeaders());
  app.use('*', cors({ origin: process.env.CORS_ORIGIN ?? '*' }));
  app.use('*', rateLimiter({
    windowMs: 60 * 1000,
    limit: 100,
    keyGenerator: (c) => c.req.header('x-forwarded-for') ?? 'local',
  }));

  // Routes registered here by module installer

  return app;
}
```

## src/index.ts (Node.js adapter)

```typescript
import { serve } from '@hono/node-server';
import { createApp } from './app';

const PORT = parseInt(process.env.PORT ?? '3000', 10);
const app = createApp();

serve({ fetch: app.fetch, port: PORT }, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
  console.log(`Swagger UI: http://localhost:${PORT}/docs`);
});
```

## Route registration pattern

```typescript
// src/routes/users.ts
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const users = new Hono();

users.get('/', async (c) => {
  return c.json({ users: [] });
});

users.post('/',
  zValidator('json', z.object({ email: z.string().email(), password: z.string().min(8) })),
  async (c) => {
    const body = c.req.valid('json');
    return c.json({ created: true }, 201);
  }
);

export default users;

// In app.ts:
// import usersRoute from './routes/users';
// app.route('/users', usersRoute);
```

## Swagger UI setup

```typescript
import { swaggerUI } from '@hono/swagger-ui';
import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';

// Replace Hono with OpenAPIHono for auto-generated spec
const app = new OpenAPIHono();

app.doc('/docs/json', {
  openapi: '3.0.0',
  info: { title: process.env.APP_NAME ?? 'API', version: '1.0.0' },
});
app.get('/docs', swaggerUI({ url: '/docs/json' }));
```

## Context variable access pattern

```typescript
// Declare typed variables
const app = new Hono<{ Variables: { userId: string } }>();

// Set in middleware
app.use('*', async (c, next) => {
  c.set('userId', 'user-123');
  await next();
});

// Read in route
app.get('/me', (c) => {
  const userId = c.get('userId');
  return c.json({ userId });
});
```

## Edge deployment targets

Hono runs on Node.js, Bun, Deno, Cloudflare Workers, and AWS Lambda with no
code changes — only the entry point adapter differs. The app factory pattern
in `app.ts` keeps it adapter-agnostic.

## TypeScript tips

- Use `@hono/zod-openapi` instead of plain `Hono` for auto-generated OpenAPI docs
- `c.req.valid('json')` returns a typed object when using `zValidator`
- `c.var` is a shorthand for `c.get()` / `c.set()` when typed
