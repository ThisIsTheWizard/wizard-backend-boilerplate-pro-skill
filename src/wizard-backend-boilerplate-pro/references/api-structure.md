# API Structure — Reference

Full route map, request/response shapes, and project layout conventions.

---

## Complete route map

| Method | Path | Module | Auth | DB |
|---|---|---|---|---|
| `GET` | `/` | HealthCheck | No | No |
| `POST` | `/users/register` | UserAuth | No | Yes |
| `POST` | `/users/verify-user-email` | UserAuth | No | Yes |
| `POST` | `/users/resend-verification-email` | UserAuth | No | Yes |
| `POST` | `/users/login` | UserAuth | No | Yes |
| `POST` | `/users/refresh-token` | UserAuth | No | Yes |
| `GET` | `/users/me` | UserAuth | Yes | Yes |
| `POST` | `/users/logout` | UserAuth | Yes | Yes |
| `POST` | `/users/change-email` | UserAuth | Yes | Yes |
| `POST` | `/users/verify-change-email` | UserAuth | Yes | Yes |
| `POST` | `/users/change-password` | UserAuth | Yes | Yes |
| `POST` | `/users/forgot-password` | UserAuth | No | Yes |
| `POST` | `/users/verify-forgot-password` | UserAuth | No | Yes |
| `GET` | `/users` | UserAuth | Yes + `user.read` | Yes |
| `GET` | `/users/:id` | UserAuth | Yes + `user.read` | Yes |
| `PUT` | `/users/:id` | UserAuth | Yes + `user.update` | Yes |
| `GET` | `/roles` | Role | Yes + `role.read` | Yes |
| `GET` | `/roles/:id` | Role | Yes + `role.read` | Yes |
| `POST` | `/roles` | Role | Yes + `role.create` | Yes |
| `PUT` | `/roles/:id` | Role | Yes + `role.update` | Yes |
| `DELETE` | `/roles/:id` | Role | Yes + `role.delete` | Yes |
| `GET` | `/permissions` | Permission | Yes + `permission.read` | Yes |
| `GET` | `/permissions/:id` | Permission | Yes + `permission.read` | Yes |
| `POST` | `/permissions` | Permission | Yes + `permission.create` | Yes |
| `PUT` | `/permissions/:id` | Permission | Yes + `permission.update` | Yes |
| `DELETE` | `/permissions/:id` | Permission | Yes + `permission.delete` | Yes |
| `GET` | `/role-users` | RoleUser | Yes + `role_user.read` | Yes |
| `GET` | `/role-users/:id` | RoleUser | Yes + `role_user.read` | Yes |
| `POST` | `/role-users` | RoleUser | Yes + `role_user.create` | Yes |
| `DELETE` | `/role-users/:id` | RoleUser | Yes + `role_user.delete` | Yes |
| `GET` | `/role-permissions` | RolePermission | Yes + `role_permission.read` | Yes |
| `GET` | `/role-permissions/:id` | RolePermission | Yes + `role_permission.read` | Yes |
| `POST` | `/role-permissions` | RolePermission | Yes + `role_permission.create` | Yes |
| `PUT` | `/role-permissions/:id` | RolePermission | Yes + `role_permission.update` | Yes |
| `DELETE` | `/role-permissions/:id` | RolePermission | Yes + `role_permission.delete` | Yes |
| `GET` | `/blog/posts` | BlogCRUD | No (published) | Yes |
| `POST` | `/blog/posts` | BlogCRUD | Yes | Yes |
| `GET` | `/blog/posts/:id` | BlogCRUD | No (published) | Yes |
| `GET` | `/blog/posts/slug/:slug` | BlogCRUD | No (published) | Yes |
| `PUT` | `/blog/posts/:id` | BlogCRUD | Yes (author/admin) | Yes |
| `PATCH` | `/blog/posts/:id/publish` | BlogCRUD | Yes | Yes |
| `PATCH` | `/blog/posts/:id/unpublish` | BlogCRUD | Yes | Yes |
| `DELETE` | `/blog/posts/:id` | BlogCRUD | Yes | Yes |
| `POST` | `/files/upload` | FileUpload | Yes | No |
| `GET` | `/files/:id` | FileDownload | Yes | No |
| `POST` | `/webhooks/:provider` | WebhookReceiver | HMAC | No |
| `GET` | `/docs` | SwaggerDocs | No | No |
| `WS` | `/ws` | WebSocketHub | Optional | No |
| `GET` | `/events` | ServerSentEvents | Optional | No |
| `POST` | `/graphql` | GraphQLServer | Context | No |
| `GET` | `/graphql` | GraphQLServer playground | No | No |

