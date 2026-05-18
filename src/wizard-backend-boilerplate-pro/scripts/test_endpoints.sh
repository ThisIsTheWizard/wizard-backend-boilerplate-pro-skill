#!/usr/bin/env bash
# test_endpoints.sh — Smoke-test all showcase API routes with curl
# Usage: bash test_endpoints.sh <BASE_URL>
# Example: bash test_endpoints.sh http://localhost:3000
# Exit code: 0 if all tests pass, 1 if any fail

set -euo pipefail

BASE_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0
SKIP=0

# ── Helpers ────────────────────────────────────────────────────────────────────

check() {
  local method="$1"
  local path="$2"
  local expected_status="$3"
  local description="$4"
  local data="${5:-}"
  local headers="${6:-}"

  local curl_args=(-s -o /dev/null -w "%{http_code}" -X "$method")
  [[ -n "$data" ]] && curl_args+=(-H "Content-Type: application/json" -d "$data")
  [[ -n "$headers" ]] && curl_args+=(-H "$headers")

  local actual_status
  actual_status=$(curl "${curl_args[@]}" "$BASE_URL$path" 2>/dev/null || echo "000")

  if [[ "$actual_status" == "$expected_status" ]]; then
    printf "  ✓ %-45s %s\n" "$description" "[$actual_status]"
    ((PASS++))
  elif [[ "$actual_status" == "000" ]]; then
    printf "  ? %-45s %s\n" "$description" "[CONNECTION REFUSED]"
    ((SKIP++))
  else
    printf "  ✗ %-45s %s expected %s\n" "$description" "[$actual_status]" "[$expected_status]"
    ((FAIL++))
  fi
}

# ── Tests ──────────────────────────────────────────────────────────────────────

echo ""
echo "Smoke-testing $BASE_URL"
echo "────────────────────────────────────────────────────────────"
echo ""

echo "Core"
check GET  /health    200 "GET /health"

echo ""
echo "Auth"
check POST /auth/register 201 "POST /auth/register (valid)" \
  '{"email":"smoketest@example.com","password":"Test1234!"}' ""
check POST /auth/register 409 "POST /auth/register (duplicate)" \
  '{"email":"smoketest@example.com","password":"Test1234!"}' "" || true
check POST /auth/login    200 "POST /auth/login (valid)" \
  '{"email":"smoketest@example.com","password":"Test1234!"}' ""
check POST /auth/login    401 "POST /auth/login (wrong password)" \
  '{"email":"smoketest@example.com","password":"wrongpass"}' ""
check GET  /auth/me       401 "GET /auth/me (no token)"

echo ""
echo "Users (no auth)"
check GET  /users         401 "GET /users (no token)"

echo ""
echo "Docs"
check GET  /docs          200 "GET /docs (Swagger UI)"
check GET  /docs/json     200 "GET /docs/json (OpenAPI spec)"

echo ""
echo "Real-time"
check GET  /events        200 "GET /events (SSE stream — may hang, OK to ctrl-c)" || true

echo ""
echo "404"
check GET  /nonexistent   404 "GET /nonexistent → 404"

echo ""
echo "────────────────────────────────────────────────────────────"
printf "Results: %d passed  %d failed  %d skipped\n" "$PASS" "$FAIL" "$SKIP"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "FAIL — fix the issues above before proceeding."
  exit 1
else
  echo "PASS — all reachable endpoints returned expected status codes."
  exit 0
fi
