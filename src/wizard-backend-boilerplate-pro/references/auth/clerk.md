# Clerk — Reference

**Compatibility:** Express, Fastify, NestJS, Hono (Node.js); FastAPI, Django, Flask (Python)
**Type:** Fully managed auth service
**Homepage:** https://clerk.com
**Free tier:** 10,000 MAU

> **RBAC:** Skip custom Role/Permission/RoleUser/RolePermission tables and their routes.
> Clerk manages roles and permissions in its dashboard — use `auth().has({ permission })` or
> `auth().has({ role })` server-side. Also skip: AuthToken, VerificationToken, AuthTemplate,
> Notification — Clerk handles sessions and transactional emails.

## Overview

Clerk handles the entire auth surface: sign-up/sign-in UI (hosted), session management,
JWT verification, OAuth, MFA, and user management. Your backend only needs to verify
Clerk-issued session tokens — no password hashing, no token storage.

## Required .env additions

```env
CLERK_SECRET_KEY=sk_test_...
CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_JWT_KEY=   # Optional: for offline JWT verification (no network call)
```

Get keys from: Clerk Dashboard → API Keys.

## Node.js install

```bash
# Express / Fastify / NestJS / Hono
$PM add @clerk/express    # Works for Express and Hono
# OR
$PM add @clerk/backend    # Framework-agnostic SDK
```

## Python install

```bash
pip install clerk-backend-api
```

## Express wiring

```typescript
import { clerkMiddleware, requireAuth, getAuth } from '@clerk/express';

app.use(clerkMiddleware());

// Protect a route
app.get('/profile', requireAuth(), (req, res) => {
  const { userId } = getAuth(req);
  res.json({ userId });
});
```

## Fastify wiring

```typescript
import { clerkPlugin, getAuth } from '@clerk/fastify';

await fastify.register(clerkPlugin);

fastify.get('/profile', {
  preHandler: fastify.clerkAuth(),
}, async (request, reply) => {
  const { userId } = getAuth(request);
  return { userId };
});
```

## Hono wiring

```typescript
import { clerkMiddleware, getAuth } from '@hono/clerk-auth';

app.use('*', clerkMiddleware());

app.get('/profile', (c) => {
  const auth = getAuth(c);
  if (!auth?.userId) return c.json({ error: 'Unauthorized' }, 401);
  return c.json({ userId: auth.userId });
});
```

## NestJS wiring

```typescript
// app.module.ts
import { ClerkClientProvider } from '@clerk/nestjs';

@Module({
  imports: [ClerkClientProvider],
})
export class AppModule {}

// guard: clerk-auth.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { clerkClient } from '@clerk/nestjs';

@Injectable()
export class ClerkAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.split(' ')[1];
    if (!token) return false;
    try {
      await clerkClient.verifyToken(token);
      return true;
    } catch {
      return false;
    }
  }
}
```

## FastAPI wiring

```python
from clerk_backend_api import Clerk
from clerk_backend_api.jwks_helpers import authenticate_request, AuthenticateRequestOptions
import os

clerk = Clerk(bearer_auth=os.environ["CLERK_SECRET_KEY"])

async def require_auth(request: Request) -> dict:
    request_state = authenticate_request(
        request,
        AuthenticateRequestOptions(authorized_parties=[os.environ["CLERK_PUBLISHABLE_KEY"]])
    )
    if not request_state.is_signed_in:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return request_state.payload

# Usage in route
@router.get("/profile")
async def profile(payload: dict = Depends(require_auth)):
    return {"userId": payload["sub"]}
```

## Flask wiring

```python
from clerk_backend_api import Clerk
from clerk_backend_api.jwks_helpers import authenticate_request, AuthenticateRequestOptions
from functools import wraps
import os

clerk = Clerk(bearer_auth=os.environ["CLERK_SECRET_KEY"])

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        from flask import request, jsonify, g
        state = authenticate_request(
            request,
            AuthenticateRequestOptions(authorized_parties=[os.environ["CLERK_PUBLISHABLE_KEY"]])
        )
        if not state.is_signed_in:
            return jsonify({"error": "Unauthorized"}), 401
        g.clerk_payload = state.payload
        return f(*args, **kwargs)
    return decorated
```

## Webhook verification

Clerk sends signed webhooks for user events. Verify them with `svix`:

```typescript
import { Webhook } from 'svix';

app.post('/webhooks/clerk', express.raw({ type: 'application/json' }), (req, res) => {
  const wh = new Webhook(process.env.CLERK_WEBHOOK_SECRET!);
  const payload = wh.verify(req.body, {
    'svix-id': req.headers['svix-id'] as string,
    'svix-timestamp': req.headers['svix-timestamp'] as string,
    'svix-signature': req.headers['svix-signature'] as string,
  });
  // payload.type: 'user.created' | 'user.updated' | 'user.deleted'
  res.json({ received: true });
});
```

## Key notes

- Clerk hosts its own sign-in/sign-up UI — you do not need to build auth pages.
- User data (email, name, avatar) is stored in Clerk, not in your database.
- If you need user data in your DB, sync it via Clerk webhooks (`user.created`, `user.updated`).
- For local development, use the Clerk test keys from the dashboard.
