# JWT (Custom) — Reference

Custom stateless authentication using JSON Web Tokens. No external service.

## How it works

1. User registers/logs in → server signs an **access token** (15 min) + **refresh token** (7 days)
2. Client stores both tokens; sends access token in `Authorization: Bearer <token>` header
3. Server middleware verifies the access token on protected routes
4. When the access token expires, client posts the refresh token to `/auth/refresh` to get a new pair

## Required .env additions

```env
JWT_SECRET=<random-64-char-hex>
JWT_EXPIRES_MINUTES=15
JWT_REFRESH_EXPIRES_DAYS=7
```

Generate secret:
```bash
# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# Python
python -c "import secrets; print(secrets.token_hex(32))"
# Go
openssl rand -hex 32
```

## Auth endpoints

| Method | Path | Body | Notes |
|---|---|---|---|
| `POST` | `/auth/register` | `{ email, password }` | Hash password, create user, return tokens |
| `POST` | `/auth/login` | `{ email, password }` | Verify password, return tokens |
| `POST` | `/auth/refresh` | `{ refreshToken }` | Verify refresh token, return new access token |
| `GET` | `/auth/me` | — | Protected — return current user from token |
| `POST` | `/auth/logout` | — | Client deletes tokens locally (or revoke refresh token in DB) |

## Password hashing

Always hash passwords with bcrypt (cost 12) before storing. Never store plain text.

```typescript
// Node.js
import bcrypt from 'bcryptjs'; // $PM add bcryptjs @types/bcryptjs
const hashed = await bcrypt.hash(password, 12);
const match = await bcrypt.compare(plain, hashed);

# Python
from passlib.context import CryptContext  # pip install passlib[bcrypt]
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
hashed = pwd_ctx.hash(password)
match = pwd_ctx.verify(plain, hashed)

// Go
import "golang.org/x/crypto/bcrypt"  // go get golang.org/x/crypto
hashed, _ := bcrypt.GenerateFromPassword([]byte(password), 12)
err := bcrypt.CompareHashAndPassword(hashed, []byte(plain))
```

## Refresh token rotation (best practice)

Issue a **new** refresh token on every `/auth/refresh` call and invalidate the old one.
This limits the damage from token theft.

Implementation:
1. Store refresh tokens in DB (table: `refresh_tokens { token_hash, user_id, expires_at, used }`)
2. On `/auth/refresh`:
   - Verify token signature
   - Look up token hash in DB — reject if not found or `used = true`
   - Mark old token as `used = true`
   - Create new refresh token, store its hash
   - Return new access + refresh token pair

## Per-framework implementation

See `assets/auth-provider/<framework>.ts.template` — the `// @if AUTH == jwt` block.

## Access token payload

Keep payloads small — only store what you need for authorization decisions:

```json
{
  "sub": "user-id",
  "exp": 1234567890,
  "iat": 1234567800
}
```

Do not store passwords, sensitive PII, or mutable data in the token payload.
