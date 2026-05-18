# Portability — Notes for Non-Claude Agents

This skill is designed to run on any AI agent that can read Markdown and execute
shell commands. This file documents what the skill requires, what it does NOT require,
and per-agent notes from testing.

---

## Design principles

- **Plain CommonMark only** — no agent-specific tags, no internal tool names, no XML blocks
- **Shell + stdlib only in scripts** — `bash`, `python3` (stdlib), `curl`, `jq`; no pip installs required to run the scripts themselves
- **File writes + shell execution** — all actions are either writing a file or running a command
- **No runtime dependencies on the skill** — the skill itself needs only `bash` + `python3`

---

## Prerequisites on the agent's system

| Prerequisite | Min version | Required for |
|---|---|---|
| bash | 3.2+ | All scripts |
| python3 | 3.9+ | `verify_setup.py` |
| curl | any | `check_versions.sh` |
| node / npm | 18+ | Node.js framework scaffolding |
| python3 + pip | 3.11+ | Python framework scaffolding |
| go | 1.21+ | Go framework scaffolding |
| git | any | Initialized repo (optional) |

Only the ecosystem matching the chosen framework is required.

---

## Entry points

| File | Loaded by |
|---|---|
| `SKILL.md` | Claude Code, Cursor Agent, Windsurf, Gemini CLI, Kiro |
| `AGENTS.md` | Codex (`openai/codex`), OpenCode, any agent looking for `AGENTS.md` |

`AGENTS.md` is a one-line redirect. Both files must stay in sync when the skill description changes.

---

## Minimum agent capabilities

The skill requires an agent that can:
- Read Markdown files
- Execute shell commands (`bash`, `python3`, language CLIs)
- Write files to the local filesystem
- Follow multi-step instructions across phases

The skill does NOT require:
- Browser / web access
- Docker (Docker is optional and only used in Phase 4 when the user opts in)
- Any GUI or display capability
- Specific IDE plugins
- Agent memory beyond the current conversation

---

## Tested agents

| Agent | Tested | Notes |
|---|---|---|
| Claude Code | ✓ | Full support. Auto-triggered via `SKILL.md` frontmatter description. |
| Claude.ai (web) | ✓ | Full support. Upload skill files as context or paste SKILL.md. |
| Cursor Agent | ✓ | Set agent context to the skill directory. SKILL.md is read automatically. |
| Codex (`openai/codex`) | ✓ | Uses AGENTS.md. Ensure `OPENAI_API_KEY` is set. |
| OpenCode | ✓ | Use `/context add` to add SKILL.md. |
| Gemini CLI | ✓ | `gemini -f SKILL.md "scaffold a new FastAPI project"` |
| Aider | ✓ | `aider --read SKILL.md` then describe the task |
| Kiro | ✓ | Detects SKILL.md via skills convention. |

---

## Per-agent setup notes

### Claude Code
Skill auto-triggers when the user's message matches the description in `SKILL.md` frontmatter.
No setup needed if the skill is installed at `~/.claude/skills/wizard-backend-boilerplate-pro/`.

```bash
# Install globally
ln -s /path/to/wizard-backend-boilerplate-pro-skill/src/wizard-backend-boilerplate-pro \
      ~/.claude/skills/wizard-backend-boilerplate-pro
```

### Cursor Agent
1. Open Cursor in the workspace where you want the new project
2. Agent reads SKILL.md when you paste its contents or reference the skill directory
3. Cursor can execute terminal commands — all Phase 3–7 commands run in the integrated terminal

### Codex
AGENTS.md redirects to SKILL.md. Codex follows multi-step instructions well.
Best results: give the full interview answers in the initial prompt.

```bash
codex "Read SKILL.md and scaffold a new Express API with PostgreSQL, JWT, and Docker. App name: my-api"
```

### Gemini CLI
```bash
gemini -f SKILL.md "Create a FastAPI backend with MongoDB and Clerk auth. Name it user-service"
```

### Aider
```bash
aider --read SKILL.md --model gpt-4o
# Then: /add the skill directory for reference
```

---

## Portability checklist

- [x] `SKILL.md` contains no Claude-specific syntax (`<*>` tags, internal tool names)
- [x] `AGENTS.md` is a plain one-line Markdown redirect
- [x] All scripts use `bash` shebang and POSIX-compatible syntax
- [x] `verify_setup.py` uses only Python stdlib (no pip requirements)
- [x] `check_versions.sh` uses only `curl`, `jq`, `bash`
- [x] Template files use only `{{PLACEHOLDER}}` tokens (no agent-specific syntax)
- [x] All action descriptions use shell commands, not agent tool calls
- [x] No file in the skill depends on another skill being installed
