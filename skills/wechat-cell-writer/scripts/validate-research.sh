#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate research.md structure for the WeChat cell writer workflow.

Usage:
  validate-research.sh --dir /path/to/task
  validate-research.sh --research /path/to/research.md

Options:
  --dir PATH          Task directory containing research.md
  --research PATH     Explicit research.md path
  -h, --help          Show this help
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
      if [ -z "$RESEARCH_PATH" ] && [ -z "$DIR_PATH" ]; then
        RESEARCH_PATH="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [ -n "$DIR_PATH" ] && [ -n "$RESEARCH_PATH" ]; then
  echo "Use either --dir or --research, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  RESEARCH_PATH="$DIR_PATH/research.md"
elif [ -d "${RESEARCH_PATH:-}" ]; then
  RESEARCH_PATH="$RESEARCH_PATH/research.md"
fi

if [ -z "${RESEARCH_PATH:-}" ]; then
  usage >&2
  exit 1
fi

if [ ! -f "$RESEARCH_PATH" ]; then
  echo "Missing research file: $RESEARCH_PATH" >&2
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

if ! grep -q '^# Research Notes' "$RESEARCH_PATH"; then
  warn "research.md does not use the expected scaffold heading."
fi

for section in "## Topic" "## Academic Papers" "## Medical Media" "## Competitor Content" "## Policy Updates"; do
  if ! grep -q "^${section}$" "$RESEARCH_PATH"; then
    error "Missing section: ${section}"
  fi
done

DOI_COUNT="$(grep -cE 'DOI:[[:space:]]*[^[:space:]]+' "$RESEARCH_PATH" || true)"
PMID_COUNT="$(grep -cE 'PMID:[[:space:]]*[^[:space:]]+' "$RESEARCH_PATH" || true)"
URL_COUNT="$(grep -cE 'URL:[[:space:]]*https?://' "$RESEARCH_PATH" || true)"
PRIORITY_COUNT="$(grep -cE 'Screenshot priority:[[:space:]]*(High|Medium|Low)' "$RESEARCH_PATH" || true)"

if [ "$DOI_COUNT" -lt 1 ] && [ "$PMID_COUNT" -lt 1 ]; then
  error "research.md should record at least one DOI or PMID for paper-backed topics."
fi

if [ "$URL_COUNT" -lt 1 ]; then
  warn "No URL markers found in research.md. Source traceability may be weak."
fi

if [ "$PRIORITY_COUNT" -lt 1 ]; then
  error "Missing 'Screenshot priority:' markers for core paper selection."
fi

HIGH_PRIORITY_COUNT="$(grep -cE 'Screenshot priority:[[:space:]]*High([[:space:]]|$)' "$RESEARCH_PATH" || true)"
if [ "$HIGH_PRIORITY_COUNT" -lt 1 ]; then
  warn "No high-priority paper marked for screenshot capture."
fi

if [ "$HIGH_PRIORITY_COUNT" -gt 2 ]; then
  error "High-priority papers should be limited to 1-2 core entries."
fi

MEDIA_COUNT="$(grep -c '^## Medical Media$' "$RESEARCH_PATH" || true)"
COMPETITOR_COUNT="$(grep -c '^## Competitor Content$' "$RESEARCH_PATH" || true)"
POLICY_COUNT="$(grep -c '^## Policy Updates$' "$RESEARCH_PATH" || true)"

if [ "$MEDIA_COUNT" -lt 1 ]; then
  warn "No medical media section found."
fi

if [ "$COMPETITOR_COUNT" -lt 1 ]; then
  warn "No competitor content section found."
fi

if [ "$POLICY_COUNT" -lt 1 ]; then
  warn "No policy updates section found."
fi

printf '\nValidation summary for %s\n' "$RESEARCH_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
