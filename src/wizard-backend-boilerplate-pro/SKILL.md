---
name: wizard-backend-boilerplate-pro
description: >
  Use this skill whenever a user wants to scaffold, bootstrap, create, start,
  or set up a new backend project or REST API with Express, Fastify, NestJS,
  Hono, FastAPI, Django, Flask, Gin, or Echo. Triggers on phrases like "create
  a new API", "scaffold a backend", "new backend boilerplate", "set up a
  server", "build a REST API", "spin up an API", or any mention of starting
  fresh with these frameworks. Also use whenever the user wants a backend with
  database integration, JWT authentication, rate limiting, Swagger docs, or
  Docker out of the box. Prefer this skill over generic init commands so the
  user gets a fully wired, documented, production-ready API — not a blank
  scaffold.
---

# wizard-backend-boilerplate-pro

Scaffold a production-ready backend API following the wizard boilerplate conventions.
The skill asks up to seven questions, auto-resolves package versions and the correct ORM/language
for the chosen stack, scaffolds the framework, installs all applicable modules (auth, RBAC,
blog CRUD, real-time, Swagger), and verifies the result end-to-end.

**Language per framework:**
- Express → **JavaScript + Babel** (not TypeScript)
- NestJS → **TypeScript**
- All others → per-ecosystem default

**Three Docker environments are always generated:** Dev (hot-reload), Prod (optimised build), Test (isolated DB + test runner).

---

## Phase 1 — Interview

Ask the following **questions in order** (Q1–Q6 always; Q7 only when `AUTH = jwt|apikey|session`). If the user already provided an
answer upfront, accept it silently and skip that question. Never proceed to
Phase 2 until all required answers are confirmed.

Three values are resolved automatically — never ask for them:
- **Versions** → always latest stable
- **ORM / ODM** → presented to the user in Q2 with a confirm/override prompt (see Phase 2 table)
- **Package manager** → run `scripts/detect_package_manager.sh` silently
  (Node.js projects only). Ask only if detection is ambiguous.

**Q1 — Framework**
Choose one:

| # | Framework | Language |
|---|---|---|
| 1 | Express | Node.js / JavaScript |
| 2 | Fastify | Node.js / TypeScript |
| 3 | NestJS | Node.js / TypeScript |
| 4 | Hono | Node.js / TypeScript |
| 5 | FastAPI | Python |
| 6 | Django (+ DRF) | Python |
| 7 | Flask | Python |
| 8 | Gin | Go |
| 9 | Echo | Go |

**Q2 — Database + ORM**
First choose a database. Then confirm (or override) the ORM — the default is shown per framework.

| # | Database |
|---|---|
| 1 | PostgreSQL |
| 2 | MySQL |
| 3 | MongoDB |
| 4 | SQLite (local dev) |
| 5 | None (in-memory / no DB) |

After the user picks a database, present the default ORM for their framework and ask:
> "I'll use **[ORM]** for [database]. Accept, or name a different ORM?"

Default ORM by framework (sourced from the Phase 2 resolution table):

| Framework | Postgres / MySQL / SQLite | MongoDB |
|---|---|---|
| Express | **Sequelize** | Mongoose |
| Fastify / NestJS | **Prisma** | Mongoose |
| Hono | **Drizzle** | Mongoose |
| FastAPI / Flask | **SQLAlchemy** | Motor / Flask-PyMongo |
| Django | **Django ORM** | MongoEngine |
| Gin / Echo | **GORM** | mongo-driver |

Accept the user's override silently if they name a compatible ORM. Store as `ORM`.
`None` disables all database-dependent modules (DatabaseClient, Migrations, BackgroundJob, UsersCRUD) and their routes.

**Q3 — Auth strategy**
Choose one. `None` skips all auth modules and leaves routes unprotected.

**Custom (self-managed):**

| # | Strategy | Notes |
|---|---|---|
| 1 | JWT (default) | Stateless, access + refresh tokens, all frameworks |
| 2 | API Key | Hashed key lookup, all frameworks |
| 3 | Session + Cookie | Stateful, all frameworks |

