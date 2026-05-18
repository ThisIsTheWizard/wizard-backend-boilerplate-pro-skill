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

Collect all **six answers** before running any commands. Never start Phase 2 early.

```
Q1  Framework?
     1) Express       (Node.js / TypeScript)
     2) Fastify       (Node.js / TypeScript)
     3) NestJS        (Node.js / TypeScript)
     4) Hono          (Node.js / TypeScript)
     5) FastAPI       (Python)
     6) Django + DRF  (Python)
     7) Flask         (Python)
     8) Gin           (Go)
     9) Echo          (Go)

Q2  Database?
     1) PostgreSQL
     2) MySQL
     3) MongoDB
     4) SQLite
     5) None

Q3  Auth strategy?
     1) JWT           (default — stateless, access + refresh tokens)
     2) API Key       (simple service-to-service auth)
     3) Session       (cookie-based, stateful)
     4) None          (no auth, all routes public)

Q4  Include Docker (Dockerfile + docker-compose.yml)?
     yes / no

Q5  Project name?
     (no default — required)

Q6  Include GraphQL endpoint alongside REST?
     yes / no
     (If yes: installs Apollo/Mercurius/Strawberry/gqlgen per framework, mounts POST /graphql,
      and adds an interactive playground in dev. REST routes are unchanged.)
```

Store answers as:
- `FRAMEWORK` — e.g. `express`, `fastapi`, `gin`
- `DB` — e.g. `postgres`, `mysql`, `mongodb`, `sqlite`, `none`
- `AUTH` — e.g. `jwt`, `apikey`, `session`, `none`
- `DOCKER` — `yes` or `no`
- `APP_NAME` — e.g. `my-api`
- `GRAPHQL` — `yes` or `no`

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

### ORM/ODM resolution table

| FRAMEWORK | DB = postgres / mysql / sqlite | DB = mongodb |
|---|---|---|
| express | prisma | mongoose |
| fastify | prisma | mongoose |
| nestjs | typeorm | mongoose |
| hono | drizzle | mongoose |
| fastapi | sqlalchemy | motor |
| django | django-orm | mongoengine |
| flask | sqlalchemy | flask-pymongo |
| gin | gorm | mongo-driver |
| echo | gorm | mongo-driver |

Store resolved ORM as `ORM`. If `DB = none`, set `ORM = none`.

---

## Phase 3 — Scaffold

See `references/frameworks/<FRAMEWORK>.md` for the full scaffold procedure.
Quick-reference commands:

### Express
```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
$PM init -y
$PM add express cors helmet morgan express-rate-limit
$PM add -D typescript @types/node @types/express ts-node nodemon eslint prettier
npx tsc --init
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
sed -i "s/{{PORT}}/$([ "$FRAMEWORK" = "fastapi" ] || [ "$FRAMEWORK" = "flask" ] || [ "$FRAMEWORK" = "django" ] && echo 8000 || ([ "$FRAMEWORK" = "gin" ] || [ "$FRAMEWORK" = "echo" ] && echo 8080) || echo 3000)/g" "$APP_NAME/.env"
```

### Database setup (skip if DB = none)

Node.js + Prisma:
```bash
$PM add prisma @prisma/client
npx prisma init --datasource-provider "$([ "$DB" = "mongodb" ] && echo mongodb || [ "$DB" = "mysql" ] && echo mysql || [ "$DB" = "sqlite" ] && echo sqlite || echo postgresql)"
```

Node.js + Drizzle (Hono):
```bash
$PM add drizzle-orm drizzle-kit
$PM add -D drizzle-kit
```

Python + SQLAlchemy:
```bash
pip install sqlalchemy[asyncio] alembic
# For PostgreSQL: pip install asyncpg
# For MySQL:      pip install aiomysql
# For SQLite:     pip install aiosqlite
```

Go + GORM:
```bash
go get gorm.io/gorm
# PostgreSQL: go get gorm.io/driver/postgres
# MySQL:      go get gorm.io/driver/mysql
# SQLite:     go get gorm.io/driver/sqlite
```

### Docker setup (skip if DOCKER = no)

```bash
cp "assets/docker-templates/$([ "$FRAMEWORK" = "fastapi" ] || [ "$FRAMEWORK" = "django" ] || [ "$FRAMEWORK" = "flask" ] && echo python || ([ "$FRAMEWORK" = "gin" ] || [ "$FRAMEWORK" = "echo" ] && echo go) || echo node).dockerfile.template" "$APP_NAME/Dockerfile"

cp assets/docker-templates/docker-compose.yml.template "$APP_NAME/docker-compose.yml"

# Replace placeholders
sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$APP_NAME/Dockerfile" "$APP_NAME/docker-compose.yml"
sed -i "s/{{DB}}/$DB/g" "$APP_NAME/docker-compose.yml"
```

