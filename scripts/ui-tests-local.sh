#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

mkdir -p TestResults

echo "Running UI tests..."
xcodebuild \
  test \
  -project "SquaredAway.xcodeproj" \
  -scheme "SquaredAway" \
  -only-testing:"SquaredAwayUITests" \
  -resultBundlePath "TestResults/ui-tests.xcresult" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"

echo "Local UI test run complete."
