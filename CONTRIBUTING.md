# Contributing

Thanks for helping improve this skill. Contributions are welcome via pull requests.

## What lives where

```
src/wizard-backend-boilerplate-pro/   ← edit here (source of truth)
.claude/skills/wizard-backend-boilerplate-pro/  ← symlink, do not edit
```

See [docs/architecture.md](docs/architecture.md) for the full layout.

## Adding a framework

1. Add a per-framework guide to `src/.../references/frameworks/<name>.md`
2. Add code templates to `src/.../assets/api-templates/<name>/`
3. Add an auth provider stub to `src/.../assets/auth-provider/<name>.<ext>.template`
4. Add an env template entry in `src/.../assets/env-templates/` if a new ecosystem
5. Update the framework list in `src/.../SKILL.md` and `workflow.md`
6. Update `references/module-catalog.md` for any framework-specific module notes

See [docs/development.md](docs/development.md) for the detailed checklist.

## Adding a module

1. Add the module spec to `src/.../references/module-catalog.md`
2. Add code templates under `src/.../assets/api-templates/<framework>/`
3. Wire the install condition into `workflow.md` Phase 5

## Template rules

- Templates may use `{{APP_NAME}}` as a placeholder — it is replaced during scaffold
- All `.js.template` files must pass `node --check`
- All `.ts.template` files must pass `tsc --noEmit --noResolve`
- All `.py.template` files must pass `python3 -m py_compile`
- All `.go.template` files must pass `gofmt -e`

CI enforces these automatically on every PR.

## Pull request checklist

- [ ] New templates pass local syntax checks (see above)
- [ ] `module-catalog.md` updated if adding/changing a module
- [ ] `workflow.md` updated if changing the interview flow or install conditions
- [ ] `CHANGELOG.md` entry added under `[Unreleased]`

## Reporting issues

Use the GitHub issue templates — bug reports and feature requests each have a form.
