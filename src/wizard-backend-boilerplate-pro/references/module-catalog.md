# Module Catalog — 38 API Modules

Full specifications for all modules installed in Phase 5.
Module count: **30 core + 8 RBAC/auth infrastructure = 38 total**.

---

## Category: Core (6 modules)

### HealthCheck
**Description:** `GET /` endpoint returning `{ message, success }`. Optional DB ping via Sequelize `.authenticate()` or Prisma `$queryRaw`.

**Endpoints:**
- `GET /` → `{ message: "Welcome to the API service!", success: true }`

**Per-framework notes:**
- Express: simple route in `src/routes/index.js`
- NestJS: `AppController.getWelcomeMessage()` returning `AppService.getWelcomeMessage()`

---

### Config
**Description:** Environment variable loading at startup. Fails fast on missing required vars.

**Peer deps:**
- Express (JS): `dotenv` → `import 'dotenv/config'` in `server.js`
- NestJS: `@nestjs/config` → `ConfigModule.forRoot({ isGlobal: true })`

---

### Logger
**Description:** Request logging via `console.log` (Express) or NestJS built-in logger.

**Per-framework notes:**
- Express: no separate logging library — `NODE_ENV`-gated `console.log` in Sequelize config
- NestJS: default NestJS logger; override with `app.useLogger()` if needed

---

### ErrorHandler
**Description:** Global error handler that converts thrown `CustomError` (Express) or `BadRequestException` (NestJS) into consistent JSON responses.

**Response shape:** `{ error: "MACHINE_READABLE_CODE", success: false }`

**Per-framework notes:**
- Express: 4-argument middleware registered last in `server.js` via `app.use(error)`
- NestJS: global exception filter `src/filters/global-exception.filter.ts`

---

### CORS
**Description:** Cross-origin resource sharing. Permissive (`origin: '*'`) by default.

**Peer deps:**
- Express: `cors` npm package → `app.use(cors({ origin: '*' }))`
- NestJS: `app.enableCors({ origin: '*' })` in `main.ts` (built-in)

---

### RateLimit
**Description:** IP-based rate limiting.

**Peer deps:**
- Express: add `express-rate-limit` if needed (not in base boilerplate — add as an enhancement)
- NestJS: add `@nestjs/throttler` if needed

---

## Category: Auth infrastructure (4 modules — custom auth only)

> **Install condition:** `AUTH = jwt | apikey | session` only.
> When `AUTH` is a provider (better-auth, Clerk, Auth0, Supabase), skip this entire category.
> Providers manage tokens, OTPs, and email flows internally.

### AuthToken
**Description:** Stores JWT access + refresh token pairs in the database. Enables logout (token revocation) and refresh.

**Schema fields:** `id`, `user_id` (FK), `access_token` (unique), `refresh_token` (unique), `created_at`, `updated_at`

**Key functions:**
- `createAuthTokensForUser({ email, roles, user_id })` — signs both tokens, persists the pair
- `verifyAnAuthTokenForUser(token)` — checks JWT signature; throws if invalid
- `refreshAuthTokensForUser({ access_token, refresh_token })` — validates refresh token, issues new pair, deletes old
- `revokeAnAuthTokenForUser(token)` — deletes the token row (logout)

**Peer deps:** `jsonwebtoken`

**Template files:**
- Express: `src/modules/auth-token/auth-token.{entity,service,helper}.js`
- NestJS: `src/auth-token/auth-token.service.ts`

---

### VerificationToken
**Description:** Short-lived 6-digit OTP tokens for email verification and password reset. Stored in DB with expiry and status.

**Schema fields:** `id`, `user_id` (FK), `email`, `token` (6-digit numeric), `type` (`user_verification` | `forgot_password`), `status` (`unverified` | `verified` | `cancelled`), `expired_at` (5 min from creation), `created_at`, `updated_at`

**Key functions:**
- `createVerificationToken({ user_id, email, type })` — generates 6-digit OTP, sets `expired_at = now + 5min`
- `validateVerificationToken({ user_id, token, type })` — checks record exists, not expired, status = unverified; marks `verified`
- `cancelVerificationTokens(user_id, type)` — marks all pending tokens of a type as `cancelled` (before creating a new one)

**Template files:**
- Express: `src/modules/verification-token/verification-token.{entity,service,helper}.js`
- NestJS: `src/verification-token/verification-token.service.ts`

---

### AuthTemplate
**Description:** Email template store. Templates are Handlebars strings stored in the DB with an `event` key. Used by the Notification module.

**Schema fields:** `id`, `event` (unique key e.g. `send_user_verification_token`), `subject` (Handlebars), `body` (Handlebars HTML), `created_at`, `updated_at`

