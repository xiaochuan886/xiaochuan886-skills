#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate images-plan.md for the OPC community writer workflow.

Usage:
  validate-images-plan.sh --dir /path/to/task
  validate-images-plan.sh --plan /path/to/images-plan.md
EOF
}

DIR_PATH=""
PLAN_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      DIR_PATH="${2:-}"
      shift 2
      ;;
    --plan)
      PLAN_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -n "$DIR_PATH" ] && [ -n "$PLAN_PATH" ]; then
  echo "Use either --dir or --plan, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  PLAN_PATH="$DIR_PATH/images-plan.md"
fi

if [ -z "$PLAN_PATH" ] || [ ! -f "$PLAN_PATH" ]; then
  echo "Missing images plan file." >&2
  exit 1
fi

ERRORS=0
WARNINGS=0

error() {
  printf 'ERROR: %s\n' "$1"
  ERRORS=$((ERRORS + 1))
}

warn() {
  printf 'WARN: %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

if ! grep -q '^- language: zh-CN$' "$PLAN_PATH"; then
  error "Global language must be zh-CN."
fi

if ! grep -q '简体中文' "$PLAN_PATH"; then
  error "images-plan.md must explicitly require Simplified Chinese."
fi

IMAGE_COUNT="$(grep -c '^## Image ' "$PLAN_PATH" || true)"
if [ "$IMAGE_COUNT" -lt 4 ]; then
  error "images-plan.md should contain at least 4 image blocks."
fi

if grep -qE 'ratio:[[:space:]]*16:9' "$PLAN_PATH"; then
  error "16:9 is not allowed for this workflow."
fi

if ! grep -q 'recommended_skill: baoyu-cover-image' "$PLAN_PATH"; then
  error "At least one cover image should route to baoyu-cover-image."
fi

if ! grep -q 'baoyu-article-illustrator' "$PLAN_PATH"; then
  error "At least one inline image should route to baoyu-article-illustrator."
fi

if ! grep -q 'xhs-series' "$PLAN_PATH"; then
  warn "No Xiaohongshu image block was found."
fi

if ! grep -q 'recommended_skill: baoyu-xhs-images' "$PLAN_PATH"; then
  warn "Xiaohongshu image block should route to baoyu-xhs-images."
fi

printf '\nValidation summary for %s\n' "$PLAN_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
