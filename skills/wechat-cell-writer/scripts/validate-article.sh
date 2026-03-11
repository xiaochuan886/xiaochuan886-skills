#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate a WeChat article draft before publishing.

Usage:
  validate-article.sh --dir /path/to/task
  validate-article.sh /path/to/task/article.md

Options:
  --dir PATH       Task directory containing article.md
  --article PATH   Explicit article.md path
  -h, --help       Show this help
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
      if [ -z "$ARTICLE_PATH" ] && [ -z "$DIR_PATH" ]; then
        ARTICLE_PATH="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [ -n "$DIR_PATH" ] && [ -n "$ARTICLE_PATH" ]; then
  echo "Use either --dir or --article, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  ARTICLE_PATH="$DIR_PATH/article.md"
elif [ -d "$ARTICLE_PATH" ]; then
  ARTICLE_PATH="$ARTICLE_PATH/article.md"
fi

if [ -z "$ARTICLE_PATH" ]; then
  usage >&2
  exit 1
fi

if [ ! -f "$ARTICLE_PATH" ]; then
  echo "Missing article file: $ARTICLE_PATH" >&2
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

report_matches() {
  local label="$1"
  local matches="$2"
  if [ -n "$matches" ]; then
    printf '%s\n' "$label"
    printf '%s\n' "$matches"
  fi
}

TITLE_VALUE="$(sed -nE 's/^title:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
AUTHOR_VALUE="$(sed -nE 's/^author:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
COVER_PATH="$(sed -nE 's/^coverImage:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"

if [ -z "$TITLE_VALUE" ]; then
  error "Missing frontmatter title."
elif printf '%s' "$TITLE_VALUE" | grep -q '\[文章标题\]'; then
  warn "Frontmatter title still uses placeholder text."
fi

if [ -z "$AUTHOR_VALUE" ]; then
  error "Missing frontmatter author."
elif [ "$AUTHOR_VALUE" != "细胞小境" ]; then
  error "Frontmatter author must be fixed to 细胞小境."
fi

TITLE_LENGTH="$(printf '%s' "$TITLE_VALUE" | awk '{print length}')"
if [ -n "$TITLE_VALUE" ] && { [ "$TITLE_LENGTH" -lt 15 ] || [ "$TITLE_LENGTH" -gt 30 ]; }; then
  warn "Title length is outside the recommended 15-30 character range."
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
  error "Draft contains URL references. Remove all URLs from article.md."
  printf '%s\n' "$URL_MATCHES"
fi

ABSOLUTE_MATCHES="$(grep -nE '100%|彻底|完全|必定|一定|唯一' "$ARTICLE_PATH" || true)"
if [ -n "$ABSOLUTE_MATCHES" ]; then
  error "Found prohibited absolute claims."
  report_matches "Absolute claim matches:" "$ABSOLUTE_MATCHES"
fi

EXAGGERATED_MATCHES="$(grep -nE '根治|治愈|神药|奇迹|特效|包治' "$ARTICLE_PATH" || true)"
if [ -n "$EXAGGERATED_MATCHES" ]; then
  error "Found exaggerated efficacy wording."
  report_matches "Exaggerated wording matches:" "$EXAGGERATED_MATCHES"
fi

CLICKBAIT_MATCHES="$(grep -nE '震惊|必看|删除前速看|疯传|看完泪奔' "$ARTICLE_PATH" || true)"
if [ -n "$CLICKBAIT_MATCHES" ]; then
  error "Found clickbait wording."
  report_matches "Clickbait wording matches:" "$CLICKBAIT_MATCHES"
fi

FEAR_MATCHES="$(grep -nE '不存后悔|错过没机会|等死|救命|必须存' "$ARTICLE_PATH" || true)"
if [ -n "$FEAR_MATCHES" ]; then
  error "Found fear-based marketing wording."
  report_matches "Fear-based wording matches:" "$FEAR_MATCHES"
fi