**Seeded events:** `send_user_verification_token`, `send_forgot_password_token`

**Template files:**
- Express: `src/modules/auth-template/auth-template.{entity,service,helper}.js`
- NestJS: NestJS boilerplate stores templates inline in the notification service; add a `AuthTemplate` Prisma model if DB storage is needed.

---

### Notification
**Description:** Email sending service. Fetches the template by event key, compiles it with Handlebars, sends via AWS SES (with `console.log` fallback in test/dev).

**Peer deps:** `@aws-sdk/client-ses`, `handlebars`

**Key function:**
- `sendNotification({ event, to, data })` — looks up AuthTemplate by `event`, compiles Handlebars with `data`, sends email

**Env vars required:** `FROM_EMAIL`, `AWS_REGION`

**Template files:**
- Express: `src/modules/notification/notification.service.js`
- NestJS: `src/notification/notification.service.ts`

---

## Category: RBAC (4 modules — custom auth only)

> **Install condition:** `AUTH = jwt | apikey | session` only.
> Auth providers (better-auth, Clerk, Auth0, Supabase) ship their own role/permission/org systems.
> Installing custom RBAC tables alongside a provider would duplicate and conflict with that system.
> When using a provider, use its native RBAC APIs instead.

**Provider RBAC equivalents:**
| Provider | Role system | Permission system |
|---|---|---|
| better-auth | `@better-auth/plugins` `ac` (access control) | Fine-grained via `createAccessControl()` |
| Clerk | Roles + permissions in the Clerk dashboard | `has({ permission })` check via `auth()` |
| Auth0 | Roles via Management API | Permissions assigned to roles |
| Supabase | Custom claims in JWT via `app_metadata` | Row-Level Security (RLS) policies |

### Role
**Description:** Manages the 4 built-in roles: `admin`, `developer`, `moderator`, `user`.

**Endpoints:**
- `GET /roles` — list roles (auth + permission: `role.read`)
- `GET /roles/:id` — get role (auth + permission: `role.read`)
- `POST /roles` — create role (auth + permission: `role.create`)
- `PUT /roles/:id` — update role (auth + permission: `role.update`)
- `DELETE /roles/:id` — delete role (auth + permission: `role.delete`)

**Seeded at startup:** all 4 roles are always seeded.

---

### Permission
**Description:** Module-action permission records. Every combination of `(module, action)` is a row.

**Modules:** `user`, `role`, `permission`, `role_user`, `role_permission`
**Actions:** `create`, `read`, `update`, `delete`

**Endpoints:**
- `GET /permissions` — list (auth + permission: `permission.read`)
- `GET /permissions/:id` — get one
- `POST /permissions` — create (auth + admin/developer)
- `PUT /permissions/:id` — update
- `DELETE /permissions/:id` — delete

**Seeded at startup:** all 20 permission rows (`5 modules × 4 actions`).

---

### RoleUser
**Description:** Assigns roles to users. Many-to-many junction.

**Schema fields:** `id`, `user_id`, `role_id` — composite unique.

**Endpoints:**
- `GET /role-users` — list (auth + permission: `role_user.read`)
- `GET /role-users/:id` — get one
- `POST /role-users` — assign role to user (auth + permission: `role_user.create`)
- `DELETE /role-users/:id` — remove role from user (auth + permission: `role_user.delete`)

---

### RolePermission
**Description:** Associates permissions with roles and stores a `can_do_the_action` flag per row. A `false` flag means "explicitly denied".

**Schema fields:** `id`, `role_id`, `permission_id`, `can_do_the_action` (boolean), `created_by`, timestamps.

**Endpoints:**
- `GET /role-permissions` — list
- `GET /role-permissions/:id` — get one
- `POST /role-permissions` — create (auth + admin)
- `PUT /role-permissions/:id` — update `can_do_the_action`
- `DELETE /role-permissions/:id` — delete

---

## Category: User + Auth routes (1 module — UserAuth)

### UserAuth (combines AuthRouter + UsersCRUD)
**Description:** All user-facing auth and profile routes. In the real boilerplate these all live under `/users`.

**Endpoints:**
- `POST /users/register` — `{ email, password, first_name?, last_name? }` → `{ data: { user, access_token, refresh_token }, success: true }`
- `POST /users/verify-user-email` — `{ email, token }` → activates account, assigns `user` role
- `POST /users/resend-verification-email` — `{ email }` → sends new OTP
- `POST /users/login` — `{ email, password }` → `{ data: { user, access_token, refresh_token }, success: true }`
- `POST /users/refresh-token` — `{ access_token, refresh_token }` → new token pair
- `GET /users/me` — (auth) → `{ data: { user + roles + permissions }, success: true }`
- `POST /users/logout` — (auth) → revokes token, `{ data: { ok: true }, success: true }`
- `POST /users/change-email` — (auth) `{ email }` → sends verification OTP to new email
- `POST /users/verify-change-email` — (auth) `{ token }` → confirms new email
- `POST /users/change-password` — (auth) `{ old_password, new_password }` → updates password, invalidates tokens
- `POST /users/forgot-password` — `{ email }` → sends reset OTP (always 200, no enumeration)
- `POST /users/verify-forgot-password` — `{ email, token, password }` → resets password
- `GET /users` — (auth + `user.read`) paginated user list
- `GET /users/:id` — (auth + `user.read`) get user
- `PUT /users/:id` — (auth + `user.update`) update user