Routes with **Auth = Yes** use `authorizer()` middleware (Express) or `@UseGuards(AuthGuard)` (NestJS).
Permission strings like `user.read` mean `module.action` — only enforced when `AUTH = jwt | apikey | session`.

**RBAC routes (`/roles`, `/permissions`, `/role-users`, `/role-permissions`) are only generated when `AUTH = jwt | apikey | session`.**
When `AUTH` is a provider (better-auth, Clerk, Auth0, Supabase):
- Omit all RBAC routes — the provider manages roles/permissions internally
- Replace `authorizer()` with the provider's SDK middleware
- Use the provider's dashboard / API to assign roles to users

GraphQL routes only present when `GRAPHQL = yes`.

---

## Test-only endpoints

These routes are active only when `NODE_ENV = test`:

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/test/setup` | Sync DB schema + seed roles/permissions/auth-templates |
| `GET` | `/test/verification-tokens` | Query `?email=&type=&user_id=` — fetch OTP for assertions |

---

## Request / Response shapes

### `POST /users/register`

Request:
```json
{ "email": "user@example.com", "password": "Secure123!", "first_name": "Alice", "last_name": "Smith" }
```

Response `201`:
```json
{
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", "status": "unverified", "first_name": "Alice" },
    "access_token": "eyJ...",
    "refresh_token": "eyJ..."
  },
  "success": true
}
```

A `send_user_verification_token` email is sent with a 6-digit OTP.

---

### `POST /users/verify-user-email`

Request:
```json
{ "email": "user@example.com", "token": "123456" }
```

Response `200`:
```json
{ "data": { "ok": true }, "success": true }
```

On success: user `status` → `active`, `user` role assigned via RoleUser.

---

### `POST /users/login`

Request:
```json
{ "email": "user@example.com", "password": "Secure123!" }
```

Response `200`:
```json
{
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", "status": "active", "Roles": [{ "name": "user" }] },
    "access_token": "eyJ...",
    "refresh_token": "eyJ..."
  },
  "success": true
}
```

Error `401`:
```json
{ "error": "INVALID_CREDENTIALS", "success": false }
```

---

### `GET /users/me`

Headers: `Authorization: Bearer <access_token>`

Response `200`:
```json
{
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "status": "active",
    "first_name": "Alice",
    "Roles": [{ "name": "user", "Permissions": [{ "module": "user", "action": "read", "can_do_the_action": true }] }]
  },
  "success": true
}
```

---

### `POST /users/forgot-password`

Request:
```json
{ "email": "user@example.com" }
```

Response `200` (always, prevents enumeration):
```json
{ "data": { "ok": true }, "success": true }
```

Sends a `send_forgot_password_token` email with a 6-digit OTP.

---

### `POST /users/verify-forgot-password`

Request:
```json
{ "email": "user@example.com", "token": "654321", "password": "NewSecure456!" }
```

Response `200`:
```json
{ "data": { "ok": true }, "success": true }
```

---

### `GET /users` (paginated)

Query: `?page=1&pageSize=20&search=alice&status=active`

Response `200`:
```json
{
  "data": [
    { "id": "uuid", "email": "alice@example.com", "status": "active", "Roles": [{ "name": "user" }] }
  ],
  "meta_data": { "page": 1, "pageSize": 20, "total": 42, "hasNext": true },
  "success": true
}
```

---

### `GET /blog/posts` (paginated)

Query: `?page=1&pageSize=20&search=hello&status=published`

Response `200`:
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Hello World",
      "slug": "hello-world",
      "excerpt": "Short intro...",
      "status": "published",
      "tags": ["news"],
      "published_at": "2026-01-15T10:00:00Z",
      "created_at": "2026-01-14T09:00:00Z"
    }
  ],
  "meta_data": { "page": 1, "pageSize": 20, "total": 5, "hasNext": false },
  "success": true
}
```

