# API Key Authentication — Reference

Simple, stateless authentication for service-to-service or developer API access.

## How it works

1. Admin generates an API key for a user/service → returns the raw key once (store it safely)
2. Server stores only the **SHA-256 hash** of the key — never the raw key
3. Client sends the raw key in `X-Api-Key` header on every request
4. Server middleware hashes the incoming key and looks it up in the database

## Required .env additions

No additional env vars needed beyond the database connection.
Optionally add `API_KEY_PREFIX=ak_` to namespace keys.

## Database schema

```sql
CREATE TABLE api_keys (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  hashed_key TEXT UNIQUE NOT NULL,
  name       TEXT,          -- Human label ("Production key", "CI/CD")
  is_active  BOOLEAN DEFAULT TRUE,
  last_used  TIMESTAMP,
  expires_at TIMESTAMP,     -- NULL = never expires
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Auth endpoints

| Method | Path | Auth required | Notes |
|---|---|---|---|
| `POST` | `/auth/keys` | Yes (existing auth) | Generate + return raw key once |
| `GET` | `/auth/keys` | Yes | List user's keys (hashed, never raw) |
| `DELETE` | `/auth/keys/:id` | Yes | Revoke a key |

## Key generation

```typescript
// Node.js
import crypto from 'crypto';
const raw = `ak_${crypto.randomBytes(24).toString('hex')}`; // "ak_" + 48 hex chars
const hashed = crypto.createHash('sha256').update(raw).digest('hex');
// Store hashed, return raw to user exactly once

# Python
import hashlib, secrets
raw = f"ak_{secrets.token_hex(24)}"
hashed = hashlib.sha256(raw.encode()).hexdigest()

// Go
b := make([]byte, 24)
rand.Read(b)
raw := "ak_" + hex.EncodeToString(b)
sum := sha256.Sum256([]byte(raw))
hashed := hex.EncodeToString(sum[:])
```

## Middleware lookup

```typescript
// Fast lookup — index on hashed_key column
const hashed = crypto.createHash('sha256').update(rawKey).digest('hex');
const apiKey = await db.apiKey.findUnique({
  where: { hashedKey: hashed, isActive: true },
  include: { user: true },
});
if (!apiKey) throw new UnauthorizedException('Invalid API key');

// Optionally update last_used
await db.apiKey.update({ where: { id: apiKey.id }, data: { lastUsed: new Date() } });
```

## Security notes

- Always SHA-256 hash keys before storing — no salting needed (keys are already random)
- Return the raw key **exactly once** at creation — it cannot be recovered later
- Index `hashed_key` for fast lookups
- Support key expiry (`expires_at`) and revocation (`is_active = false`)
- Rate-limit the key lookup endpoint and log excessive failures

## Per-framework implementation

See `assets/auth-provider/<framework>.ts.template` — the `// @if AUTH == apikey` block.