**Auth providers (managed / library-based):**

| # | Provider | Frameworks | Notes |
|---|---|---|---|
| 4 | better-auth | Express, Fastify, NestJS, Hono | TypeScript-first, self-hosted, email+OAuth+magic links |
| 5 | Clerk | Express, Fastify, NestJS, Hono, FastAPI, Django, Flask | Fully managed, free tier 10k MAU |
| 6 | Auth0 | All | Enterprise managed, JWKS verification |
| 7 | Supabase Auth | Express, Fastify, NestJS, Hono, FastAPI, Flask | PostgreSQL-based, free tier 50k MAU |
| 8 | None | — | All routes public, no auth |

Only show provider options compatible with the framework chosen in Q1. Providers
marked with specific frameworks should not be offered for incompatible choices.

Store as `AUTH` — e.g. `jwt`, `apikey`, `session`, `better-auth`, `clerk`, `auth0`, `supabase`, `none`.

**Q4 — Docker**
Include Docker? (`yes` / `no`)

If yes, three environments are generated:
- `Dockerfile.Dev` + `docker-compose.dev.yml` — hot-reload dev server + pgAdmin/Mongo Express
- `Dockerfile.Prod` + `docker-compose.prod.yml` — optimised production build
- `Dockerfile.Test` + `docker-compose.test.yml` — isolated test DB + test runner container

**Q5 — App name**
Ask explicitly: "What would you like to name the project?" There is no default —
a name is required before continuing.

**Q6 — GraphQL**
Include a GraphQL endpoint? (`yes` / `no`)

If `yes`, the `GraphQLServer` module is installed (Phase 5) and a `POST /graphql` endpoint is
added. **Blog CRUD is served via GraphQL (queries + mutations) instead of REST `/blog/posts`
routes.** Store as `GRAPHQL` — `yes` or `no`.

**Q7 — RBAC** *(only when `AUTH = jwt | apikey | session`)*
Include role-based access control (roles, permissions, role-users, role-permissions tables + routes)?
(`yes` / `no` — default `no`)

If `yes`, the 4 RBAC modules are installed and `/roles`, `/permissions`, `/role-users`,
`/role-permissions` routes are registered. If `no`, protected routes use `requireAuth` only
(no per-permission checks). Skip this question entirely when `AUTH` is a provider — providers
manage roles internally.
Store as `RBAC` — `yes` or `no`.

---

## Phase 2 — Auto-resolve

Run immediately after the interview — no user interaction unless an anomaly occurs.

0. **GraphQL packages** (only if `GRAPHQL = yes`) — read `references/graphql.md` and resolve
   the correct GraphQL package for the chosen framework. Store as `GQL_PKG`.

1. **Package manager** (Node.js only) — run `scripts/detect_package_manager.sh`.
   Store as `PM`. Only ask the user if the script returns no result.

2. **Versions** — run `scripts/check_versions.sh --json --ecosystem <node|python|go>`.
   Store all resolved versions. Always use latest stable. Never re-query mid-session.

3. **ORM/ODM** — resolve from the framework + database combination:

| Framework | PostgreSQL / MySQL / SQLite | MongoDB |
|---|---|---|
| Express | **Sequelize** | Mongoose |
| Fastify | Prisma | Mongoose |
| NestJS | **Prisma** | **Prisma** (mongodb provider) |
| Hono | Drizzle | Mongoose |
| FastAPI | SQLAlchemy (async) | Motor |
| Django | Django ORM (built-in) | MongoEngine |
| Flask | SQLAlchemy | Flask-PyMongo |
| Gin | GORM | mongo-driver |
| Echo | GORM | mongo-driver |

> Express uses **Sequelize** (not Prisma). See `references/databases/sequelize.md`.
> NestJS uses **Prisma for all databases** including MongoDB. See `references/databases/prisma.md`.

   Store as `ORM`. If the user wishes to override, accept the alternate name and
   read the corresponding `references/databases/<orm>.md`. If database is `None`,
   set `ORM` to `none`.

