# Development Guide — `wizard-backend-boilerplate-pro`

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Node.js | 20+ | Validate Node.js framework templates |
| Python | 3.11+ | Run `scripts/generate_palette.py`, `scripts/verify_setup.py` |
| Go | 1.21+ | Validate Go framework templates |
| bash | 3.2+ | Run all `.sh` scripts |
| git | any | Clone, symlink verification |

## Cloning and setup

```bash
git clone https://github.com/ThisIsTheWizard/wizard-backend-boilerplate-pro-skill
cd wizard-backend-boilerplate-pro-skill

# Create the .claude/skills symlink
ln -s ../../src/wizard-backend-boilerplate-pro \
      .claude/skills/wizard-backend-boilerplate-pro
```

## Validating scripts

```bash
# Validate all shell scripts
bash -n src/wizard-backend-boilerplate-pro/scripts/check_versions.sh
bash -n src/wizard-backend-boilerplate-pro/scripts/detect_package_manager.sh
bash -n src/wizard-backend-boilerplate-pro/scripts/test_endpoints.sh

# Validate Python scripts
python -m py_compile src/wizard-backend-boilerplate-pro/scripts/verify_setup.py
```

## Running check_versions.sh

```bash
# Print versions in human-readable form
bash src/wizard-backend-boilerplate-pro/scripts/check_versions.sh

# Print as JSON (used by SKILL.md Phase 2)
bash src/wizard-backend-boilerplate-pro/scripts/check_versions.sh --json

# Query a specific ecosystem
bash src/wizard-backend-boilerplate-pro/scripts/check_versions.sh --ecosystem node
bash src/wizard-backend-boilerplate-pro/scripts/check_versions.sh --ecosystem python
bash src/wizard-backend-boilerplate-pro/scripts/check_versions.sh --ecosystem go
```

## Adding a new module

1. Add an entry to the module table in `references/module-catalog.md`:
   - name, category, description, endpoints (if any), peer deps, per-framework notes
2. Add the module's endpoint(s) to `references/api-structure.md`.
3. Add template files for at least the three primary frameworks (Express, FastAPI, Gin):
   - `assets/api-templates/<framework>/<ModuleName>.<ext>.template`
4. Update `SKILL.md` Phase 5 module list.
5. Update `scripts/test_endpoints.sh` with smoke-test curl commands for the new endpoints.

## Adding a new color preset

Not applicable for the backend skill — no color system. The backend skill has no theming phase.

## Template placeholder conventions

All template files use `{{PLACEHOLDER}}` tokens that are replaced during Phase 5 (module installation):

| Placeholder | Replaced with |
|---|---|
| `{{APP_NAME}}` | Project name from Phase 1 Q5 |
| `{{DB_URL}}` | Database connection string |
| `{{JWT_SECRET}}` | Generated JWT secret |
| `{{PORT}}` | Server port (default 3000 for Node, 8000 for Python, 8080 for Go) |
| `{{ORM}}` | Resolved ORM name |
| `{{FRAMEWORK}}` | Framework slug |
| `{{LANGUAGE}}` | `typescript`, `javascript`, `python`, or `go` |

## CI

The repository uses two GitHub Actions workflows:

- `.github/workflows/claude.yml` — runs on PRs, triggers Claude Code review
- `.github/workflows/python-ci.yml` — runs `python -m py_compile` on all Python scripts

## File naming conventions

- Reference files: `kebab-case.md`
- Template files: `<name>.<ext>.template` (e.g. `server.ts.template`)
- Scripts: `snake_case.sh` / `snake_case.py`
- Asset directories: `kebab-case/`
