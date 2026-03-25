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

if [ ! -f "${REPO_ROOT}/supabase/config.toml" ]; then
  echo "Missing supabase/config.toml. Run the following first:"
  echo "  supabase init"
  echo "  supabase login"
  echo "  supabase link --project-ref <your-project-ref>"
  exit 1
fi

echo "Pushing local migrations to the linked Supabase project..."
supabase db push "$@"

echo "Remote Supabase push complete."