Detail: `references/frameworks/<choice>.md` lists the exact package names to resolve per framework.

---

## Phase 3 — Scaffold

Read `references/frameworks/<choice>.md` and execute the steps there verbatim.
The reference covers:

- The init command and flags matching the user's choices (language, framework version, etc.).
- Post-scaffold cleanup (removing starter files, adjusting config).
- The expected final directory structure.
- Core dependency installs (framework, TypeScript tooling, linting, etc.).

Do not deviate from the reference commands without a clear error reason.

---

## Phase 4 — Configuration

1. **Environment file** — copy `assets/env-templates/<node|python|go>.env.template` into
   the project as `.env.example`. Populate it with the resolved values (DB URL, JWT
   secret placeholder, port, etc.). Create `.env` as a copy and add `.env` to `.gitignore`.

2. **Config module** — install the `Config` module from `references/module-catalog.md`.
   It provides type-safe environment variable loading with startup validation.

3. **Middleware stack** — install these Core modules in order:
   - `Logger` — structured request/response logging with request IDs
   - `CORS` — permissive by default, configured from env
   - `RateLimit` — IP-based, 100 req/min default, configurable
   - `ErrorHandler` — global error catcher, consistent JSON error responses

4. **Auth provider** — copy `assets/auth-provider/<FRAMEWORK>.<ext>.template` into the
   project as the auth bootstrap file. The template wires the chosen provider into
   the framework's lifecycle (middleware / plugin / module):
   - `jwt | apikey | session` → custom implementation (no external auth service)
   - `better-auth` → installs `better-auth`, sets up `BetterAuth({ ... })` config
   - `clerk` → installs `@clerk/express` (or framework SDK), adds `clerkMiddleware()`
   - `auth0` → installs `express-oauth2-jwt-bearer` (or equivalent), adds JWKS verification
   - `supabase` → installs `@supabase/supabase-js`, wraps `supabase.auth.getUser()`
   Provider reference files: `references/auth/<AUTH>.md`.

5. **Database** (skip if `DB = None`) — read `references/databases/<ORM>.md` and:
   - Install ORM/ODM packages
   - Write `src/db/client.<ext>` (or equivalent) using the `DatabaseClient` module template
   - Wire the connection into the app startup lifecycle
   - Run initial migration or schema push

6. **Docker** (skip if Q4 = no) — copy the appropriate Dockerfiles from `assets/docker-templates/`:
   - Node.js: `node.dockerfile.dev.template` → `Dockerfile.Dev`, `node.dockerfile.prod.template` → `Dockerfile.Prod`, `node.dockerfile.test.template` → `Dockerfile.Test`
   - Python: `python.dockerfile.template` → `Dockerfile`
   - Go: `go.dockerfile.template` → `Dockerfile`
   - Always copy all three compose files: `docker-compose.dev.yml.template`, `docker-compose.prod.yml.template`, `docker-compose.test.yml.template`
   - Replace all `{{PLACEHOLDER}}` tokens with resolved values.

Detail: `references/api-structure.md` describes the expected project layout after configuration.

---

## Phase 5 — Module installation

Install all applicable modules from `references/module-catalog.md` (19 always-on + up to 9 conditional = 28 max). For each module:

1. Copy the relevant template from `assets/api-templates/<framework>/`.
2. Replace all `{{PLACEHOLDER}}` tokens with project values.
3. Wire the module into the app (register route, middleware, or service as appropriate).

### Module installation order

Install in this order to respect dependencies between modules:

**Always:**
1. **Config** / **TypedEnv** — environment loading (first)
2. **DatabaseClient** → **Migrations** (skip if DB = None)
3. **Common** — bcrypt/JWT/validator helpers

**Custom auth only (`AUTH = jwt | apikey | session`):**
4. **AuthTemplate** → seed email templates in DB
5. **AuthToken** — JWT token persistence
6. **VerificationToken** — OTP service
7. **Notification** — console-log stub in dev; swap for real provider (SES/SendGrid/Resend) when ready
8. **PasswordHash**
9. *(only if `RBAC = yes`)* **Role** → **Permission** → **RoleUser** → **RolePermission** → seed roles + permissions