**Password policy:** min 8 chars, at least 1 uppercase, 1 lowercase, 1 number, 1 symbol (enforced by `validator.isStrongPassword`).

---

## Category: Blog (1 module)

### BlogCRUD
**Description:** Full CRUD for blog posts with status workflow and pagination. Only installed when the user requests it.

**Schema fields:** `id`, `title`, `slug` (unique, auto-generated), `content`, `excerpt`, `author_id` (FK → User), `status` (`draft` | `published` | `archived`), `tags` (array), `published_at`, timestamps.

**Endpoints:**
- `GET /blog/posts` — list (paginated, filterable by `status`, `search`)
- `POST /blog/posts` — create (auth)
- `GET /blog/posts/:id` — get by ID
- `GET /blog/posts/slug/:slug` — get by slug
- `PUT /blog/posts/:id` — update (auth, author/admin)
- `PATCH /blog/posts/:id/publish` — publish (auth)
- `PATCH /blog/posts/:id/unpublish` — unpublish (auth)
- `DELETE /blog/posts/:id` — soft-delete via `status = archived` (auth)

**Pagination envelope:** `{ data: Post[], meta_data: { page, pageSize, total, hasNext } }`

---

## Category: Infrastructure (4 modules)

### DatabaseClient
**Description:** Database connection setup.

- Express: `sequelize.authenticate()` called at startup in `server.js`
- NestJS: `PrismaService extends PrismaClient implements OnModuleInit` — auto-connects

---

### CacheClient
**Description:** Redis wrapper for get/set/del/expire.

**Peer deps:**
- Node.js: `ioredis`

---

### Migrations
**Description:** Schema migration runner.

- Express (Sequelize): `sequelize.sync({ alter: true })` in dev; `sequelize.sync()` in prod
- NestJS (Prisma): `pnpm prisma migrate deploy` in prod Dockerfile CMD

---

### BackgroundJob
**Description:** Async job queue.

**Peer deps:**
- Node.js: `bullmq` + `ioredis`

---

## Category: Real-time (3 modules)

### WebSocketHub
**Peer deps:** `ws` + `@types/ws` (Express) · `@nestjs/websockets` (NestJS)

### ServerSentEvents
**Description:** `GET /events` SSE stream.

### EventEmitter
**Peer deps:** `eventemitter3` (Express/Fastify/Hono) · NestJS built-in `EventEmitter2`

---

## Category: DX / Docs (5 modules)

### SwaggerDocs
**Description:** OpenAPI 3.0 spec at `/docs`.

**Peer deps:**
- Express: swagger-ui-express + swagger-jsdoc → `src/modules/doc/doc.router.js`
- NestJS: `@nestjs/swagger` → `DocumentBuilder` + `SwaggerModule.setup('docs', app, document)`

### RequestValidator
**Peer deps:** `validator` (Express) · `class-validator` + `class-transformer` (NestJS)

### ResponseFormatter
**Description:** Consistent envelope `{ data: T, success: true }` or `{ error: string, success: false }`.

### TypedEnv
**Description:** Validated env schema on startup.
**Peer deps:** `dotenv` (Express) · `@nestjs/config` (NestJS)

### GraphQLServer
**Description:** GraphQL endpoint alongside REST. Only installed when `GRAPHQL = yes`.

**Endpoints:**
- `POST /graphql` — execute queries/mutations
- `GET /graphql` — Apollo Sandbox (dev) or GraphiQL

**Peer deps:**
- Express: `@apollo/server @as-integrations/express5 graphql @graphql-tools/merge`
- NestJS: `@nestjs/graphql @apollo/server graphql`

**Schema exposes:** users, blog posts (queries + mutations). See `references/graphql.md`.

---

## Module counts by category

| Category | Count |
|---|---|
| Core | 6 |
| Auth infrastructure | 4 |
| RBAC | 4 |
| User + Auth routes | 1 |
| Blog | 1 |
| Infrastructure | 4 |
| Real-time | 3 |
| DX / Docs | 5 |
| **Total** | **28 base + GraphQLServer (conditional)** |
