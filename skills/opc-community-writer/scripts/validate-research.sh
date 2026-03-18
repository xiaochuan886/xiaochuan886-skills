#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate research.md structure for the OPC community writer workflow.

Usage:
  validate-research.sh --dir /path/to/task
  validate-research.sh --research /path/to/research.md
EOF
}

DIR_PATH=""
RESEARCH_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      DIR_PATH="${2:-}"
      shift 2
      ;;
    --research)
      RESEARCH_PATH="${2:-}"
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

if [ -n "$DIR_PATH" ] && [ -n "$RESEARCH_PATH" ]; then
  echo "Use either --dir or --research, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  RESEARCH_PATH="$DIR_PATH/research.md"
fi

if [ -z "$RESEARCH_PATH" ] || [ ! -f "$RESEARCH_PATH" ]; then
  echo "Missing research file." >&2
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

for section in "## Topic" "## 政策法规" "## 办事路径" "## 法律边界" "## 创业案例" "## 平台内容观察"; do
  if ! grep -q "^${section}$" "$RESEARCH_PATH"; then
    error "Missing section: ${section}"
  fi
done

DATE_COUNT="$(grep -c '发布时间:' "$RESEARCH_PATH" || true)"
REGION_COUNT="$(grep -cE '适用地区:|地区:' "$RESEARCH_PATH" || true)"
URL_COUNT="$(grep -c 'URL:' "$RESEARCH_PATH" || true)"

if [ "$DATE_COUNT" -lt 3 ]; then
  warn "research.md should usually record multiple publish dates."
fi

if [ "$REGION_COUNT" -lt 3 ]; then
  warn "research.md should usually record multiple region fields."
fi

if [ "$URL_COUNT" -lt 3 ]; then
  error "research.md should record multiple source URLs."
fi

if ! grep -q 'Source type: 官方' "$RESEARCH_PATH"; then
  error "At least one official source should be recorded."
fi

if ! grep -q 'Source type: 创业案例' "$RESEARCH_PATH" && ! grep -q 'Source type: 创业案例 / 媒体报道' "$RESEARCH_PATH"; then
  warn "No case source marker was found."
fi

printf '\nValidation summary for %s\n' "$RESEARCH_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
