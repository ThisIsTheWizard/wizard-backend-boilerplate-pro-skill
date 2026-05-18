# Architecture — `wizard-backend-boilerplate-pro`

## Three-location pattern

The skill lives in three places. Only one is the source of truth.

| Location | Role | Edit? |
|---|---|---|
| `src/wizard-backend-boilerplate-pro/` | **Source of truth** | Yes |
| `.claude/skills/wizard-backend-boilerplate-pro/` | Symlink → `src/` | Never |
| _(future)_ `cli/assets/` | Bundled copy for npm installer | Never directly |

### Why three locations?

**`src/`** is where you make changes. It is a plain directory you can open in any editor, run git diff on, and review in PRs.

**`.claude/skills/`** is where Claude Code looks for installed skills. The symlink means the skill is always in sync with `src/` — no copy-paste, no drift.

**`cli/assets/`** will be used by a future npm CLI that copies the skill to any project on demand. It will be generated from `src/` by a build script, not edited directly.

## Symlink setup

```bash
# From the repo root — run once after cloning
ln -s ../../src/wizard-backend-boilerplate-pro \
      .claude/skills/wizard-backend-boilerplate-pro
```

Verify:
```bash
ls -la .claude/skills/
# wizard-backend-boilerplate-pro -> ../../src/wizard-backend-boilerplate-pro
```

## Skill entry points

| File | Loaded by |
|---|---|
| `SKILL.md` | Claude Code, Cursor, Windsurf, any skill-aware agent |
| `AGENTS.md` | Codex, OpenCode, and agents that look for AGENTS.md |

`AGENTS.md` is a one-line redirect to `SKILL.md`. Both files must be kept in sync when the description frontmatter changes.

## File responsibilities

```
SKILL.md        ← 7-phase workflow overview + decision logic
workflow.md     ← verbatim shell commands for every phase step
references/     ← one file per concern (framework / database / auth / module)
assets/         ← drop-in code templates applied during scaffolding
scripts/        ← automation scripts called from SKILL.md / workflow.md
```

`SKILL.md` is intentionally under 400 lines. It describes *what* to do and *which reference to read* for detail. The references do the heavy lifting so SKILL.md stays navigable.

## Adding a new framework

1. Add an entry to the framework table in `SKILL.md` Phase 1 Q1.
2. Add the ORM row to the auto-resolution table in `SKILL.md` Phase 2.
3. Create `references/frameworks/<name>.md` with scaffold steps.
4. Create `assets/api-templates/<name>/` with all required template files.
5. Update `workflow.md` Phase 3 with the new framework's commands.
6. Update `scripts/check_versions.sh` with the new framework's package names.
7. Update `references/portability.md` test matrix.
