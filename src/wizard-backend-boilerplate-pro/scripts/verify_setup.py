#!/usr/bin/env python3
"""
verify_setup.py — Validate backend project structure and configuration

Usage:
    python verify_setup.py [--dir <project_dir>] [--framework <name>] [--quiet]

Exit code:
    0 — all checks pass
    1 — one or more checks fail
"""

import argparse
import json
import os
import sys
from pathlib import Path

PASS = "\033[92m✓\033[0m"
FAIL = "\033[91m✗\033[0m"
WARN = "\033[93m?\033[0m"


def check(label: str, condition: bool, severity: str = "error") -> bool:
    icon = PASS if condition else (WARN if severity == "warn" else FAIL)
    print(f"  {icon} {label}")
    return condition


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify backend project setup")
    parser.add_argument("--dir", default=".", help="Project directory")
    parser.add_argument("--framework", default="", help="Framework name (e.g. express, fastapi)")
    parser.add_argument("--quiet", action="store_true", help="Only print failures")
    args = parser.parse_args()

    root = Path(args.dir).resolve()
    framework = args.framework.lower()
    failures = 0

    print(f"\nVerifying {root}")
    print("─" * 50)

    # ── Common checks ──────────────────────────────────────────────────────────

    print("\nProject root")
    if not check(".env file exists", (root / ".env").exists()):
        failures += 1
    if not check(".env.example exists", (root / ".env.example").exists(), "warn"):
        pass  # warn only
    if not check(".gitignore exists", (root / ".gitignore").exists(), "warn"):
        pass

    # ── Check .env has required keys ───────────────────────────────────────────

    print("\nEnvironment variables")
    env_path = root / ".env"
    env_vars: dict[str, str] = {}
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, val = line.partition("=")
                env_vars[key.strip()] = val.strip()

    required_vars = ["APP_NAME", "PORT"]
    for var in required_vars:
        if not check(f"{var} is set", var in env_vars and env_vars[var] != ""):
            failures += 1

    # Check auth vars based on what's in .env
    auth_vars_found = any(k in env_vars for k in [
        "JWT_SECRET", "SESSION_SECRET", "CLERK_SECRET_KEY",
        "AUTH0_DOMAIN", "SUPABASE_URL", "BETTER_AUTH_SECRET"
    ])
    if not check("Auth secret/config is set", auth_vars_found, "warn"):
        pass

    # Check for placeholder values
    placeholders = ["change-me", "changeme", "your-tenant", "your-project"]
    for key, val in env_vars.items():
        if any(ph in val.lower() for ph in placeholders):
            print(f"  {WARN} {key} still has placeholder value — update before production")

    # ── Node.js checks ─────────────────────────────────────────────────────────

    if framework in ("", "express", "fastify", "nestjs", "hono"):
        pkg_json = root / "package.json"
        if pkg_json.exists():
            print("\nNode.js")
            try:
                pkg = json.loads(pkg_json.read_text())
                if not check("package.json name matches APP_NAME",
                             pkg.get("name") == env_vars.get("APP_NAME"), "warn"):
                    pass
                if not check("scripts.dev exists", "dev" in pkg.get("scripts", {}), "warn"):
                    pass
                if not check("scripts.build exists", "build" in pkg.get("scripts", {})):
                    failures += 1
            except json.JSONDecodeError:
                print(f"  {FAIL} package.json is not valid JSON")
                failures += 1

    # ── Python checks ──────────────────────────────────────────────────────────

    if framework in ("", "fastapi", "django", "flask"):
        req_txt = root / "requirements.txt"
        if req_txt.exists():
            print("\nPython")
            if not check("requirements.txt exists", True):
                pass
            reqs = req_txt.read_text().lower()
            if framework == "fastapi":
                if not check("fastapi in requirements.txt", "fastapi" in reqs):
                    failures += 1
                if not check("uvicorn in requirements.txt", "uvicorn" in reqs):
                    failures += 1
            elif framework == "django":
                if not check("django in requirements.txt", "django" in reqs):
                    failures += 1
            elif framework == "flask":
                if not check("flask in requirements.txt", "flask" in reqs):
                    failures += 1

            venv_exists = (root / ".venv").exists() or (root / "venv").exists()
            if not check("virtual environment (.venv) exists", venv_exists, "warn"):
                pass

    # ── Go checks ──────────────────────────────────────────────────────────────

    if framework in ("", "gin", "echo"):
        go_mod = root / "go.mod"
        if go_mod.exists():
            print("\nGo")
            mod_content = go_mod.read_text()
            if not check("go.mod exists", True):
                pass
            if not check("module name set in go.mod",
                         env_vars.get("APP_NAME", "") in mod_content, "warn"):
                pass
            go_sum = root / "go.sum"
            if not check("go.sum exists", go_sum.exists(), "warn"):
                pass

    # ── Source structure ───────────────────────────────────────────────────────

    print("\nSource structure")
    src_candidates = [root / "src", root / "app", root / "internal"]
    src_found = any(p.exists() for p in src_candidates)
    if not check("Source directory exists (src/ or app/ or internal/)", src_found):
        failures += 1

    # ── Summary ────────────────────────────────────────────────────────────────

    print("\n" + "─" * 50)
    if failures == 0:
        print(f"\n{PASS} All checks passed.\n")
        return 0
    else:
        print(f"\n{FAIL} {failures} check(s) failed. Fix the issues above.\n")
        return 1


if __name__ == "__main__":
    sys.exit(main())
