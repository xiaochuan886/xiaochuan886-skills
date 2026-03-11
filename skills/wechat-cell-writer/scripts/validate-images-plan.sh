#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate images-plan.md for the WeChat cell writer workflow.

Usage:
  validate-images-plan.sh --dir /path/to/task
  validate-images-plan.sh --plan /path/to/images-plan.md

Options:
  --dir PATH       Task directory containing images-plan.md
  --plan PATH      Explicit images-plan.md path
  -h, --help       Show this help
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
      if [ -z "$PLAN_PATH" ] && [ -z "$DIR_PATH" ]; then
        PLAN_PATH="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [ -n "$DIR_PATH" ] && [ -n "$PLAN_PATH" ]; then
  echo "Use either --dir or --plan, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  PLAN_PATH="$DIR_PATH/images-plan.md"
elif [ -d "${PLAN_PATH:-}" ]; then
  PLAN_PATH="$PLAN_PATH/images-plan.md"
fi

if [ -z "${PLAN_PATH:-}" ]; then
  usage >&2
  exit 1
fi

if [ ! -f "$PLAN_PATH" ]; then
  echo "Missing images plan file: $PLAN_PATH" >&2
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

extract_value() {
  local key="$1"
  sed -nE "s/^- ${key}:[[:space:]]*(.+)$/\1/p" "$PLAN_PATH" | head -n 1
}

GLOBAL_LANGUAGE="$(extract_value "language")"
GLOBAL_TEXT_POLICY="$(extract_value "text_policy")"
GLOBAL_ENGLISH_ALLOWED="$(extract_value "english_allowed")"
GLOBAL_ABBR_POLICY="$(extract_value "abbreviation_policy")"

if [ "$GLOBAL_LANGUAGE" != "zh-CN" ]; then
  error "Global language must be zh-CN."
fi

if ! printf '%s' "$GLOBAL_TEXT_POLICY" | grep -q '简体中文'; then
  error "Global text_policy must require Simplified Chinese."
fi

if [ "$GLOBAL_ENGLISH_ALLOWED" != "abbreviations-only" ]; then
  error "english_allowed must be abbreviations-only for this skill."
fi

if ! printf '%s' "$GLOBAL_ABBR_POLICY" | grep -Eq 'CAR-T|NK|TIL'; then
  warn "abbreviation_policy should mention allowed domain abbreviations such as CAR-T, NK, TIL."
fi

IMAGE_COUNT="$(grep -c '^## Image ' "$PLAN_PATH" || true)"
if [ "$IMAGE_COUNT" -lt 4 ]; then
  error "images-plan.md should contain at least 4 image blocks."
fi

if grep -qE 'ratio:[[:space:]]*16:9' "$PLAN_PATH"; then
  error "16:9 is not allowed for reader-facing generated images."
fi

if ! grep -q 'recommended_skill: baoyu-cover-image' "$PLAN_PATH"; then
  error "Cover image should route to baoyu-cover-image."
fi

if ! grep -qE 'recommended_skill: baoyu-article-illustrator' "$PLAN_PATH"; then
  error "At least one inline image should route to baoyu-article-illustrator."
fi

if ! grep -qE 'recommended_skill: .*baoyu-infographic|recommended_skill: baoyu-article-illustrator 或 baoyu-infographic' "$PLAN_PATH"; then
  warn "No data-heavy image appears to route to baoyu-infographic."
fi

if ! grep -q 'recommended_skill: wechat-cell-writer screenshot-paper.ts' "$PLAN_PATH"; then
  error "Paper screenshot block should route to screenshot-paper.ts."
fi

LANGUAGE_REQUIREMENT_LINES="$(grep -n 'language_requirement:' "$PLAN_PATH" || true)"
if [ -z "$LANGUAGE_REQUIREMENT_LINES" ]; then
  error "Each image block should include a language_requirement."
fi

NON_CHINESE_REQUIREMENTS="$(grep -n 'language_requirement:' "$PLAN_PATH" | grep -vE '简体中文|原始论文页面内容|专业缩写可保留' || true)"
if [ -n "$NON_CHINESE_REQUIREMENTS" ]; then
  error "All non-paper image language requirements must explicitly require Simplified Chinese as core text."
  printf '%s\n' "$NON_CHINESE_REQUIREMENTS"
fi

FINAL_PROMPT_PENDING_COUNT="$(grep -c 'final_prompt: \[待生成\]' "$PLAN_PATH" || true)"
if [ "$FINAL_PROMPT_PENDING_COUNT" -ge 1 ]; then
  warn "Some final_prompt fields are still pending."
fi

FILLED_PROMPTS="$(grep -nE '^- final_prompt:[[:space:]]*(.+)$' "$PLAN_PATH" | grep -v '\[待生成\]' | grep -v '\[不适用\]' || true)"
if [ -n "$FILLED_PROMPTS" ]; then
  BAD_PROMPTS="$(printf '%s\n' "$FILLED_PROMPTS" | grep -viE '中文|简体中文|Simplified Chinese|专业缩写|abbreviation' || true)"
  if [ -n "$BAD_PROMPTS" ]; then
    error "Filled final_prompt entries must explicitly require Chinese core text and may optionally allow domain abbreviations."
    printf '%s\n' "$BAD_PROMPTS"
  fi
fi

printf '\nValidation summary for %s\n' "$PLAN_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
