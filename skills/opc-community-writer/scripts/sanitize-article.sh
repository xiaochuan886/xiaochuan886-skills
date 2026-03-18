#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Create a publish-safe article draft with URLs removed.

Usage:
  sanitize-article.sh --dir /path/to/task
  sanitize-article.sh --article /path/to/article.md [--output /path/to/article.publish.md]

Options:
  --dir PATH         Task directory containing article.md
  --article PATH     Explicit article.md path
  --output PATH      Output file path
  --in-place         Replace the source article instead of writing a sibling file
  -h, --help         Show this help
EOF
}

DIR_PATH=""
ARTICLE_PATH=""
OUTPUT_PATH=""
IN_PLACE=0

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
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --in-place)
      IN_PLACE=1
      shift
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

if [ -n "$DIR_PATH" ] && [ -n "$ARTICLE_PATH" ]; then
  echo "Use either --dir or --article, not both." >&2
  exit 1
fi

if [ -n "$DIR_PATH" ]; then
  ARTICLE_PATH="$DIR_PATH/article.md"
fi

if [ -z "$ARTICLE_PATH" ]; then
  usage >&2
  exit 1
fi

if [ ! -f "$ARTICLE_PATH" ]; then
  echo "Missing article file: $ARTICLE_PATH" >&2
  exit 1
fi

if [ "$IN_PLACE" -eq 1 ] && [ -n "$OUTPUT_PATH" ]; then
  echo "--in-place cannot be used with --output." >&2
  exit 1
fi

ARTICLE_DIR="$(CDPATH= cd -- "$(dirname -- "$ARTICLE_PATH")" && pwd)"
ARTICLE_NAME="$(basename -- "$ARTICLE_PATH")"
ARTICLE_STEM="${ARTICLE_NAME%.md}"

if [ "$IN_PLACE" -eq 1 ]; then
  OUTPUT_PATH="$ARTICLE_PATH"
elif [ -z "$OUTPUT_PATH" ]; then
  OUTPUT_PATH="$ARTICLE_DIR/${ARTICLE_STEM}.publish.md"
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

sed -E \
  -e 's#https?://[^[:space:])>]+##g' \
  -e 's#www\.[^[:space:])>]+##g' \
  -e 's/[[:space:]]+\)$//g' \
  -e 's/[[:space:]]{2,}/ /g' \
  "$ARTICLE_PATH" >"$TMP_FILE"

python3 - "$TMP_FILE" "$OUTPUT_PATH" <<'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text()

lines = []
for raw_line in text.splitlines():
    line = raw_line.rstrip()
    line = re.sub(r'\(\s*\)', '', line)
    line = re.sub(r'来源：\s*$', '来源：待补充', line)
    line = re.sub(r'URL:\s*$', 'URL: [仅 research.md 保留]', line)
    line = re.sub(r'\s{2,}', ' ', line).rstrip()
    lines.append(line)

sanitized = "\n".join(lines).strip() + "\n"
dst.write_text(sanitized)
PY

echo "Sanitized article written to: $OUTPUT_PATH"
