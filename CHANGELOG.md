# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-05-19

### Added

**9 supported frameworks**
- Express, Fastify, Hono (Node.js)
- NestJS (TypeScript)
- FastAPI, Flask, Django (Python)
- Gin, Echo (Go)

**Up to 28 installable API modules**
- Core: HealthCheck, Config, Logger, ErrorHandler, CORS, RateLimit
- Auth infrastructure (custom auth): AuthToken, VerificationToken, AuthTemplate, Notification
- RBAC (optional): Role, Permission, RoleUser, RolePermission
- User routes: UserAuth (register, login, refresh, verify, forgot-password, profile)
- Blog CRUD with REST and GraphQL modes
- Infrastructure: DatabaseClient, Migrations
- Real-time (opt-in): CacheClient (Redis), BackgroundJob (BullMQ/Celery), WebSocketHub, ServerSentEvents, EventEmitter
- DX: SwaggerDocs, RequestValidator, ResponseFormatter, TypedEnv, GraphQLServer

**Per-framework asset templates**
- `.env` templates for Node, Python, Go ecosystems
- API module code templates (JS/TS/Python/Go)
- Auth provider integration stubs (better-auth, Clerk, Auth0, Supabase, JWT custom)
- Docker: multi-stage Dockerfile variants + docker-compose (dev, test, prod)

**7-phase interview workflow**
- Q1 Framework → Q2 Database → Q3 Auth strategy → Q4 RBAC → Q5 Real-time → Q6 Blog → Q7 Docker
- Conditional module graph: only what you need gets installed

**CI: template syntax validation**
- JS: `node --check`
- TypeScript: `tsc --noEmit --noResolve`
- Python: `python3 -m py_compile`
- Go: `gofmt -e`

[1.0.0]: https://github.com/ThisIsTheWizard/wizard-backend-boilerplate-pro-skill/releases/tag/v1.0.0
