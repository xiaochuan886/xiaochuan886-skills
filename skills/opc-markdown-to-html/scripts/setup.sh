#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v bun >/dev/null 2>&1; then
  bun install --cwd "$SCRIPT_DIR"
elif command -v npx >/dev/null 2>&1; then
  (cd "$SCRIPT_DIR" && npx -y bun install)
else
  echo "Need bun or npx to install dependencies." >&2
  exit 1
fi
