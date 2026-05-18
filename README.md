# wizard-backend-boilerplate-pro

A Claude Code skill that scaffolds production-ready backend APIs in minutes. Ask it to create a new backend project and it walks you through five questions, then builds a fully wired API with authentication, database integration, structured logging, rate limiting, and Swagger docs — ready to `docker compose up`.

## What it builds

- **28 API modules** across 6 categories (Core, Auth, Data, Infrastructure, Real-time, DX/Docs)
- **OpenAPI / Swagger UI** at `/docs` — auto-generated from your routes
- **Working REST API** with health check, auth, users CRUD, pagination, file upload, WebSocket, SSE
- **Database integration** with the right ORM auto-wired for your framework + DB choice
- **Authentication** — JWT, API Key, or session-based, fully implemented with middleware
- **Optional Docker** — production-ready multi-stage `Dockerfile` + `docker-compose.yml`
- **Structured logging** with request IDs, timing, and error context
- **Environment config** — typed `.env` loading with validation

## Supported frameworks

### Node.js / TypeScript
| Framework | Character |
|---|---|
| **Express** | Classic, middleware-based, maximum flexibility |
| **Fastify** | High-performance, schema-first, 2× faster than Express |
| **NestJS** | Opinionated, decorator-based, enterprise-grade |
| **Hono** | Ultra-lightweight, edge-ready, runs anywhere |

### Python
| Framework | Character |
|---|---|
| **FastAPI** | Async, Pydantic-powered, OpenAPI native |
| **Django** | Batteries-included, Django REST Framework |
| **Flask** | Minimal, explicit, battle-tested |

### Go
| Framework | Character |
|---|---|
| **Gin** | High-performance, production-popular |
| **Echo** | Clean API, middleware-rich |

## ORM / ODM

The skill auto-selects the best ORM for your framework + database combination:

| Framework | SQL (PostgreSQL / MySQL / SQLite) | MongoDB |
|---|---|---|
| Express / Fastify / Hono | Prisma | Mongoose |
| NestJS | TypeORM | `@nestjs/mongoose` |
| FastAPI / Flask | SQLAlchemy (async) | Motor |
| Django | Django ORM | MongoEngine |
| Gin / Echo | GORM | mongo-driver |

You can override the default during the interview.

## The 28 modules

| Category | Modules |
|---|---|
| **Core** | HealthCheck, Config, Logger, ErrorHandler, CORS, RateLimit |
| **Auth** | JwtAuth, ApiKeyAuth, PasswordHash, AuthRouter, SessionAuth |
| **Data** | UsersCRUD, Pagination, SearchFilter, FileUpload, FileDownload, WebhookReceiver |
| **Infrastructure** | DatabaseClient, CacheClient, Migrations, BackgroundJob |
| **Real-time** | WebSocketHub, ServerSentEvents, EventEmitter |
| **DX / Docs** | SwaggerDocs, RequestValidator, ResponseFormatter, TypedEnv |

## Usage

The skill triggers automatically when you ask:

- "Create a new Express API"
- "Scaffold a FastAPI backend"
- "Set up a NestJS project with PostgreSQL and JWT"
- "New backend boilerplate with Gin and Docker"
- "Build a REST API with Flask and MongoDB"

## Five interview questions

1. **Framework** — choose from the 9 supported frameworks
2. **Database** — PostgreSQL, MySQL, MongoDB, SQLite, or None
3. **Auth strategy** — JWT (default), API Key, Session+Cookie, or None
4. **Docker** — include Dockerfile + docker-compose.yml? (yes/no)
5. **Project name** — no default, required

Three values are auto-resolved:
- **ORM/ODM** — best choice for your framework + DB (override allowed)
- **Versions** — latest stable from the registry
- **Package manager** — auto-detected from lockfile (Node.js projects)

## Portability

Works with Claude Code, Cursor Agent, OpenCode, Codex, Gemini CLI, and any agent that can read Markdown and execute shell commands. No agent-specific syntax anywhere.
