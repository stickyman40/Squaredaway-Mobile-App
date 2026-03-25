#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is not installed. Install it first with:"
  echo "  brew install supabase/tap/supabase"
  exit 1
fi

if [ ! -d "${REPO_ROOT}/supabase" ]; then
  echo "Expected supabase directory at ${REPO_ROOT}/supabase"
  exit 1
fi

echo "Starting local Supabase services..."
supabase start

echo "Resetting local database from migrations..."
supabase db reset

echo "Local Supabase reset complete."
