#!/usr/bin/env bash
# detect_package_manager.sh — Detect the Node.js package manager in use
# Usage: bash detect_package_manager.sh
# Output: prints one of: bun | pnpm | yarn | npm
# Exit code: always 0 (defaults to npm)

# 1. Check for lockfiles in the current directory
if [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
  echo "bun"
  exit 0
fi

if [[ -f "pnpm-lock.yaml" ]]; then
  echo "pnpm"
  exit 0
fi

if [[ -f "yarn.lock" ]]; then
  echo "yarn"
  exit 0
fi

if [[ -f "package-lock.json" ]]; then
  echo "npm"
  exit 0
fi

# 2. Check packageManager field in package.json
if [[ -f "package.json" ]]; then
  PM_FIELD=$(python3 -c "
import json, sys
try:
    data = json.load(open('package.json'))
    pm = data.get('packageManager', '')
    if pm.startswith('bun@'):   print('bun')
    elif pm.startswith('pnpm@'): print('pnpm')
    elif pm.startswith('yarn@'): print('yarn')
    elif pm.startswith('npm@'):  print('npm')
except Exception:
    pass
" 2>/dev/null)
  if [[ -n "$PM_FIELD" ]]; then
    echo "$PM_FIELD"
    exit 0
  fi
fi

# 3. Check PATH availability (prefer bun > pnpm > yarn > npm)
if command -v bun &>/dev/null; then
  echo "bun"
  exit 0
fi

if command -v pnpm &>/dev/null; then
  echo "pnpm"
  exit 0
fi

if command -v yarn &>/dev/null; then
  echo "yarn"
  exit 0
fi

# 4. Default fallback
echo "npm"
exit 0
