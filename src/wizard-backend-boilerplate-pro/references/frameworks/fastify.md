# Fastify — Reference

**Language:** Node.js / TypeScript
**Version:** 5.x (use `fastify@latest`)
**Package registry:** https://www.npmjs.com/package/fastify

## Directory structure (after scaffold)

```
<APP_NAME>/
├── src/
│   ├── app.ts              # Fastify app factory (no listen call)
│   ├── server.ts           # Entry point
│   ├── plugins/            # Fastify plugins (cors, helmet, rate-limit, swagger)
│   ├── routes/             # Route handlers per module
│   │   ├── health.ts
│   │   ├── auth/
│   │   ├── users/
│   │   └── files/
│   ├── schemas/            # JSON Schema / Zod schemas
│   ├── services/           # Business logic
│   └── types/
├── prisma/ or drizzle/
├── .env
├── .env.example
├── tsconfig.json
└── package.json
```

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
$PM init -y

$PM add fastify @fastify/cors @fastify/helmet @fastify/rate-limit \
         @fastify/swagger @fastify/swagger-ui @fastify/multipart

$PM add -D typescript @types/node ts-node-dev eslint prettier \
         @typescript-eslint/eslint-plugin @typescript-eslint/parser

npx tsc --init --target es2022 --module commonjs --outDir dist \
        --rootDir src --strict --esModuleInterop --skipLibCheck
```

## package.json scripts

```json
{
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "lint": "eslint src --ext .ts"
  }
}
```

## src/app.ts (factory)

```typescript
import Fastify from 'fastify';

export async function buildApp() {
  const fastify = Fastify({ logger: true });

  await fastify.register(import('@fastify/cors'), { origin: process.env.CORS_ORIGIN ?? true });
  await fastify.register(import('@fastify/helmet'));
  await fastify.register(import('@fastify/rate-limit'), { max: 100, timeWindow: '1 minute' });
  await fastify.register(import('@fastify/swagger'), {
    openapi: {
      info: { title: process.env.APP_NAME ?? 'API', version: '1.0.0' },
      components: { securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer' } } },
    },
  });
  await fastify.register(import('@fastify/swagger-ui'), { routePrefix: '/docs' });

  // Routes registered here by module installer

  return fastify;
}
```

## src/server.ts

```typescript
import { buildApp } from './app';

const PORT = parseInt(process.env.PORT ?? '3000', 10);

buildApp().then((fastify) => {
  fastify.listen({ port: PORT, host: '0.0.0.0' }, (err) => {
    if (err) { fastify.log.error(err); process.exit(1); }
  });
});
```

## Plugin registration pattern

Fastify uses plugins and `fastify-plugin` (fp) for dependency sharing.

```typescript
import fp from 'fastify-plugin';
import type { FastifyPluginAsync } from 'fastify';

const myPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.decorate('myService', { doSomething() {} });
};

export default fp(myPlugin);
```

Wrap with `fp()` when the plugin adds decorators consumed by other plugins.
Don't wrap with `fp()` for route-only plugins (keeps scope isolated).

## Route registration

```typescript
// src/routes/users/index.ts
import type { FastifyPluginAsync } from 'fastify';

const usersRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/', { schema: { response: { 200: usersSchema } } }, async (request, reply) => {
    return { users: [] };
  });
};

export default usersRoute;

// Register in app.ts
await fastify.register(usersRoute, { prefix: '/users' });
```

## JSON Schema validation (built-in)

Fastify validates request and response bodies via JSON Schema automatically
when you provide a `schema` option on the route. Use `@sinclair/typebox` for
TypeScript-friendly schema generation:

```bash
$PM add @sinclair/typebox
```

```typescript
import { Type } from '@sinclair/typebox';

const CreateUserBody = Type.Object({
  email: Type.String({ format: 'email' }),
  password: Type.String({ minLength: 8 }),
});
```

## TypeScript tips

- Fastify has excellent built-in TypeScript support — no `@types/fastify` needed
- Use `FastifyRequest<{ Body: typeof CreateUserBody }>` for typed route handlers
- Decorate fastify instance via `declare module 'fastify'` for custom properties
