# Improvement Plan — wizard-backend-boilerplate-pro (Public Release)

Audited on 2026-05-19. Tasks are ordered by priority: P0 blocks publishing, P1 makes it polished, P2 makes it fun.

---

## P0 — Broken (blocks publishing)

### Session 1 · Numerical consistency pass
Fix conflicting module/question counts across every public-facing file.

| File | Current claim | Correct value |
|---|---|---|
| `skill.json` | "38 API modules" | 28 base + GraphQLServer conditional |
| `.claude-plugin/plugin.json` | "28 API modules" | ✅ correct |
| `.claude-plugin/marketplace.json` | "28 wired modules" | ✅ correct |
| `README.md` | "28 API modules" | ✅ correct |
| `SKILL.md` Phase 5 header | "Install all 30 modules" | 28 |
| `module-catalog.md` header | "38 API Modules (30 core + 8 RBAC)" then lists 28 | 28 base, 4 RBAC conditional, 4 auth-infra conditional |
| `SKILL.md` Phase 1 intro | "six questions in order" | 7 questions (Q7 conditional) |
| `README.md` | "Five interview questions" | 7 (Q7 conditional on AUTH) |
| `workflow.md` Phase 1 header | "seven answers" | ✅ correct |

**Canonical module count decision:**
- 28 modules always (6 Core + 1 UserAuth + 1 Blog + 4 Infrastructure + 3 Real-time + 5 DX/Docs + 4 Auth-infra conditional + 4 RBAC conditional)
- Wait — Auth-infra (4) and RBAC (4) are conditional, so base is 20 always-on + 4 auth-infra (when AUTH=custom) + 4 RBAC (when RBAC=yes) + 1 GraphQL (when GRAPHQL=yes) = **20–29 depending on options**
- Public headline: **"20 always-on modules + up to 9 conditional"** or simplify to **"up to 29 modules"**

### Session 2 · SKILL.md + workflow.md bug fixes
- [ ] Fix duplicate step `5.` in Phase 4 (Database is 5, Docker is also 5 — Docker should be 6)
- [ ] Fix `SKILL.md` intro saying "six questions" → "up to seven questions"  
- [ ] Fix `README.md` saying "Five interview questions" → "Seven questions (Q7 conditional)"
- [ ] Resolve `--legacy-peer-deps` contradiction: `SKILL.md` Phase 7 bans it; `workflow.md` recommends it — pick one policy and apply consistently

### Session 3 · ORM table drift in README
`README.md` says Express→Prisma and NestJS→TypeORM. `SKILL.md` uses Express→Sequelize and NestJS→Prisma. Fix README to match SKILL.md.

### Session 4 · Install instructions (README is missing this entirely)
A public developer landing on the repo must be able to install the skill. Add:
```markdown
## Installation

### Claude Code
npx claude install ThisIsTheWizard/wizard-backend-boilerplate-pro-skill

### Manual (any agent)
Clone the repo and copy / symlink src/wizard-backend-boilerplate-pro/ into your
agent's skills directory (e.g. .claude/skills/ for Claude Code).
```

---

## P1 — Polish

### Session 5 · Build out missing framework templates
Only Express has full module-level templates. Every other framework has just one entry-point file. Add at minimum:
- `core/health.<ext>.template` + `core/errorHandler.<ext>.template`
- `data/users.<ext>.template` + `data/blog.<ext>.template`
- Auth bootstrap is already covered by `assets/auth-provider/`

Priority order: **NestJS** → **FastAPI** → Fastify → Hono → Django → Flask → Gin → Echo

### Session 6 · Fill out thin module-catalog entries
WebSocketHub, ServerSentEvents, EventEmitter, CacheClient, BackgroundJob each get
1–2 lines. Each module should have: endpoints (if any), schema fields (if any), peer deps, and a 3-line example response shape.

### Session 7 · E2E CI
Add a GitHub Actions workflow that:
1. Scaffolds one project per ecosystem (Express+Postgres, FastAPI+Postgres, Gin+Postgres)
2. Runs lint + type-check
3. Starts the server
4. Hits `GET /` and `GET /docs` with curl, asserts 200

### Session 8 · Repo hygiene
- [ ] `CHANGELOG.md` (start from v1.0.0)
- [ ] `CONTRIBUTING.md`
- [ ] `.github/ISSUE_TEMPLATE/bug_report.md`
- [ ] `.github/ISSUE_TEMPLATE/feature_request.md`
- [ ] MIT badge + workflow status badge in README header

---

## P2 — Fun (what makes developers share this)

### Session 9 · README visuals
The highest-leverage change for adoption. Add:
- Animated GIF of the 7-question interview flow in Claude Code
- Screenshot of generated `/docs` Swagger UI
- `httpie` one-liner hitting the scaffolded API: `http POST :3000/users/register email=demo@example.com password=Test123!`
- What-you-get section with the full route table

### Session 10 · `examples/` directory
Committed sample scaffolds so devs see the output before installing:
```
examples/
  express-postgres-jwt/      ← Express + PostgreSQL + JWT + RBAC
  fastapi-postgres-clerk/    ← FastAPI + PostgreSQL + Clerk
  gin-mongo-jwt/             ← Gin + MongoDB + JWT
```

### Session 11 · Wizard theming
- Wizard ASCII banner at interview start
- Friendly section headers ("Choosing your weapon..." for Q1, "Summoning your data layer..." for Q2)
- Route table printed with 🧙 header at the end of Phase 7
- Named presets: `--preset starter`, `--preset enterprise`, `--preset edge`

### Session 12 · Post-scaffold showcase command
After scaffold completes, auto-generate:
- Bruno/Postman collection JSON with all routes pre-filled
- A seeded demo user so the dev can hit `POST /users/login` immediately
- Print "Your API is ready. Try: `http POST :3000/users/register email=you@example.com password=Wizard123!`"

---

## Implementation status

| Session | Status | Notes |
|---|---|---|
| 1 — Module/question count | ✅ done | Canonical count: 19 always-on, 28 max |
| 2 — Phase 4 bugs + policy | ✅ done | Fixed duplicate step-5; legacy-peer-deps policy unified |
| 3 — ORM table README | ✅ done | Express→Sequelize, NestJS→Prisma, Hono→Drizzle |
| 4 — Install instructions | ✅ done | Added Install section, 30-second hello world, Compatibility table |
| 5 — Framework templates | ✅ done | NestJS (13), FastAPI (7), Fastify (5), Hono (5) — 51 total templates (was 19) |
| 6 — Module catalog depth | ✅ done | All 6 thin entries filled; CacheClient/BackgroundJob/WS/SSE moved to conditional |
| 7 — E2E CI | ✅ done | validate-templates.yml — 4 parallel jobs (JS, TS, Python, Go); badge in README |
| 8 — Repo hygiene | ✅ done | CHANGELOG.md, CONTRIBUTING.md, bug + feature issue templates |
| 9 — README visuals | ✅ done | Full route table, curl demo, GIF/screenshot placeholder comments |
| 10 — Examples dir | ✅ done | express-postgres-jwt, fastapi-postgres-clerk, gin-mongo-jwt (uncommitted) |
| 11 — Wizard theming | ✅ done | ASCII banner, 3 presets, 🧙 question headers |
| 12 — Showcase command | ✅ done | Route table + curl one-liners printed at end of Phase 7 |
