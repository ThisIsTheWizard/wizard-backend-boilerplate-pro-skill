# Auth0 — Reference

**Compatibility:** All frameworks (universal JWKS-based JWT verification)
**Type:** Enterprise managed auth (Okta)
**Homepage:** https://auth0.com
**Free tier:** 7,500 MAU

> **RBAC:** Skip custom Role/Permission/RoleUser/RolePermission tables and their routes.
> Auth0 manages roles and permissions via the Management API and includes them as claims in
> the JWT (`https://your-domain/roles`, `https://your-domain/permissions`). Read those claims
> from the verified token. Also skip: AuthToken, VerificationToken, AuthTemplate, Notification.

## Overview

Auth0 issues JWTs (RS256 signed) that your backend verifies by fetching the
JWKS (JSON Web Key Set) from your Auth0 tenant. No passwords, no sessions —
your backend only verifies tokens. Auth0 handles login UI, MFA, social logins,
and enterprise SSO.

## Required .env additions

```env
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_AUDIENCE=https://your-api-identifier
AUTH0_CLIENT_ID=       # Only needed for Management API calls
AUTH0_CLIENT_SECRET=   # Only needed for Management API calls
```

## Express wiring

```bash
$PM add express-oauth2-jwt-bearer
```

```typescript
import { auth } from 'express-oauth2-jwt-bearer';

const checkJwt = auth({
  audience: process.env.AUTH0_AUDIENCE,
  issuerBaseURL: `https://${process.env.AUTH0_DOMAIN}/`,
});

app.get('/protected', checkJwt, (req, res) => {
  res.json({ sub: (req as any).auth.payload.sub });
});
```

## Fastify wiring

```bash
$PM add jwks-rsa fast-jwt
```

```typescript
import jwksClient from 'jwks-rsa';
import { createVerifier } from 'fast-jwt';

const client = jwksClient({
  jwksUri: `https://${process.env.AUTH0_DOMAIN}/.well-known/jwks.json`,
});

const verifyToken = createVerifier({
  key: async (header) => {
    const key = await client.getSigningKey(header.kid);
    return key.getPublicKey();
  },
  algorithms: ['RS256'],
});

fastify.addHook('preHandler', async (request, reply) => {
  const token = request.headers.authorization?.split(' ')[1];
  if (!token) return reply.code(401).send({ error: 'Missing token' });
  try {
    (request as any).jwtPayload = await verifyToken(token);
  } catch {
    return reply.code(401).send({ error: 'Invalid token' });
  }
});
```

## NestJS wiring

```bash
$PM add @nestjs/passport passport passport-jwt jwks-rsa
```

```typescript
// jwt.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `https://${process.env.AUTH0_DOMAIN}/.well-known/jwks.json`,
      }),
      audience: process.env.AUTH0_AUDIENCE,
      issuer: `https://${process.env.AUTH0_DOMAIN}/`,
      algorithms: ['RS256'],
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
    });
  }

  validate(payload: any) {
    return { userId: payload.sub, ...payload };
  }
}
```

## Hono wiring

```typescript
import { createRemoteJWKSet, jwtVerify } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL(`https://${process.env.AUTH0_DOMAIN}/.well-known/jwks.json`)
);

const auth0Middleware = async (c: Context, next: Next) => {
  const token = c.req.header('Authorization')?.split(' ')[1];
  if (!token) return c.json({ error: 'Unauthorized' }, 401);
  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://${process.env.AUTH0_DOMAIN}/`,
      audience: process.env.AUTH0_AUDIENCE,
    });
    c.set('jwtPayload', payload);
    await next();
  } catch {
    return c.json({ error: 'Invalid token' }, 401);
  }
};
```

## FastAPI wiring

```bash
pip install python-jose[cryptography] httpx
```

```python
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, jwk
import httpx, os

security = HTTPBearer()

async def get_jwks():
    async with httpx.AsyncClient() as client:
        r = await client.get(f"https://{os.environ['AUTH0_DOMAIN']}/.well-known/jwks.json")
        return r.json()

async def require_auth(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    jwks = await get_jwks()
    try:
        payload = jwt.decode(
            token, jwks,
            algorithms=['RS256'],
            audience=os.environ['AUTH0_AUDIENCE'],
            issuer=f"https://{os.environ['AUTH0_DOMAIN']}/"
        )
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))
```

## Django wiring

```bash
pip install djangorestframework python-jose[cryptography]
```

```python
# auth/auth0_backend.py
import os
from jose import jwt
import urllib.request, json

class Auth0JSONWebTokenAuthentication(BaseAuthentication):
    def authenticate(self, request):
        token = request.META.get('HTTP_AUTHORIZATION', '').split('Bearer ')[-1]
        if not token:
            return None
        with urllib.request.urlopen(f"https://{os.environ['AUTH0_DOMAIN']}/.well-known/jwks.json") as r:
            jwks = json.loads(r.read())
        payload = jwt.decode(token, jwks, algorithms=['RS256'],
                             audience=os.environ['AUTH0_AUDIENCE'])
        from django.contrib.auth.models import AnonymousUser
        return (AnonymousUser(), payload)
```

## Flask wiring

```bash
pip install python-jose[cryptography]
```

```python
from functools import wraps
from flask import request, jsonify, g
from jose import jwt
import urllib.request, json, os

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').split('Bearer ')[-1]
        with urllib.request.urlopen(f"https://{os.environ['AUTH0_DOMAIN']}/.well-known/jwks.json") as r:
            jwks = json.loads(r.read())
        try:
            g.jwt_payload = jwt.decode(token, jwks, algorithms=['RS256'],
                                       audience=os.environ['AUTH0_AUDIENCE'])
        except Exception as e:
            return jsonify({"error": str(e)}), 401
        return f(*args, **kwargs)
    return decorated
```

## Gin wiring

```bash
go get github.com/auth0/go-jwt-middleware/v2
go get gopkg.in/square/go-jose.v2
```

```go
import (
    jwtmiddleware "github.com/auth0/go-jwt-middleware/v2"
    "github.com/auth0/go-jwt-middleware/v2/jwks"
    "github.com/auth0/go-jwt-middleware/v2/validator"
)

func Auth0Middleware() gin.HandlerFunc {
    issuerURL, _ := url.Parse("https://" + os.Getenv("AUTH0_DOMAIN") + "/")
    provider := jwks.NewCachingProvider(issuerURL, 5*time.Minute)
    jwtValidator, _ := validator.New(
        provider.KeyFunc,
        validator.RS256,
        issuerURL.String(),
        []string{os.Getenv("AUTH0_AUDIENCE")},
    )
    mw := jwtmiddleware.New(jwtValidator.ValidateToken)
    return func(c *gin.Context) {
        mw.CheckJWT(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            c.Request = r
            c.Next()
        })).ServeHTTP(c.Writer, c.Request)
    }
}
```

## Echo wiring

Same JWKS logic as Gin — adapt `Auth0Middleware()` to return `echo.MiddlewareFunc`
wrapping the `go-jwt-middleware` handler.

## Key notes

- Auth0 uses RS256 (asymmetric) by default — do NOT switch to HS256 for APIs.
- JWKS are cached — set a reasonable TTL (5–15 min) to avoid hitting rate limits.
- For M2M (machine-to-machine) tokens, use the Client Credentials grant.
- For user management from your backend, use the Auth0 Management API (requires separate credentials).
