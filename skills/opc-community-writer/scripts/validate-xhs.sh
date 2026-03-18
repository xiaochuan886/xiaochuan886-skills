#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate a Xiaohongshu draft for the OPC community writer workflow.

Usage:
  validate-xhs.sh --dir /path/to/task
  validate-xhs.sh --xhs /path/to/xhs.md

Options:
  --dir PATH       Task directory containing xhs.md
  --xhs PATH       Explicit xhs.md path
  -h, --help       Show this help
EOF
}

DIR_PATH=""
XHS_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      DIR_PATH="${2:-}"
      shift 2
      ;;
    --xhs)
      XHS_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -n "$DIR_PATH" ] && [ -n "$XHS_PATH" ]; then
  echo "Use either --dir or --xhs, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  XHS_PATH="$DIR_PATH/xhs.md"
fi

if [ -z "$XHS_PATH" ]; then
  usage >&2
  exit 1
fi

if [ ! -f "$XHS_PATH" ]; then
  echo "Missing xhs file: $XHS_PATH" >&2
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

for heading in "## 标题候选" "## 适用人群" "## 开头钩子" "## 正文" "## 标签" "## 软 CTA"; do
  if ! grep -q "^${heading}$" "$XHS_PATH"; then
    error "Missing section: ${heading}"
  fi
done

TITLE_COUNT="$(grep -cE '^[0-9]+\.' "$XHS_PATH" || true)"
if [ "$TITLE_COUNT" -lt 3 ]; then
  error "xhs.md should provide at least 3 title candidates."
fi

CARD_COUNT="$(grep -c '^### 卡片 ' "$XHS_PATH" || true)"
if [ "$CARD_COUNT" -lt 4 ]; then
  warn "xhs.md should usually contain at least 4 content cards."
fi

URL_MATCHES="$(grep -nE 'https?://|www\.' "$XHS_PATH" || true)"
if [ -n "$URL_MATCHES" ]; then
  error "xhs.md must not contain URL references."
  printf '%s\n' "$URL_MATCHES"
fi

BAD_MARKETING="$(grep -nE '稳赚|躺赚|零成本|零风险|包会|包过|保证|加入社群就能|立刻变现|马上接单|必拿补贴' "$XHS_PATH" || true)"
if [ -n "$BAD_MARKETING" ]; then
  error "Found prohibited certainty or income-promise wording."
  printf '%s\n' "$BAD_MARKETING"
fi

HARD_CTA="$(grep -nE '立即加入|立刻报名|限时名额|扫码进群|速来|错过就没了' "$XHS_PATH" || true)"
if [ -n "$HARD_CTA" ]; then
  error "Found hard-sell CTA wording."
  printf '%s\n' "$HARD_CTA"
fi

if grep -Eq '政策|税务|注册|补贴|公司法|个体户|一人有限公司' "$XHS_PATH"; then
  if ! grep -Eq '20[0-9]{2}[-年]' "$XHS_PATH"; then
    warn "Policy or legal topic detected, but no explicit date marker was found."
  fi

  if ! grep -Eq '全国|北京|上海|广州|深圳|杭州|苏州|成都|地区|城市|适用范围' "$XHS_PATH"; then
    warn "Policy or legal topic detected, but no region marker was found."
  fi
fi

printf '\nValidation summary for %s\n' "$XHS_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
