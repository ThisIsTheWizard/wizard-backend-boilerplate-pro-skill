# Session + Cookie Authentication — Reference

Stateful server-side sessions. The server stores session data; the client holds a signed cookie containing only the session ID.

## How it works

1. User logs in → server creates session record (in memory, Redis, or DB), sets `Set-Cookie` header
2. Browser sends cookie automatically on every request to the same domain
3. Server middleware reads session ID from cookie, looks up session data
4. On logout, server deletes the session record and clears the cookie

## Required .env additions

```env
SESSION_SECRET=<random-64-char-hex>
SESSION_MAX_AGE=604800    # 7 days in seconds
```

## Session store options

| Store | Package | Best for |
|---|---|---|
| Memory (default) | Built-in | Development only (data lost on restart) |
| Redis | `connect-redis` / `redis` | Production (shared across instances) |
| PostgreSQL | `connect-pg-simple` | Production (persisted, auditable) |

## Node.js session stores

```bash
# Redis store
$PM add connect-redis redis

# PostgreSQL store
$PM add connect-pg-simple
```

```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL });
await redisClient.connect();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production', // HTTPS only in prod
    sameSite: 'lax',
    maxAge: parseInt(process.env.SESSION_MAX_AGE ?? '604800') * 1000,
  },
}));
```

## Auth endpoints

| Method | Path | Notes |
|---|---|---|
| `POST` | `/auth/register` | Hash password, create user, create session |
| `POST` | `/auth/login` | Verify password, set `req.session.userId`, return user |
| `POST` | `/auth/logout` | Destroy session, clear cookie |
| `GET` | `/auth/me` | Read `req.session.userId`, return user |

## Login handler

```typescript
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await db.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  (req.session as any).userId = user.id;
  res.json({ id: user.id, email: user.email });
});

app.post('/auth/logout', (req, res) => {
  req.session.destroy(() => {
    res.clearCookie('connect.sid');
    res.json({ ok: true });
  });
});
```

## Python (Starlette/FastAPI SessionMiddleware)

```python
# app/main.py
from starlette.middleware.sessions import SessionMiddleware
app.add_middleware(
    SessionMiddleware,
    secret_key=os.environ["SESSION_SECRET"],
    https_only=os.getenv("ENV") == "production",
    max_age=int(os.getenv("SESSION_MAX_AGE", 604800)),
)

# Route
@router.post("/login")
async def login(request: Request, body: LoginBody, db: AsyncSession = Depends(get_db)):
    user = await authenticate_user(db, body.email, body.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    request.session["user_id"] = str(user.id)
    return {"id": str(user.id), "email": user.email}

@router.post("/logout")
async def logout(request: Request):
    request.session.clear()
    return {"ok": True}
```

## CSRF protection

Session auth requires CSRF protection when used with browser clients:

```bash
# Node.js
$PM add csurf   # or use SameSite=Strict cookies (modern browsers)
```

With `SameSite=Lax` (default), CSRF is largely mitigated for same-origin requests.
Use `SameSite=Strict` for higher security. Use `Lax` if you need cross-site navigation
to preserve sessions (e.g. link clicks from emails).

## Per-framework implementation

See `assets/auth-provider/<framework>.ts.template` — the `// @if AUTH == session` block.
