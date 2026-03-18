#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate an OPC community article draft before publishing.

Usage:
  validate-article.sh --dir /path/to/task
  validate-article.sh --article /path/to/article.md
EOF
}

normalize_path() {
  local base_dir="$1"
  local path="$2"

  case "$path" in
    /*) printf '%s\n' "$path" ;;
    ./*) printf '%s\n' "$base_dir/${path#./}" ;;
    *) printf '%s\n' "$base_dir/$path" ;;
  esac
}

DIR_PATH=""
ARTICLE_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      DIR_PATH="${2:-}"
      shift 2
      ;;
    --article)
      ARTICLE_PATH="${2:-}"
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

if [ -n "$DIR_PATH" ] && [ -n "$ARTICLE_PATH" ]; then
  echo "Use either --dir or --article, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  ARTICLE_PATH="$DIR_PATH/article.md"
fi

if [ -z "$ARTICLE_PATH" ] || [ ! -f "$ARTICLE_PATH" ]; then
  echo "Missing article file." >&2
  exit 1
fi

ARTICLE_DIR="$(CDPATH= cd -- "$(dirname -- "$ARTICLE_PATH")" && pwd)"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

awk '
  NR == 1 && $0 == "---" { in_frontmatter = 1; next }
  in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
  !in_frontmatter { print }
' "$ARTICLE_PATH" >"$BODY_FILE"

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

TITLE_VALUE="$(sed -nE 's/^title:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
AUTHOR_VALUE="$(sed -nE 's/^author:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
SUMMARY_VALUE="$(sed -nE 's/^summary:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
COVER_PATH="$(sed -nE 's/^coverImage:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"

if [ -z "$TITLE_VALUE" ] || printf '%s' "$TITLE_VALUE" | grep -q '\[文章标题\]'; then
  error "Missing or placeholder frontmatter title."
fi

if [ -z "$AUTHOR_VALUE" ]; then
  error "Missing frontmatter author."
fi

if [ -z "$SUMMARY_VALUE" ] || printf '%s' "$SUMMARY_VALUE" | grep -q '\[一句话摘要'; then
  warn "Missing frontmatter summary. HTML templates work better when summary is explicit."
fi

if [ -z "$COVER_PATH" ]; then
  error "Missing frontmatter coverImage."
else
  RESOLVED_COVER="$(normalize_path "$ARTICLE_DIR" "$COVER_PATH")"
  if [ ! -f "$RESOLVED_COVER" ]; then
    error "Missing cover image file: $COVER_PATH"
  fi
fi

URL_MATCHES="$(grep -nE 'https?://|www\.' "$ARTICLE_PATH" || true)"
if [ -n "$URL_MATCHES" ]; then
  error "Draft contains URL references."
  printf '%s\n' "$URL_MATCHES"
fi

BAD_WORDS="$(grep -nE '稳赚|零成本|零风险|必拿补贴|加入社群就能|立刻变现|马上接单|包会|保证' "$ARTICLE_PATH" || true)"
if [ -n "$BAD_WORDS" ]; then
  error "Found prohibited certainty or income-promise wording."
  printf '%s\n' "$BAD_WORDS"
fi

HARD_CTA="$(grep -nE '立即加入|立刻报名|限时名额|扫码进群|速来|错过就没了' "$ARTICLE_PATH" || true)"
if [ -n "$HARD_CTA" ]; then
  error "Found hard-sell CTA wording."
  printf '%s\n' "$HARD_CTA"
fi

PERSONALIZED_ADVICE="$(grep -nE '你就该注册成|一定选个体户|一定选一人有限公司|最适合你的税务方案|直接按这个办' "$ARTICLE_PATH" || true)"
if [ -n "$PERSONALIZED_ADVICE" ]; then
  warn "Found wording that may look like personalized legal or tax advice."
  printf '%s\n' "$PERSONALIZED_ADVICE"
fi

BODY_IMAGE_COUNT="$(grep -cE '^[[:space:]]*!\[' "$BODY_FILE" || true)"
if [ "$BODY_IMAGE_COUNT" -lt 2 ]; then
  error "Body must contain at least 2 markdown image references."
fi

BODY_IMAGE_PATHS="$(sed -nE 's/.*!\[[^]]*\]\(([^)]+)\).*/\1/p' "$BODY_FILE" | sed -E 's/^["'"'"']|["'"'"']$//g' | awk 'NF' | sort -u)"
while IFS= read -r image_path; do
  [ -z "$image_path" ] && continue
  resolved_path="$(normalize_path "$ARTICLE_DIR" "$image_path")"
  if [ ! -f "$resolved_path" ]; then
    error "Missing referenced body image file: $image_path"
  fi
done <<EOF
$BODY_IMAGE_PATHS
EOF

CAPTION_COUNT="$(grep -cE '^\*图[0-9一二三四五六七八九十：:]' "$BODY_FILE" || true)"
if [ "$CAPTION_COUNT" -lt "$BODY_IMAGE_COUNT" ]; then
  warn "Some images may be missing standalone captions."
fi

if ! grep -qE '^>[[:space:]].+' "$BODY_FILE"; then
  warn "No summary/insight blockquote found in body. HTML output usually looks better with one opening quote block."
fi

if grep -qE '^<div|^<section|^<table' "$BODY_FILE"; then
  warn "Raw HTML detected. Prefer native Markdown unless there is a clear formatting need."
fi

if ! grep -q '^## 如果你想继续交流$' "$ARTICLE_PATH"; then
  error "Missing soft CTA section heading."
fi

if ! grep -q '^## 📖 参考资料$' "$ARTICLE_PATH"; then
  error "Missing reference section heading."
fi

if grep -Eq '政策|税务|注册|补贴|公司法|个体户|一人有限公司' "$ARTICLE_PATH"; then
  if ! grep -Eq '20[0-9]{2}[-年]' "$ARTICLE_PATH"; then
    warn "Policy or legal topic detected, but no explicit date marker was found."
  fi

  if ! grep -Eq '适用地区：|全国|北京|上海|广州|深圳|杭州|苏州|成都' "$ARTICLE_PATH"; then
    warn "Policy or legal topic detected, but no explicit region marker was found."
  fi
fi

printf '\nValidation summary for %s\n' "$ARTICLE_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
