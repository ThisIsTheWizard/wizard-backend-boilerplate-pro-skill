#!/usr/bin/env bash
# check_versions.sh — Query package registries for latest stable versions
# Usage:
#   bash check_versions.sh                   # human-readable output
#   bash check_versions.sh --json            # JSON output
#   bash check_versions.sh --ecosystem node  # Node.js only
#   bash check_versions.sh --ecosystem python
#   bash check_versions.sh --ecosystem go
set -euo pipefail

FORMAT="human"
ECOSYSTEM="all"

while [[ $# -gt 0 ]]; do
  case $1 in
    --json) FORMAT="json" ;;
    --ecosystem) ECOSYSTEM="$2"; shift ;;
    *) ;;
  esac
  shift
done

# ── Helpers ────────────────────────────────────────────────────────────────────

npm_latest() {
  local pkg="$1"
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$pkg', safe='@'))")
  curl -sf "https://registry.npmjs.org/$encoded/latest" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('version','unknown'))" \
    2>/dev/null || echo "unknown"
}

pypi_latest() {
  local pkg="$1"
  curl -sf "https://pypi.org/pypi/$pkg/json" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['info']['version'])" \
    2>/dev/null || echo "unknown"
}

go_latest() {
  local module="$1"
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$module', safe=''))")
  curl -sf "https://proxy.golang.org/$encoded/@latest" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('Version','unknown'))" \
    2>/dev/null || echo "unknown"
}

# ── Node.js packages ──────────────────────────────────────────────────────────

declare -A NODE_PKGS=(
  [express]="express"
  [fastify]="fastify"
  [nestjs_core]="@nestjs/core"
  [hono]="hono"
  [prisma]="prisma"
  [drizzle_orm]="drizzle-orm"
  [typeorm]="typeorm"
  [mongoose]="mongoose"
  [zod]="zod"
  [bcryptjs]="bcryptjs"
  [jose]="jose"
  [bullmq]="bullmq"
  [ioredis]="ioredis"
  [typescript]="typescript"
)

# ── Python packages ───────────────────────────────────────────────────────────

declare -A PY_PKGS=(
  [fastapi]="fastapi"
  [django]="django"
  [flask]="flask"
  [sqlalchemy]="sqlalchemy"
  [pydantic]="pydantic"
  [pydantic_settings]="pydantic-settings"
  [alembic]="alembic"
  [uvicorn]="uvicorn"
  [motor]="motor"
  [passlib]="passlib"
  [python_jose]="python-jose"
  [slowapi]="slowapi"
  [celery]="celery"
  [redis_py]="redis"
)

# ── Go modules ─────────────────────────────────────────────────────────────────

declare -A GO_PKGS=(
  [gin]="github.com/gin-gonic/gin"
  [echo]="github.com/labstack/echo/v4"
  [gorm]="gorm.io/gorm"
  [godotenv]="github.com/joho/godotenv"
  [jwt]="github.com/golang-jwt/jwt/v5"
  [go_redis]="github.com/redis/go-redis/v9"
  [asynq]="github.com/hibiken/asynq"
  [zerolog]="github.com/rs/zerolog"
  [validator]="github.com/go-playground/validator/v10"
)

# ── Fetch versions ──────────────────────────────────────────────────────────────

declare -A RESULTS

fetch_node() {
  for key in "${!NODE_PKGS[@]}"; do
    RESULTS["node_$key"]=$(npm_latest "${NODE_PKGS[$key]}")
  done
}

fetch_python() {
  for key in "${!PY_PKGS[@]}"; do
    RESULTS["py_$key"]=$(pypi_latest "${PY_PKGS[$key]}")
  done
}

fetch_go() {
  for key in "${!GO_PKGS[@]}"; do
    RESULTS["go_$key"]=$(go_latest "${GO_PKGS[$key]}")
  done
}

case $ECOSYSTEM in
  node)   fetch_node ;;
  python) fetch_python ;;
  go)     fetch_go ;;
  all)    fetch_node; fetch_python; fetch_go ;;
esac

# ── Output ─────────────────────────────────────────────────────────────────────

if [[ $FORMAT == "json" ]]; then
  python3 - <<'PYEOF'
import sys, json, os

data = {}
# Read from environment (parent shell exported RESULTS as env vars)
# Fallback: emit placeholder
for k, v in os.environ.items():
    if k.startswith("RESULTS_"):
        data[k[8:].lower()] = v

# Build structured output
out = {"node": {}, "python": {}, "go": {}}
for k, v in data.items():
    if k.startswith("node_"):
        out["node"][k[5:]] = v
    elif k.startswith("py_"):
        out["python"][k[3:]] = v
    elif k.startswith("go_"):
        out["go"][k[3:]] = v

print(json.dumps(out, indent=2))
PYEOF
else
  echo "=== Node.js packages ==="
  for key in "${!RESULTS[@]}"; do
    [[ $key == node_* ]] && printf "  %-20s %s\n" "${key#node_}" "${RESULTS[$key]}"
  done | sort

  echo ""
  echo "=== Python packages ==="
  for key in "${!RESULTS[@]}"; do
    [[ $key == py_* ]] && printf "  %-20s %s\n" "${key#py_}" "${RESULTS[$key]}"
  done | sort

  echo ""
  echo "=== Go modules ==="
  for key in "${!RESULTS[@]}"; do
    [[ $key == go_* ]] && printf "  %-20s %s\n" "${key#go_}" "${RESULTS[$key]}"
  done | sort
fi
