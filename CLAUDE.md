# CLAUDE.md — `wizard-backend-boilerplate-pro` Skill

This file provides guidance to Claude Code when working in this repository.

## Architecture

Three locations — one source of truth. See [`docs/architecture.md`](docs/architecture.md) for the full explanation.

| Location | Role |
|---|---|
| **`src/wizard-backend-boilerplate-pro/`** | **Source of truth** — edit here |
| **`.claude/skills/wizard-backend-boilerplate-pro/`** | Symlink → `src/` — consumed by Claude Code |
| _(future)_ **`cli/assets/`** | Bundled copy for npm CLI installer |

```
wizard-backend-boilerplate-pro-skill/
├── src/
│   └── wizard-backend-boilerplate-pro/    # ← EDIT HERE (source of truth)
│       ├── SKILL.md                        # Universal entry point (7-phase workflow)
│       ├── AGENTS.md                       # One-line alias → SKILL.md
│       ├── workflow.md                     # Detailed playbook with verbatim commands
│       ├── references/
│       │   ├── frameworks/                 # Per-framework scaffold guides (9 frameworks)
│       │   ├── databases/                  # ORM/ODM setup per database type
│       │   ├── auth/                       # Auth strategy implementations
│       │   ├── module-catalog.md
│       │   ├── api-structure.md
│       │   └── portability.md
│       ├── assets/
│       │   ├── env-templates/              # .env templates per language ecosystem
│       │   ├── api-templates/              # Per-framework module code templates
│       │   └── docker-templates/           # Dockerfile + docker-compose templates
│       └── scripts/
│           ├── check_versions.sh
│           ├── detect_package_manager.sh
│           ├── test_endpoints.sh
│           └── verify_setup.py
├── .claude/skills/wizard-backend-boilerplate-pro/  # symlink → ../../src/…
├── docs/                                   # Developer documentation
│   ├── architecture.md
│   └── development.md
├── .github/workflows/                      # CI
│   ├── claude.yml
│   └── python-ci.yml
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skill.json
├── CLAUDE.md
├── README.md
└── LICENSE
```

**Source of truth:** `src/wizard-backend-boilerplate-pro/`

All skill content lives there. The `.claude/skills/` entry is a symlink — never edit files
there directly. The root holds only repo infrastructure (CI, docs, manifests).

## Session convention

Each session completes **exactly one TODO item** from `TODO.md`. Do not move to the next item unless the user explicitly starts a new session for it.

Mark the item `[x]` in `TODO.md` when complete.

## Code quality

All generated code files (`.js`, `.ts`, `.py`, `.go`) in templates must be syntactically valid and follow the conventions of the target language. TypeScript templates must pass `tsc --noEmit`. Python templates must pass `python -m py_compile`. Go templates must pass `go vet`.

## Reference files

- `PLAN.md` — architecture decisions and full skill structure (source of truth for build decisions)
- `TODO.md` — ordered build checklist, one item per session
- `src/wizard-backend-boilerplate-pro/SKILL.md` — the skill entry point itself
- `docs/architecture.md` — three-location pattern and symlink setup
- `docs/development.md` — how to add frameworks, update references, run validation
