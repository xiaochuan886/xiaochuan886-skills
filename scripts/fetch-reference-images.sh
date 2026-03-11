#!/usr/bin/env bash
set -euo pipefail

# Fetch safe reference images (Wikimedia Commons) with license filtering.
# Requires: ~/.agents/skills/wechat-safe-science-images

usage() {
  cat <<'EOF'
Usage:
  fetch-reference-images.sh --dir <ARTICLE_DIR> [--query "keyword"] [--limit 3]

Notes:
- Downloads images into: <ARTICLE_DIR>/imgs/refs/
- Writes audit manifest (may contain URLs): <ARTICLE_DIR>/imgs/refs/image-manifest.json
- Writes per-image captions (NO URLs): <ARTICLE_DIR>/image-captions.md
EOF
}

DIR=""
QUERY=""
LIMIT=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --query) QUERY="$2"; shift 2;;
    --limit) LIMIT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$DIR" ]]; then echo "--dir required"; usage; exit 1; fi
DIR=$(cd "$DIR" && pwd)

ARTICLE_MD="$DIR/article.md"
if [[ -z "$QUERY" ]]; then
  if [[ -f "$ARTICLE_MD" ]]; then
    # Try infer from frontmatter title, fall back to 'cell therapy'
    TITLE=$(perl -0777 -ne 'if(/\n---\n/){$x=$_; $x=~s/^---\n.*?\n---\n//s;}; if(/^title:\s*(.+)$/m){print $1}' "$ARTICLE_MD" 2>/dev/null || true)
    if [[ -z "$TITLE" ]]; then
      TITLE=$(grep -E '^title:' "$ARTICLE_MD" | head -n 1 | sed 's/^title:\s*//')
    fi
    QUERY="$TITLE"
  else
    QUERY="cell therapy"
  fi
fi

OUT="$DIR/imgs/refs"
mkdir -p "$OUT"

FETCHER="$HOME/.agents/skills/wechat-safe-science-images/scripts/commons_fetch.mjs"
if [[ ! -f "$FETCHER" ]]; then
  echo "Missing fetcher: $FETCHER" >&2
  exit 2
fi

node "$FETCHER" --query "$QUERY" --out "$OUT" --limit "$LIMIT" --min-width 800

# Generate per-image captions (NO URLs) and keep full audit trail in manifest
MANIFEST="$OUT/image-manifest.json"
CAPTIONS="$DIR/image-captions.md"
node - "$MANIFEST" "$CAPTIONS" <<'NODE'
const fs=require('fs');
const manifestPath=process.argv[2];
const outPath=process.argv[3];
const data=JSON.parse(fs.readFileSync(manifestPath,'utf8'));
const lines=[];
lines.push('# Image Captions (NO URLs)');
lines.push('');
lines.push('Usage: place the matching caption directly under each image in article.md.');
lines.push('');
for(const img of (data.images||[])){
  const lic=(img.license_short_name||'').replace(/\s+/g,' ').trim() || 'CC';
  // commons is default allowlist
  // keep it minimal for readers; no links
  lines.push(`- ${img.filename}: *图源：Wikimedia Commons（公开许可素材，${lic}）。*`);
}
fs.writeFileSync(outPath, lines.join('\n'));
NODE

echo "OK: downloaded refs to $OUT"
echo "OK: captions -> $CAPTIONS"
echo "OK: audit manifest -> $MANIFEST"