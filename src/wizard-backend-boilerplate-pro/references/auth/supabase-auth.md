# Supabase Auth — Reference

**Compatibility:** Express, Fastify, NestJS, Hono (Node.js); FastAPI, Flask (Python)
**Type:** Open-source managed auth (PostgreSQL-based)
**Homepage:** https://supabase.com/docs/guides/auth
**Free tier:** 50,000 MAU

> **RBAC:** Skip custom Role/Permission/RoleUser/RolePermission tables and their routes.
> Supabase uses Row-Level Security (RLS) policies on the database for authorization, and
> custom claims in `app_metadata` for roles. Add roles via `supabase.auth.admin.updateUserById()`
> and read them from the JWT in your middleware. Also skip: AuthToken, VerificationToken,
> AuthTemplate, Notification — Supabase Auth handles sessions and emails.

## Overview

Supabase Auth is built on top of GoTrue (an open-source auth server). It issues
JWTs signed with your project's JWT secret. Your backend verifies these tokens
using the shared secret. User data is stored in Supabase's PostgreSQL — you can
query it directly with Row Level Security (RLS).

## Required .env additions

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJ...         # Public (safe to expose to clients)
SUPABASE_SERVICE_ROLE_KEY=eyJ... # Private (never expose — full DB access)
SUPABASE_JWT_SECRET=your-jwt-secret  # Found in Supabase Dashboard → Settings → API
```

## Node.js install

```bash
$PM add @supabase/supabase-js
```

## Python install

```bash
pip install supabase
```

## Express wiring

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // Service role for server-side calls
);

// Auth middleware — verifies Bearer token from client
async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: 'Missing token' });

  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ error: 'Invalid token' });

  (req as any).user = user;
  next();
}

app.get('/profile', requireAuth, (req, res) => {
  res.json((req as any).user);
});
```

## Fastify wiring

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

fastify.addHook('preHandler', async (request, reply) => {
  const token = request.headers.authorization?.split('Bearer ')[1];
  if (!token) return;
  const { data: { user } } = await supabase.auth.getUser(token);
  (request as any).user = user;
});

const requireAuth = async (request: FastifyRequest, reply: FastifyReply) => {
  if (!(request as any).user) reply.code(401).send({ error: 'Unauthorized' });
};
```

## Hono wiring

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

const supabaseAuth = async (c: Context, next: Next) => {
  const token = c.req.header('Authorization')?.split('Bearer ')[1];
  if (!token) return c.json({ error: 'Unauthorized' }, 401);
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return c.json({ error: 'Invalid token' }, 401);
  c.set('user', user);
  await next();
};
```

## NestJS wiring

```typescript
// supabase.guard.ts
import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.split('Bearer ')[1];
    if (!token) throw new UnauthorizedException();
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) throw new UnauthorizedException();
    request.user = user;
    return true;
  }
}
```

## FastAPI wiring

```python
from supabase import create_client, Client
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import os

supabase: Client = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
security = HTTPBearer()

async def require_auth(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    response = supabase.auth.get_user(token)
    if not response.user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return response.user

@router.get("/profile")
async def profile(user=Depends(require_auth)):
    return {"id": user.id, "email": user.email}
```

## Flask wiring

```python
from supabase import create_client
from functools import wraps
from flask import request, jsonify, g
import os

supabase = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization", "").split("Bearer ")[-1]
        if not token:
            return jsonify({"error": "Unauthorized"}), 401
        response = supabase.auth.get_user(token)
        if not response.user:
            return jsonify({"error": "Invalid token"}), 401
        g.user = response.user
        return f(*args, **kwargs)
    return decorated
```

## Row Level Security (RLS)

Supabase's RLS lets PostgreSQL enforce auth rules at the DB level. Create an
authenticated client using the user's JWT (not the service role key) so that
RLS policies apply:

```typescript
// Per-request client with user context
const userClient = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  { global: { headers: { Authorization: `Bearer ${userToken}` } } }
);
const { data } = await userClient.from('posts').select('*');
// Only returns rows the user is allowed to see via RLS
```

## Key notes

- Use `SUPABASE_SERVICE_ROLE_KEY` on the server side only — it bypasses RLS.
- Use `SUPABASE_ANON_KEY` on the client side — it respects RLS.
- For offline JWT verification (no network call), use `SUPABASE_JWT_SECRET` with `jsonwebtoken`.
- Supabase Auth supports email/password, magic links, OAuth, phone OTP.
