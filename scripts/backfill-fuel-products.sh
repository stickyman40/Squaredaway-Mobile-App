#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

SUPABASE_URL="${SUPABASE_URL:-https://cwfipabgnufbmclexunm.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3ZmlwYWJnbnVmYm1jbGV4dW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NTQ5NDMsImV4cCI6MjA4ODQzMDk0M30.0i837hYp5GTk9CYIreDC6hI8zKu8KvDjYpCdrjlb3wY}"
FUEL_BATCH_SIZE="${FUEL_BATCH_SIZE:-25}"
FUEL_START_OFFSET="${FUEL_START_OFFSET:-0}"
FUEL_MAX_PRODUCTS="${FUEL_MAX_PRODUCTS:-0}"
FUEL_SLEEP_SECONDS="${FUEL_SLEEP_SECONDS:-0.15}"
FUEL_STALE_DAYS="${FUEL_STALE_DAYS:-}"

REST_URL="${SUPABASE_URL%/}/rest/v1/fuel_products"
FUNCTION_URL="${SUPABASE_URL%/}/functions/v1/barcode-lookup"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for barcode parsing."
  exit 1
fi

stale_cutoff=""
if [ -n "${FUEL_STALE_DAYS}" ]; then
  stale_cutoff="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
import os

days = float(os.environ["FUEL_STALE_DAYS"])
cutoff = datetime.now(timezone.utc) - timedelta(days=days)
print(cutoff.replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"
fi

fetch_page() {
  local offset="$1"
  local -a curl_args=(
    -fsS
    -G
    "${REST_URL}"
    -H "apikey: ${SUPABASE_ANON_KEY}"
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}"
    -H "Accept: application/json"
    --data-urlencode "select=barcode"
    --data-urlencode "order=updated_at.asc"
    --data-urlencode "limit=${FUEL_BATCH_SIZE}"
    --data-urlencode "offset=${offset}"
  )

  if [ -n "${stale_cutoff}" ]; then
    curl_args+=(--data-urlencode "updated_at=lt.${stale_cutoff}")
  fi

  curl "${curl_args[@]}"
}

extract_barcodes() {
  python3 -c 'import json, sys; data = json.load(sys.stdin); [print(row["barcode"]) for row in data if row.get("barcode")]'
}

refresh_barcode() {
  local barcode="$1"
  curl -fsS "${FUNCTION_URL}" \
    -H "Content-Type: application/json" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    --data "{\"barcode\":\"${barcode}\"}" >/dev/null
}

write_summary() {
  local status_line="$1"

  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
      echo "## Fuel Check Refresh"
      echo
      echo "- ${status_line}"
      echo "- Processed: ${processed}"
      echo "- Succeeded: ${successes}"
      echo "- Failed: ${failures}"
      echo "- Batch size: ${FUEL_BATCH_SIZE}"
      echo "- Max products: ${FUEL_MAX_PRODUCTS}"
      if [ -n "${FUEL_STALE_DAYS}" ]; then
        echo "- Stale days: ${FUEL_STALE_DAYS}"
      else
        echo "- Stale days: full sweep"
      fi
    } >> "${GITHUB_STEP_SUMMARY}"
  fi

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo "processed=${processed}"
      echo "successes=${successes}"
      echo "failures=${failures}"
    } >> "${GITHUB_OUTPUT}"
  fi
}

finish_run() {
  local status_line="$1"
  echo "${status_line}"
  echo "Finished with ${successes} successes and ${failures} failures."
  write_summary "${status_line}"
}

offset="${FUEL_START_OFFSET}"
processed=0
successes=0
failures=0

echo "Backfilling Fuel Check products from offset ${offset} in batches of ${FUEL_BATCH_SIZE}..."
if [ -n "${stale_cutoff}" ]; then
  echo "Only refreshing products older than ${stale_cutoff}."
fi

while true; do
  page_json="$(fetch_page "${offset}")"
  barcodes=()
  while IFS= read -r barcode; do
    [ -n "${barcode}" ] && barcodes+=("${barcode}")
  done < <(printf '%s' "${page_json}" | extract_barcodes)

  if [ "${#barcodes[@]}" -eq 0 ]; then
    break
  fi

  for barcode in "${barcodes[@]}"; do
    if [ "${FUEL_MAX_PRODUCTS}" -gt 0 ] && [ "${processed}" -ge "${FUEL_MAX_PRODUCTS}" ]; then
      finish_run "Reached max product limit (${FUEL_MAX_PRODUCTS})."
      exit 0
    fi

    processed=$((processed + 1))
    if refresh_barcode "${barcode}"; then
      successes=$((successes + 1))
      echo "[${processed}] Refreshed ${barcode}"
    else
      failures=$((failures + 1))
      echo "[${processed}] Failed ${barcode}" >&2
    fi

    sleep "${FUEL_SLEEP_SECONDS}"
  done

  offset=$((offset + ${#barcodes[@]}))
done

finish_run "Backfill complete."