---

## Phase 5 — Module installation

For each module, copy the template file and replace `{{PLACEHOLDER}}` tokens:

```bash
TEMPLATE_DIR="assets/api-templates/$FRAMEWORK"

replace_placeholders() {
  local file="$1"
  sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$file"
  sed -i "s/{{ORM}}/$ORM/g" "$file"
  sed -i "s/{{DB}}/$DB/g" "$file"
  sed -i "s/{{AUTH}}/$AUTH/g" "$file"
  sed -i "s/{{FRAMEWORK}}/$FRAMEWORK/g" "$file"
}
```

Install modules in dependency order (see SKILL.md Phase 5 for the full order).

Wire each module:

**Express example** — register route in `src/app.ts`:
```typescript
import healthRouter from './core/HealthCheck';
import authRouter from './auth/AuthRouter';
import usersRouter from './data/UsersCRUD';
import swaggerPlugin from './docs/SwaggerDocs';

app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use('/users', usersRouter);
swaggerPlugin(app);
```

**FastAPI example** — include routers in `app/main.py`:
```python
from app.core.health import router as health_router
from app.auth.router import router as auth_router
from app.data.users import router as users_router

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
node -e "const app = require('./src/app'); require('express-list-endpoints')(app).forEach(r => console.log(r.methods.join(','), r.path))"

# FastAPI — route list is visible in /docs

# Go — Gin prints routes at startup with GIN_MODE=debug
GIN_MODE=debug go run ./cmd/server
```

Confirm these paths are present:
- `GET /health`
- `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`
- `GET /users`, `POST /users`, `GET /users/:id`, `PUT /users/:id`, `DELETE /users/:id`
- `POST /files/upload`, `GET /files/:id`
- `POST /webhooks/:provider`
- `GET /docs`, `GET /docs/json`
- `WS /ws`, `GET /events`

---

## Phase 7 — Verify

### Install and type-check

```bash
# Node.js
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
# Express / Fastify / Hono
$PM run dev          # nodemon / ts-node-dev

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
BASE_URL="http://localhost:$([ "$FRAMEWORK" = "gin" ] || [ "$FRAMEWORK" = "echo" ] && echo 8080 || ([ "$FRAMEWORK" = "fastapi" ] || [ "$FRAMEWORK" = "django" ] || [ "$FRAMEWORK" = "flask" ] && echo 8000) || echo 3000)"

bash scripts/test_endpoints.sh "$BASE_URL"
```

### Check Swagger UI

```bash
# Should return 200 and contain "swagger"
curl -s "$BASE_URL/docs" | grep -i swagger && echo "PASS" || echo "FAIL"
```

### Docker build (if DOCKER = yes)

```bash
docker compose up --build -d
sleep 3
BASE_URL="http://localhost:$(grep HOST_PORT docker-compose.yml | head -1 | grep -oE '[0-9]+')"
bash scripts/test_endpoints.sh "$BASE_URL"
docker compose down
```

---

## Failure protocols

**Peer-dependency error (Node.js):**
```bash
# Try with --legacy-peer-deps only after confirming the conflict with the user
$PM install --legacy-peer-deps
```

**DB connection refused:**
- Check that the DB service is running: `docker ps` or `pg_isready -h localhost`
- Verify `.env` DB_URL matches the running service
- Offer `DB = sqlite` fallback if user cannot run the DB service locally

**TypeScript compile error:**
- Read the error, fix the source file, re-run `tsc --noEmit`
- Never add `// @ts-ignore` or `// @ts-nocheck` without a documented reason

**Python import error:**
- Confirm the virtual environment is active: `which python` should point to `.venv/bin/python`
- Re-run `pip install -r requirements.txt`

**Go build error:**
- Run `go mod tidy` to sync dependencies
- Read the compile error and fix the source file

**Swagger UI blank / routes missing:**
- Confirm all routers are registered before the Swagger plugin initializes
- NestJS: confirm `@nestjs/swagger` `SwaggerModule.setup()` is called after all modules are imported
- FastAPI: routes auto-register — check that all routers are included in `app.include_router()`
- Gin: confirm `swag init` was run and `docs` package is imported