MEDICAL_AD_MATCHES="$(grep -nE '价格|费用|优惠|套餐|咨询热线|扫码|联系客服' "$ARTICLE_PATH" || true)"
if [ -n "$MEDICAL_AD_MATCHES" ]; then
  warn "Found wording that may look like promotional or medical advertising."
  report_matches "Promotional wording matches:" "$MEDICAL_AD_MATCHES"
fi

BODY_IMAGE_COUNT="$(grep -cE '^[[:space:]]*!\[' "$BODY_FILE" || true)"
if [ "$BODY_IMAGE_COUNT" -lt 2 ]; then
  error "Body must contain at least 2 markdown image references."
fi

BODY_IMAGE_PATHS="$(sed -nE 's/.*!\[[^]]*\]\(([^)]+)\).*/\1/p' "$BODY_FILE" | sed -E 's/^["'"'"']|["'"'"']$//g' | awk 'NF' | sort -u)"
if [ -z "$BODY_IMAGE_PATHS" ]; then
  error "No body image paths were found."
fi

while IFS= read -r image_path; do
  [ -z "$image_path" ] && continue
  resolved_path="$(normalize_path "$ARTICLE_DIR" "$image_path")"
  if [ ! -f "$resolved_path" ]; then
    error "Missing referenced body image file: $image_path"
  fi
done <<EOF
$BODY_IMAGE_PATHS
EOF

PAPER_SIGNAL=0
if grep -Eq 'DOI:|PMID|《(Nature|Cell|Science|Lancet|NEJM|JAMA|Nature Medicine|Nature Aging|Nature Biotechnology)》' "$ARTICLE_PATH"; then
  PAPER_SIGNAL=1
fi

PAPER_IMAGE_PATHS="$(printf '%s\n' "$BODY_IMAGE_PATHS" | grep 'paper-' || true)"
PAPER_IMAGE_COUNT="$(printf '%s\n' "$PAPER_IMAGE_PATHS" | awk 'NF' | wc -l | tr -d ' ')"

if [ "$PAPER_SIGNAL" -eq 1 ] && [ "$PAPER_IMAGE_COUNT" -lt 1 ]; then
  error "Paper citations detected, but no paper screenshot is embedded in the article body."
fi

if [ "$PAPER_IMAGE_COUNT" -gt 2 ]; then
  error "Paper screenshots should be limited to 1-2 core papers."
fi

if [ "$PAPER_SIGNAL" -eq 1 ]; then
  while IFS= read -r paper_path; do
    [ -z "$paper_path" ] && continue
    resolved_path="$(normalize_path "$ARTICLE_DIR" "$paper_path")"
    if [ ! -f "$resolved_path" ]; then
      error "Missing paper screenshot file: $paper_path"
    fi
  done <<EOF
$PAPER_IMAGE_PATHS
EOF
fi

REFERENCE_SECTION_COUNT="$(grep -c '^## 📖 参考资料' "$ARTICLE_PATH" || true)"
if [ "$REFERENCE_SECTION_COUNT" -lt 1 ]; then
  warn "Missing reference section heading: ## 📖 参考资料"
fi

DOI_COUNT="$(grep -c 'DOI:' "$ARTICLE_PATH" || true)"
if [ "$PAPER_SIGNAL" -eq 1 ] && [ "$DOI_COUNT" -lt 1 ]; then
  warn "Paper-oriented draft detected but no DOI marker was found in article.md."
fi

DISCLAIMER_COUNT="$(grep -c '本文仅供科普参考，不构成医疗建议' "$ARTICLE_PATH" || true)"
if grep -Eq '癌症|肿瘤|治疗|疗法|临床试验' "$ARTICLE_PATH"; then
  if [ "$DISCLAIMER_COUNT" -lt 1 ]; then
    warn "Medical topic detected. Consider adding the standard disclaimer."
  fi
fi

printf '\nValidation summary for %s\n' "$ARTICLE_PATH"
printf 'Errors: %s\n' "$ERRORS"
printf 'Warnings: %s\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