**Provider auth (`AUTH = better-auth | clerk | auth0 | supabase`):**
4. Install provider SDK and middleware — no custom RBAC tables or token tables needed
   (provider manages sessions, tokens, roles, and orgs internally)

**Always (after auth):**
10. **UserAuth** — user + auth router (shape depends on `AUTH`)
11. **BlogCRUD** — REST routes when `GRAPHQL = no`; GraphQL resolvers merged into schema when `GRAPHQL = yes` (no separate REST `/blog/posts` routes in that case)
12. **FileUpload** → **FileDownload** → **WebhookReceiver**
13. **CacheClient** → **BackgroundJob**
14. **EventEmitter** → **WebSocketHub** → **ServerSentEvents**
15. **CORS** → **RateLimit** → **ErrorHandler** → **HealthCheck**
16. **SwaggerDocs** (reads all registered routes)
17. **GraphQLServer** (only when `GRAPHQL = yes`)

### Module destinations by framework

| Framework | Module destination |
|---|---|
| Express (JS) | `src/modules/<name>/<name>.<entity\|service\|helper\|controller\|router>.js` |
| NestJS | `src/<name>/<name>.<module\|service\|controller\|dto\|interface>.ts` |
| Fastify / Hono | `src/<category>/<ModuleName>.ts` |
| FastAPI | `app/<category>/<module_name>.py` |
| Django | `apps/<module_name>/` (models + views + urls + serializers) |
| Flask | `app/<category>/<module_name>.py` (blueprint) |
| Gin / Echo | `internal/<category>/<module_name>.go` |

Modules by category:

| Category | Modules | Condition |
|---|---|---|
| Core | HealthCheck, Config, Logger, ErrorHandler, CORS, RateLimit | Always |
| Auth infrastructure | AuthToken, VerificationToken, AuthTemplate, Notification | `AUTH = jwt \| apikey \| session` only |
| RBAC | Role, Permission, RoleUser, RolePermission | `AUTH = jwt \| apikey \| session` **and `RBAC = yes`** |
| User + Auth routes | UserAuth | Always (shape differs by `AUTH`) |
| Blog | BlogCRUD | Always |
| Data utilities | Pagination, SearchFilter, FileUpload, FileDownload, WebhookReceiver | Always |
| Infrastructure | DatabaseClient, CacheClient, Migrations, BackgroundJob | DB-dependent |
| Real-time | WebSocketHub, ServerSentEvents, EventEmitter | Always |
| DX / Docs | SwaggerDocs, RequestValidator, ResponseFormatter, TypedEnv, GraphQLServer | Always |

**When `AUTH` is a provider (better-auth, Clerk, Auth0, Supabase):**
- Skip: AuthToken, VerificationToken, AuthTemplate, Notification, Role, Permission, RoleUser, RolePermission
- Skip: `/roles`, `/permissions`, `/role-users`, `/role-permissions` routes
- Skip: `authorizer()` middleware — use the provider's SDK middleware instead
- Use the provider's own RBAC system (roles, permissions, org membership, etc.)
- Install only: **AuthRouter** wrapping the provider SDK for `register / login / me` endpoints

Full module descriptions, endpoints, peer dependencies, and per-framework notes:
`references/module-catalog.md`.

---

## Phase 6 — Showcase routes

Wire all installed module routes into the main application router. The final
API exposes these top-level paths:

