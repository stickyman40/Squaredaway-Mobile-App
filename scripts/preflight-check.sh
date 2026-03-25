#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  echo "[PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo "[WARN] $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local path="$1"
  if [ -e "${path}" ]; then
    pass "Found ${path}"
  else
    fail "Missing ${path}"
  fi
}

check_executable() {
  local path="$1"
  if [ -x "${path}" ]; then
    pass "Executable ${path}"
  elif [ -e "${path}" ]; then
    fail "Not executable ${path}"
  else
    fail "Missing ${path}"
  fi
}

echo "Running SquaredAway preflight checks..."
echo

check_file "README.md"
check_file ".env.example"
check_file "SquaredAway.xcodeproj"
check_file "supabase_schema.sql"
check_file "supabase/README.md"
check_file "docs/release-checklist.md"
check_file "supabase/migrations/20260323120000_initial_schema.sql"

check_executable "scripts/supabase-reset-local.sh"
check_executable "scripts/supabase-push-remote.sh"

if [ -x "scripts/preflight-check.sh" ]; then
  pass "Executable scripts/preflight-check.sh"
else
  warn "scripts/preflight-check.sh is not executable yet"
fi

if command -v supabase >/dev/null 2>&1; then
  pass "Supabase CLI available"
else
  warn "Supabase CLI not installed"
fi

if [ -f "supabase/config.toml" ]; then
  pass "Found supabase/config.toml"
else
  warn "Missing supabase/config.toml"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pass "Git repository detected"

  if git diff --quiet && git diff --cached --quiet; then
    pass "No staged or unstaged tracked changes"
  else
    warn "Tracked git changes are present"
  fi

  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    warn "Untracked files are present"
  else
    pass "No untracked files"
  fi
else
  warn "Not running inside a git repository"
fi

echo
echo "Summary: ${PASS_COUNT} passed, ${WARN_COUNT} warnings, ${FAIL_COUNT} failed"

if [ "${FAIL_COUNT}" -gt 0 ]; then
  exit 1
fi
