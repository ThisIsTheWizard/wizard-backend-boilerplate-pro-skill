# better-auth — Reference

**Compatibility:** Express, Fastify, NestJS, Hono (Node.js only)
**Type:** Self-hosted TypeScript auth library
**Homepage:** https://better-auth.com

> **RBAC:** Skip the custom Role/Permission/RoleUser/RolePermission tables and routes.
> Use better-auth's access-control plugin (`@better-auth/plugins` → `ac`) instead.
> Also skip: AuthToken, VerificationToken, AuthTemplate, Notification modules — better-auth manages sessions and emails internally.

## Overview

better-auth is a TypeScript-first, self-hosted authentication library. It handles
email/password, OAuth (Google, GitHub, Discord, etc.), magic links, two-factor auth,
and session management. It integrates with Prisma, Drizzle, and other ORMs.

## Install

```bash
# npm / pnpm / bun / yarn
$PM add better-auth
```

## Required .env additions

```env
BETTER_AUTH_SECRET=<generated-random-32-char-string>
BETTER_AUTH_URL=http://localhost:${PORT}

# OAuth providers (add only the ones you need)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
```

Generate secret:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Core setup file

Create `src/lib/auth.ts`:

```typescript
import { betterAuth } from 'better-auth';
import { prismaAdapter } from 'better-auth/adapters/prisma'; // or drizzleAdapter
import { db } from './db';

export const auth = betterAuth({
  database: prismaAdapter(db, { provider: 'postgresql' }),
  emailAndPassword: { enabled: true },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
    github: {
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    },
  },
});

export type Session = typeof auth.$Infer.Session;
```

## Express wiring

```typescript
import { toNodeHandler } from 'better-auth/node';
import { auth } from './lib/auth';

// Mount all better-auth routes under /api/auth/*
app.all('/api/auth/*', toNodeHandler(auth));

// Middleware to attach session to req
app.use(async (req, res, next) => {
  const session = await auth.api.getSession({ headers: req.headers as any });
  (req as any).session = session;
  next();
});
```

## Fastify wiring

```typescript
import { toNodeHandler } from 'better-auth/node';
import { auth } from './lib/auth';

fastify.all('/api/auth/*', async (request, reply) => {
  const handler = toNodeHandler(auth);
  return new Promise((resolve) => {
    handler(request.raw, reply.raw, resolve);
  });
});

fastify.addHook('preHandler', async (request) => {
  const session = await auth.api.getSession({ headers: request.headers as any });
  (request as any).session = session;
});
```

## Hono wiring

```typescript
import { betterAuth } from 'better-auth';
import { auth } from './lib/auth';

app.on(['POST', 'GET'], '/api/auth/*', (c) => auth.handler(c.req.raw));

app.use('*', async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  c.set('session', session);
  await next();
});
```

## NestJS wiring

Create `src/auth/auth.module.ts`:

```typescript
import { Module, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { BetterAuthMiddleware } from './better-auth.middleware';

@Module({})
export class AuthModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(BetterAuthMiddleware)
      .forRoutes({ path: '/api/auth/*', method: RequestMethod.ALL });
  }
}
```

`src/auth/better-auth.middleware.ts`:

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { toNodeHandler } from 'better-auth/node';
import { auth } from '../lib/auth';

const handler = toNodeHandler(auth);

@Injectable()
export class BetterAuthMiddleware implements NestMiddleware {
  use(req: any, res: any, next: () => void) {
    handler(req, res, next);
  }
}
```

## Protect a route

```typescript
// Express middleware
function requireAuth(req: Request, res: Response, next: NextFunction) {
  if (!(req as any).session?.user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.get('/profile', requireAuth, (req, res) => {
  res.json((req as any).session.user);
});
```

## Database schema (Prisma)

Run `npx @better-auth/cli generate` to add the required tables to `schema.prisma`, then:

```bash
npx prisma migrate dev --name add-better-auth
```

## Built-in routes (auto-registered)

| Route | Action |
|---|---|
| `POST /api/auth/sign-in/email` | Email + password login |
| `POST /api/auth/sign-up/email` | Email + password register |
| `POST /api/auth/sign-out` | Sign out (clears session) |
| `GET /api/auth/session` | Get current session |
| `GET /api/auth/callback/:provider` | OAuth callback |
| `GET /api/auth/sign-in/:provider` | OAuth redirect |