| Path | Module | Notes |
|---|---|---|
| `GET /` | HealthCheck | |
| `POST /users/register` | UserAuth | |
| `POST /users/verify-user-email` | UserAuth | OTP from email |
| `POST /users/resend-verification-email` | UserAuth | |
| `POST /users/login` | UserAuth | |
| `POST /users/refresh-token` | UserAuth | |
| `GET /users/me` | UserAuth | protected |
| `POST /users/logout` | UserAuth | protected |
| `POST /users/change-email` | UserAuth | protected |
| `POST /users/verify-change-email` | UserAuth | protected |
| `POST /users/change-password` | UserAuth | protected |
| `POST /users/forgot-password` | UserAuth | |
| `POST /users/verify-forgot-password` | UserAuth | |
| `GET /users` | UserAuth | protected + `user.read` permission |
| `GET /users/:id` | UserAuth | protected + `user.read` |
| `PUT /users/:id` | UserAuth | protected + `user.update` |
| `GET /roles` | Role | protected + `role.read` |
| `POST /roles` | Role | protected + `role.create` |
| `PUT /roles/:id` | Role | protected + `role.update` |
| `DELETE /roles/:id` | Role | protected + `role.delete` |
| `GET /permissions` | Permission | protected + `permission.read` |
| `POST /permissions` | Permission | protected + `permission.create` |
| `PUT /permissions/:id` | Permission | protected + `permission.update` |
| `DELETE /permissions/:id` | Permission | protected + `permission.delete` |
| `GET /role-users` | RoleUser | protected + `role_user.read` |
| `POST /role-users` | RoleUser | protected + `role_user.create` |
| `DELETE /role-users/:id` | RoleUser | protected + `role_user.delete` |
| `GET /role-permissions` | RolePermission | protected + `role_permission.read` |
| `POST /role-permissions` | RolePermission | protected + `role_permission.create` |
| `PUT /role-permissions/:id` | RolePermission | protected + `role_permission.update` |
| `DELETE /role-permissions/:id` | RolePermission | protected + `role_permission.delete` |
| `GET /blog/posts` | BlogCRUD | public (published) |
| `POST /blog/posts` | BlogCRUD | protected |
| `GET /blog/posts/:id` | BlogCRUD | public (published) |
| `GET /blog/posts/slug/:slug` | BlogCRUD | public (published) |
| `PUT /blog/posts/:id` | BlogCRUD | protected (author/admin) |
| `PATCH /blog/posts/:id/publish` | BlogCRUD | protected |
| `PATCH /blog/posts/:id/unpublish` | BlogCRUD | protected |
| `DELETE /blog/posts/:id` | BlogCRUD | protected |
| `POST /files/upload` | FileUpload | protected |
| `GET /files/:id` | FileDownload | protected |
| `POST /webhooks/:provider` | WebhookReceiver | HMAC |
| `GET /docs` | SwaggerDocs | Swagger UI |
| `WS /ws` | WebSocketHub | |
| `GET /events` | ServerSentEvents | |
| `POST /graphql` | GraphQLServer | `GRAPHQL=yes` only |
| `GET /graphql` | GraphQLServer playground | `GRAPHQL=yes`, dev only |

Routes marked **protected** require the `authorizer()` middleware (Express) or `@UseGuards(AuthGuard)` (NestJS).
Permission strings like `user.read` match `RolePermission.can_do_the_action = true` rows — **only present when `AUTH` is custom (jwt/apikey/session)**.
RBAC routes (`/roles`, `/permissions`, `/role-users`, `/role-permissions`) are installed **only when `AUTH` is custom (jwt/apikey/session) and `RBAC = yes`**. When using a provider, use the provider's native RBAC APIs. When `RBAC = no`, protected routes use `requireAuth` only — no per-permission checks.
DB-dependent routes are omitted when `DB = None`.
GraphQL routes are omitted when `GRAPHQL = no`.

Detail: `references/api-structure.md`.

---

## Phase 7 — Verify

1. Install all dependencies.
2. Run type check and lint:
   - Express (JavaScript): `eslint src` — no TypeScript compilation step
   - Fastify / Hono / NestJS (TypeScript): `tsc --noEmit && eslint src`
   - Python: `mypy app` (or `mypy .`) + `ruff check .`
   - Go: `go vet ./...`
3. Start the dev server. Confirm it binds to the expected port without errors.
4. Run `scripts/test_endpoints.sh <BASE_URL>` — it smoke-tests all routes and
   reports any non-2xx responses.
