#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

mkdir -p TestResults

echo "Running preflight checks..."
./scripts/preflight-check.sh

echo "Building app..."
xcodebuild \
  -project "SquaredAway.xcodeproj" \
  -scheme "SquaredAway" \
  -destination "generic/platform=iOS Simulator" \
  build

echo "Running unit tests..."
xcodebuild \
  test \
  -project "SquaredAway.xcodeproj" \
  -scheme "SquaredAway" \
  -only-testing:"SquaredAwayTests" \
  -resultBundlePath "TestResults/unit-tests.xcresult" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"

echo "Local CI run complete."
