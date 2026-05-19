# workflow.md — Detailed Playbook

Verbatim commands for every step of the seven-phase scaffold. Load this file
when you need the exact shell syntax for a given framework or phase. For the
high-level flow, see `SKILL.md`. For framework-specific detail beyond what is
shown here, see `references/frameworks/<choice>.md`.

---

## Table of contents

1. [Phase 1 — Interview](#phase-1--interview)
2. [Phase 2 — Auto-resolve](#phase-2--auto-resolve)
3. [Phase 3 — Scaffold](#phase-3--scaffold)
4. [Phase 4 — Configuration](#phase-4--configuration)
5. [Phase 5 — Module installation](#phase-5--module-installation)
6. [Phase 6 — Showcase routes](#phase-6--showcase-routes)
7. [Phase 7 — Verify](#phase-7--verify)
8. [Failure protocols](#failure-protocols)

---

## Phase 1 — Interview

Collect all **seven answers** before running any commands. Never start Phase 2 early.

### Banner

Display this before asking Q1:

```
╔══════════════════════════════════════════════════════════════════╗
║  🧙  Wizard Backend Boilerplate Pro                             ║
║  Answer 7 questions. Get a production-ready API in minutes.     ║
╚══════════════════════════════════════════════════════════════════╝
```

### Presets

If the user's request includes a **preset keyword**, pre-fill the answers below and skip those questions (only ask the ones still open):

| Preset | FRAMEWORK | DB | AUTH | RBAC | GRAPHQL | DOCKER |
|---|---|---|---|---|---|---|
| `starter` | express | sqlite | jwt | no | no | no |
| `saas` | express | postgres | jwt | yes | no | yes |
| `edge` | hono | postgres | clerk | no | no | no |

Example: "Create a saas backend called order-service" → pre-fills everything except APP_NAME; only ask Q5.

### Questions

```
🧙 Choosing your weapon — which framework?
     1) Express       (Node.js / JavaScript)
     2) Fastify       (Node.js / TypeScript)
     3) NestJS        (Node.js / TypeScript)
     4) Hono          (Node.js / TypeScript)
     5) FastAPI       (Python)
     6) Django + DRF  (Python)
     7) Flask         (Python)
     8) Gin           (Go)
     9) Echo          (Go)

🧙 Summoning your data layer — database + ORM?
     First pick a database:
       1) PostgreSQL
       2) MySQL
       3) MongoDB
       4) SQLite
       5) None

     Then confirm (or override) the ORM. Defaults by framework:
       Framework      | Postgres/MySQL/SQLite | MongoDB
       ───────────────|──────────────────────|────────
       Express        | Sequelize            | Mongoose
       Fastify/NestJS | Prisma               | Mongoose
       Hono           | Drizzle              | Mongoose
       FastAPI/Flask  | SQLAlchemy           | Motor
       Django         | Django ORM           | MongoEngine
       Gin/Echo       | GORM                 | mongo-driver

     Present: "I'll use [ORM] for [DB]. Accept, or name a different ORM?"
     Accept override silently if the user names a compatible ORM.

🧙 Securing your kingdom — auth strategy?
     1) JWT           (default — stateless, access + refresh tokens)
     2) API Key       (simple service-to-service auth)
     3) Session       (cookie-based, stateful)
     4) better-auth   (library-based, self-hosted)
     5) Clerk         (fully managed)
     6) Auth0         (enterprise managed)
     7) Supabase      (PostgreSQL-based)
     8) None          (no auth, all routes public)

🧙 Naming your creation — project name?
     (no default — required)

🧙 Building your fortress — include Docker?
     (Dockerfile.Dev/Prod/Test + docker-compose.dev/prod/test.yml)
     yes / no

🧙 Adding arcane power — GraphQL alongside REST?
     yes / no
     (If yes: Apollo/Mercurius/Strawberry/gqlgen per framework; POST /graphql added.
      Blog CRUD is served as GraphQL queries/mutations — REST /blog/posts routes are skipped.)

🧙 Granting access by role — include RBAC?
     yes / no
     (Only asked when AUTH = jwt | apikey | session. Providers manage roles internally.)
```

Store answers as:
- `FRAMEWORK` — e.g. `express`, `fastapi`, `gin`
- `DB` — e.g. `postgres`, `mysql`, `mongodb`, `sqlite`, `none`
- `ORM` — e.g. `sequelize`, `prisma`, `drizzle`, `sqlalchemy`, `gorm`, `mongoose`, `none`
- `AUTH` — e.g. `jwt`, `apikey`, `session`, `better-auth`, `clerk`, `auth0`, `supabase`, `none`
- `DOCKER` — `yes` or `no`
- `APP_NAME` — e.g. `my-api`
- `GRAPHQL` — `yes` or `no`
- `RBAC` — `yes` or `no` (always `no` when AUTH is a provider)

---

## Phase 2 — Auto-resolve

### Detect package manager (Node.js only)

```bash
bash scripts/detect_package_manager.sh
# Prints: bun | pnpm | yarn | npm
# Store as PM
```

### Query latest versions

```bash
# Node.js ecosystem
bash scripts/check_versions.sh --json --ecosystem node

# Python ecosystem
bash scripts/check_versions.sh --json --ecosystem python

# Go ecosystem
bash scripts/check_versions.sh --json --ecosystem go
```

### ORM/ODM resolution table (auto-resolved in Phase 1 Q2)

| FRAMEWORK | DB = postgres / mysql / sqlite | DB = mongodb |
|---|---|---|
| express | **sequelize** | mongoose |
| fastify | prisma | mongoose |
| nestjs | prisma | mongoose |
| hono | drizzle | mongoose |
| fastapi | sqlalchemy | motor |
| django | django-orm | mongoengine |
| flask | sqlalchemy | flask-pymongo |
| gin | gorm | mongo-driver |
| echo | gorm | mongo-driver |

If `DB = none`, set `ORM = none`.

---

## Phase 3 — Scaffold

See `references/frameworks/<FRAMEWORK>.md` for the full scaffold procedure.
Quick-reference commands:

### Express (JavaScript — no TypeScript)
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
$PM init -y
$PM add express cors helmet morgan express-rate-limit dotenv
$PM add -D nodemon eslint prettier

# Add ESM + path aliases to package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
pkg.type = 'module';
pkg.main = 'src/server.js';
pkg.scripts = {
  ...pkg.scripts,
  start: 'node src/server.js',
  dev: 'nodemon src/server.js',
  lint: 'eslint src'
};
pkg.imports = {
  '#core/*':          './src/core/*.js',
  '#auth/*':          './src/auth/*.js',
  '#data/*':          './src/data/*.js',
  '#docs/*':          './src/docs/*.js',
  '#lib/*':           './src/lib/*.js',
  '#db/*':            './src/db/*.js',
  '#modules/*':       './src/modules/*.js',
  '#graphql/*':       './src/graphql/*.js',
  '#notifications/*': './src/notifications/*.js'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"
```

### Fastify
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
$PM init -y
$PM add fastify @fastify/cors @fastify/helmet @fastify/rate-limit @fastify/swagger @fastify/swagger-ui
$PM add -D typescript @types/node ts-node nodemon eslint prettier
npx tsc --init
```

### NestJS
```bash
npx @nestjs/cli new "$APP_NAME" --package-manager $PM --language TypeScript
cd "$APP_NAME"
```

### Hono
```bash
$PM create hono@latest "$APP_NAME" -- --template nodejs
cd "$APP_NAME"
```

### FastAPI
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
python -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn[standard] python-dotenv pydantic-settings
pip install ruff mypy
```

### Django
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
python -m venv .venv && source .venv/bin/activate
pip install django djangorestframework django-cors-headers python-dotenv
django-admin startproject config .
```

### Flask
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
python -m venv .venv && source .venv/bin/activate
pip install flask flask-cors flask-restx python-dotenv
```

### Gin
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
go mod init "$APP_NAME"
go get github.com/gin-gonic/gin
go get github.com/gin-contrib/cors github.com/ulule/limiter/v3
```

### Echo
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
go mod init "$APP_NAME"
go get github.com/labstack/echo/v4
go get github.com/labstack/echo/v4/middleware
```

---

## Phase 4 — Configuration

### Environment file

```bash
# Node.js
cp assets/env-templates/node.env.template "$APP_NAME/.env.example"
cp "$APP_NAME/.env.example" "$APP_NAME/.env"
echo ".env" >> "$APP_NAME/.gitignore"

# Python
cp assets/env-templates/python.env.template "$APP_NAME/.env.example"
cp "$APP_NAME/.env.example" "$APP_NAME/.env"

# Go
cp assets/env-templates/go.env.template "$APP_NAME/.env.example"
cp "$APP_NAME/.env.example" "$APP_NAME/.env"
```

Replace placeholders in `.env`:
```bash
sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$APP_NAME/.env"
```

### Database setup (skip if DB = none)

**Node.js + Sequelize (Express):**
```bash
$PM add sequelize sequelize-cli
# PostgreSQL: $PM add pg pg-hstore
# MySQL:      $PM add mysql2
# SQLite:     $PM add sqlite3
# MongoDB:    $PM add mongoose  (Sequelize not used for MongoDB)
npx sequelize-cli init
```

**Node.js + Prisma (Fastify / NestJS):**
```bash
$PM add prisma @prisma/client
npx prisma init --datasource-provider "$(
  [ "$DB" = "mongodb" ] && echo mongodb ||
  [ "$DB" = "mysql" ]   && echo mysql   ||
  [ "$DB" = "sqlite" ]  && echo sqlite  ||
  echo postgresql
)"
```

**Node.js + Drizzle (Hono):**
```bash
$PM add drizzle-orm
$PM add -D drizzle-kit
```

**Python + SQLAlchemy:**
```bash
pip install sqlalchemy[asyncio] alembic
# PostgreSQL: pip install asyncpg
# MySQL:      pip install aiomysql
# SQLite:     pip install aiosqlite
```

**Go + GORM:**
```bash
go get gorm.io/gorm
# PostgreSQL: go get gorm.io/driver/postgres
# MySQL:      go get gorm.io/driver/mysql
# SQLite:     go get gorm.io/driver/sqlite
```

### Docker setup (skip if DOCKER = no)

```bash
ECOSYSTEM=$(
  ([ "$FRAMEWORK" = "fastapi" ] || [ "$FRAMEWORK" = "django" ] || [ "$FRAMEWORK" = "flask" ]) && echo python ||
  ([ "$FRAMEWORK" = "gin"    ] || [ "$FRAMEWORK" = "echo"   ]) && echo go ||
  echo node
)

if [ "$ECOSYSTEM" = "node" ]; then
  cp "assets/docker-templates/node.dockerfile.dev.template"  "$APP_NAME/Dockerfile.Dev"
  cp "assets/docker-templates/node.dockerfile.prod.template" "$APP_NAME/Dockerfile.Prod"
  cp "assets/docker-templates/node.dockerfile.test.template" "$APP_NAME/Dockerfile.Test"
else
  cp "assets/docker-templates/${ECOSYSTEM}.dockerfile.template" "$APP_NAME/Dockerfile"
fi

cp assets/docker-templates/docker-compose.dev.yml.template  "$APP_NAME/docker-compose.dev.yml"
cp assets/docker-templates/docker-compose.prod.yml.template "$APP_NAME/docker-compose.prod.yml"
cp assets/docker-templates/docker-compose.test.yml.template "$APP_NAME/docker-compose.test.yml"

# Replace {{APP_NAME}} placeholder in all Docker files
for f in "$APP_NAME/Dockerfile.Dev" "$APP_NAME/Dockerfile.Prod" "$APP_NAME/Dockerfile.Test" \
         "$APP_NAME/docker-compose.dev.yml" "$APP_NAME/docker-compose.prod.yml" "$APP_NAME/docker-compose.test.yml"; do
  [ -f "$f" ] && sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$f"
done
```

> **Credentials:** Docker Compose reads `DB_USER` and `DB_PASSWORD` from `.env`.
> Add these to `.env` — do not hardcode them in compose files.

---

## Phase 5 — Module installation

For each module, copy the template file and replace `{{PLACEHOLDER}}` tokens:

```bash
TEMPLATE_DIR="assets/api-templates/$FRAMEWORK"

replace_placeholders() {
  local file="$1"
  sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$file"
  sed -i "s/{{ORM}}/$ORM/g"           "$file"
  sed -i "s/{{DB}}/$DB/g"             "$file"
  sed -i "s/{{AUTH}}/$AUTH/g"         "$file"
  sed -i "s/{{FRAMEWORK}}/$FRAMEWORK/g" "$file"
}
```

Install modules in dependency order (see SKILL.md Phase 5 for the full order).

Wire each module:

**Express example** — register route in `src/app.js` using `#` path aliases:
```javascript
import healthRouter from '#core/health.js';
import authRouter   from '#auth/router.js';
import usersRouter  from '#data/users.js';
import { setupSwagger } from '#docs/swagger.js';

app.use('/health', healthRouter);
app.use('/auth',   authRouter);
app.use('/users',  usersRouter);
setupSwagger(app);
```

> **Blog routing:** When `GRAPHQL = no`, wire `import blogRouter from '#data/blog.js'` and `app.use('/blog/posts', blogRouter)`.
> When `GRAPHQL = yes`, skip the REST blog router — blog CRUD is served via `assets/api-templates/express/graphql/blog.resolvers.js.template` merged into the GraphQL schema.

> **RBAC routes** (`/roles`, `/permissions`, `/role-users`, `/role-permissions`): Only wire when `RBAC = yes`.

> **Notification module:** Uses `assets/api-templates/express/notifications/notification.service.js.template` — a console-log stub. Wire as `import { sendNotification } from '#notifications/notification.service.js'`.

**FastAPI example** — include routers in `app/main.py`:
```python
from app.core.health import router as health_router
from app.auth.router  import router as auth_router
from app.data.users   import router as users_router

app.include_router(health_router)
app.include_router(auth_router, prefix="/auth")
app.include_router(users_router, prefix="/users")
```

**Gin example** — register in `internal/router/router.go`:
```go
v1 := r.Group("/")
health.RegisterRoutes(v1)

auth := r.Group("/auth")
authHandler.RegisterRoutes(auth)

users := r.Group("/users")
users.Use(middleware.JwtAuth())
usersHandler.RegisterRoutes(users)
```

---

## Phase 6 — Showcase routes

After all modules are installed, verify the full route table is registered.
Print the route map to confirm:

```bash
# Node.js (express-list-endpoints or similar)
node --input-type=module <<'EOF'
import { createApp } from './src/app.js';
import listEndpoints from 'express-list-endpoints';
listEndpoints(createApp()).forEach(r => console.log(r.methods.join(','), r.path));
EOF

# FastAPI — route list is visible in /docs (auto-generated)

# Go — Gin prints routes at startup with GIN_MODE=debug
GIN_MODE=debug go run ./cmd/server
```

Confirm these paths are present:
- `GET /health`
- `POST /users/register`, `POST /users/login`, `POST /users/refresh-token`, `GET /users/me`
- `GET /users`, `GET /users/:id`, `PUT /users/:id`
- `GET /blog/posts`, `POST /blog/posts`, etc. — **only when `GRAPHQL = no`**
- `POST /files/upload`, `GET /files/:id`
- `POST /webhooks/:provider`
- `GET /docs`
- `WS /ws`, `GET /events`
- `POST /graphql`, `GET /graphql` — **only when `GRAPHQL = yes`**
- `/roles`, `/permissions`, `/role-users`, `/role-permissions` — **only when `RBAC = yes`**

---

## Phase 7 — Verify

### Install and check

```bash
# Express (JavaScript — no TypeScript compilation)
$PM install
$PM run lint         # eslint src

# Fastify / Hono / NestJS (TypeScript)
$PM install
$PM run build        # tsc --noEmit
$PM run lint         # eslint src

# Python
pip install -r requirements.txt
mypy app --ignore-missing-imports
ruff check .

# Go
go mod tidy
go vet ./...
```

### Start dev server

```bash
# Express (JavaScript)
$PM run dev          # nodemon src/server.js

# Fastify / Hono
$PM run dev          # ts-node-dev / tsx

# NestJS
$PM run start:dev

# FastAPI
uvicorn app.main:app --reload --port 8000

# Django
python manage.py runserver 8000

# Flask
flask run --port 8000

# Gin / Echo
go run ./cmd/server/main.go
```

### Smoke-test all routes

```bash
BASE_URL="http://localhost:$(
  ([ "$FRAMEWORK" = "gin" ] || [ "$FRAMEWORK" = "echo" ]) && echo 8080 ||
  ([ "$FRAMEWORK" = "fastapi" ] || [ "$FRAMEWORK" = "django" ] || [ "$FRAMEWORK" = "flask" ]) && echo 8000 ||
  echo 3000
)"

bash scripts/test_endpoints.sh "$BASE_URL"
```

### Check Swagger UI

```bash
# Should return 200 and contain "swagger"
curl -s "$BASE_URL/docs" | grep -i swagger && echo "PASS" || echo "FAIL"
```

### Docker build (if DOCKER = yes)

```bash
docker compose -f docker-compose.prod.yml up --build -d
sleep 5
BASE_URL="http://localhost:3000"
bash scripts/test_endpoints.sh "$BASE_URL"
docker compose -f docker-compose.prod.yml down
```

### Showcase output

After all checks pass, print this block. Adjust the route table to only show routes that apply (omit RBAC rows when `RBAC=no`, omit `/graphql` when `GRAPHQL=no`, omit `/blog` rows when blog was skipped):

```
🧙 $APP_NAME is ready!

┌──────────────────────────────────────────────────────────┐
│  $APP_NAME                                    v1.0.0    │
│  $BASE_URL                                              │
├──────────┬───────────────────────────┬──────────────────┤
│ Method   │ Route                     │ Auth required    │
├──────────┼───────────────────────────┼──────────────────┤
│ GET      │ /health                   │ public           │
│ GET      │ /docs                     │ public           │
├──────────┼───────────────────────────┼──────────────────┤
│ POST     │ /users/register           │ public           │
│ POST     │ /users/login              │ public           │
│ POST     │ /users/refresh-token      │ public           │
│ POST     │ /users/forgot-password    │ public           │
│ GET      │ /users/me                 │ bearer token     │
│ POST     │ /users/logout             │ bearer token     │
│ GET      │ /users                    │ bearer token     │
│ GET      │ /users/:id                │ bearer token     │
│ PUT      │ /users/:id                │ bearer token     │
├──────────┼───────────────────────────┼──────────────────┤
│ GET      │ /blog/posts               │ public           │
│ POST     │ /blog/posts               │ bearer token     │
│ PATCH    │ /blog/posts/:id/publish   │ bearer token     │
│ DELETE   │ /blog/posts/:id           │ bearer token     │
├──────────┼───────────────────────────┼──────────────────┤  ← omit when RBAC=no
│ GET      │ /roles                    │ bearer + role    │
│ GET      │ /permissions              │ bearer + role    │
│ POST     │ /role-users               │ bearer + admin   │
├──────────┼───────────────────────────┼──────────────────┤  ← omit when GRAPHQL=no
│ POST     │ /graphql                  │ mixed            │
│ GET      │ /graphql                  │ public (sandbox) │
└──────────┴───────────────────────────┴──────────────────┘

Try it now:

  curl -s $BASE_URL/health | jq

  curl -s -X POST $BASE_URL/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"you@example.com","password":"Wizard123!"}' | jq

  open $BASE_URL/docs
```

---

## Failure protocols

**Peer-dependency error (Node.js):**
Present the conflict clearly, suggest the minimum version downgrade that resolves it, and ask the user to confirm before applying. Only use `--legacy-peer-deps` as a last resort after the user confirms:
```bash
# Only after user confirmation — explain the conflict first
$PM install --legacy-peer-deps
```

**DB connection refused:**
- Check that the DB service is running: `docker ps` or `pg_isready -h localhost`
- Verify `.env` DATABASE_URL matches the running service
- Offer `DB = sqlite` fallback if user cannot run the DB service locally

**TypeScript compile error (Fastify / Hono / NestJS — does not apply to Express):**
- Read the error, fix the source file, re-run `tsc --noEmit`
- Never add `// @ts-ignore` or `// @ts-nocheck` without a documented reason

**`#` alias resolution error (Express):**
- Confirm `package.json` has `"type": "module"` and the `imports` map is present
- Node.js 18+ supports subpath imports natively — no extra packages needed
- Re-run `node --input-type=module` to test a specific import

**Python import error:**
- Confirm the virtual environment is active: `which python` should point to `.venv/bin/python`
- Re-run `pip install -r requirements.txt`

**Go build error:**
- Run `go mod tidy` to sync dependencies
- Read the compile error and fix the source file

**Swagger UI blank / routes missing:**
- Confirm all routers are registered before the Swagger plugin initialises
- NestJS: confirm `@nestjs/swagger` `SwaggerModule.setup()` is called after all modules are imported
- FastAPI: routes auto-register — check that all routers are included in `app.include_router()`
- Gin: confirm `swag init` was run and `docs` package is imported