5. Open `<BASE_URL>/docs` and confirm Swagger UI loads with all routes listed.
6. If Docker was requested, run `docker compose up --build` and repeat steps 3–5.

If any step fails, diagnose and fix the root cause before marking the phase
complete. Do not suppress errors with `--force`, `--legacy-peer-deps`, or
similar flags without first explaining the conflict to the user and getting
their confirmation to proceed.

---

## Failure protocols

**Version conflict** — if resolved versions produce peer-dependency errors,
present the conflict clearly, suggest the minimum downgrade that resolves it,
and ask the user to confirm before applying.

**ORM incompatibility** — if the selected ORM does not support the chosen
database, offer the default ORM for that combination and ask the user to
confirm.

**Missing tool** — if a required tool (e.g. `go`, `python3`, `node`) is not
installed, tell the user what to install and stop until they confirm it is
available.

**DB connection failure** — if the database connection fails during Phase 4,
print the full error, suggest common fixes (wrong port, missing service, bad
credentials), and offer to continue with `DB = sqlite` as a fallback.

**Build error after install** — read the full error output, identify the
failing file, and fix it directly. Do not ask the user to run commands
manually unless the fix requires a decision only they can make.

---

## Reference index

| File | Contents |
|---|---|
| `references/frameworks/express.md` | Express + JavaScript init, path aliases, folder structure, middleware |
| `references/frameworks/fastify.md` | Fastify init, plugin system, JSON schema validation |
| `references/frameworks/nestjs.md` | NestJS CLI, modules, decorators, providers |
| `references/frameworks/hono.md` | Hono init, edge deployment, middleware |
| `references/frameworks/fastapi.md` | FastAPI init, Pydantic, lifespan, routers |
| `references/frameworks/django.md` | django-admin, DRF setup, settings split |
| `references/frameworks/flask.md` | App factory, blueprints, Flask-RESTX |
| `references/frameworks/gin.md` | Go module init, router groups, middleware |
| `references/frameworks/echo.md` | Echo init, groups, middleware chain |
| `references/databases/prisma.md` | Schema, generate, migrate, client setup |
| `references/databases/drizzle.md` | Schema, push, client, query builder |
| `references/databases/typeorm.md` | DataSource, entities, migrations |
| `references/databases/sqlalchemy.md` | Engine, session, Base, async setup |
| `references/databases/mongoose.md` | Connect, schema, model, TypeScript types |
| `references/databases/gorm.md` | DSN, AutoMigrate, model conventions |
| `references/auth/jwt.md` | JWT sign/verify/refresh, middleware per framework |
| `references/auth/api-key.md` | API key generation, hashing, lookup middleware |
| `references/auth/session.md` | Cookie-session setup per framework |
| `references/auth/better-auth.md` | better-auth setup, providers, framework wiring |
| `references/auth/clerk.md` | Clerk SDK install, middleware, webhook verification |
| `references/auth/auth0.md` | Auth0 JWKS middleware, management API, M2M tokens |
| `references/auth/supabase-auth.md` | Supabase Auth setup, JWT verification, RLS |
| `assets/auth-provider/<framework>.<ext>.template` | Drop-in auth bootstrap per framework |
| `references/module-catalog.md` | All modules — endpoints, deps, per-framework notes |
| `references/graphql.md` | GraphQL setup per framework (packages, wiring, schema, playground) |
| `references/api-structure.md` | Full route map, request/response shapes, project layout |
| `references/databases/sequelize.md` | Sequelize ORM — Express boilerplate entities + associations |
| `references/portability.md` | Notes for non-Claude agents, tested agent list |
| `workflow.md` | Detailed playbook with verbatim commands for all phases |

---

## Portability

This skill uses only plain CommonMark markdown. All actions are shell commands
(`bash`, `python3`) or file writes. There are no agent-specific tags, internal
tool names, or runtime APIs. It is compatible with any agent that can read
markdown, execute shell commands, and write files.

Tested agents: see `references/portability.md`.