---

### Error envelope

All errors use:
```json
{ "error": "MACHINE_READABLE_CODE", "success": false }
```

Express: `CustomError(statusCode, message)` — message is uppercased + spaces → underscores for the `error` field.

NestJS: `BadRequestException({ messages: [...], success: false })` from global `ValidationPipe` exceptionFactory.

Common codes:

| Status | Code |
|---|---|
| 400 | `INVALID_INPUT` / `VALIDATION_ERROR` |
| 401 | `UNAUTHORIZED` |
| 403 | `FORBIDDEN` / `INSUFFICIENT_ROLE` / `INSUFFICIENT_PERMISSION` |
| 404 | `USER_NOT_FOUND` / `ROLE_NOT_FOUND` / etc. |
| 409 | `EMAIL_ALREADY_EXISTS` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## Project layout conventions

### Express projects (JavaScript + Babel)

```
src/
├── server.js
├── routes/
│   └── index.js
├── middlewares/
│   ├── index.js
│   ├── authorizer.js
│   └── error.js
├── modules/
│   ├── controllers.js      # barrel
│   ├── services.js         # barrel
│   ├── routers.js          # barrel
│   ├── entities.js         # barrel
│   ├── helpers.js          # barrel
│   ├── user/               # 5-file pattern
│   ├── permission/
│   ├── role/
│   ├── role-user/
│   ├── role-permission/
│   ├── auth-token/         # entity + service + helper
│   ├── auth-template/      # entity + service + helper
│   ├── verification-token/ # entity + service + helper
│   ├── notification/       # service only
│   ├── common/             # service + helper
│   └── doc/                # router only (Swagger)
└── utils/
    ├── database/index.js   # Sequelize instance
    ├── error/index.js      # CustomError class
    └── seed/               # role.seed.js, user.seed.js, auth-template.seed.js
test/
    ├── setup.js
    └── <module>/<module>.test.js
```

### NestJS projects (TypeScript + Prisma)

```
src/
├── main.ts
├── app/
│   ├── app.module.ts
│   ├── app.controller.ts
│   └── app.service.ts
├── auth/
│   ├── auth.module.ts
│   ├── auth.service.ts
│   ├── auth.controller.ts
│   └── auth.dto.ts
├── user/
│   ├── user.module.ts
│   ├── user.service.ts
│   ├── user.controller.ts
│   ├── user.dto.ts
│   └── user.interface.ts
├── role/
│   ├── role.module.ts
│   ├── role.service.ts
│   ├── role.controller.ts
│   └── role.dto.ts
├── permission/
├── auth-token/
│   ├── auth-token.service.ts
│   ├── auth-token.dto.ts
│   └── auth-token.interface.ts
├── verification-token/
│   └── verification-token.service.ts
├── common/
│   ├── common.module.ts
│   ├── common.service.ts
│   └── common.interface.ts
├── prisma/
│   └── prisma.service.ts
├── guards/
│   ├── auth.guard.ts
│   ├── roles.guard.ts
│   └── permissions.guard.ts
├── decorators/
│   ├── user.decorator.ts
│   ├── roles.decorator.ts
│   ├── permissions.decorator.ts
│   └── password.decorator.ts
└── filters/
    └── global-exception.filter.ts
prisma/
├── schema.prisma
└── seed.ts
test/
├── setup.ts
├── fixtures.ts
└── <module>.test.ts
```

---

## Port conventions

| Framework | Default port |
|---|---|
| Express | 3000 |
| NestJS | 8000 |
| FastAPI / Django / Flask | 8000 |
| Gin / Echo | 8080 |

Always overrideable via `PORT` env var.

---

## Docker environments

Every project ships three Docker environments:

| Files | Purpose |
|---|---|
| `Dockerfile.Dev` + `docker-compose.dev.yml` | Hot-reload dev with pgAdmin |
| `Dockerfile.Prod` + `docker-compose.prod.yml` | Compiled production build |
| `Dockerfile.Test` + `docker-compose.test.yml` | Isolated test DB + test runner container |
