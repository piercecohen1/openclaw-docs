#!/bin/bash
# Downloads all OpenClaw docs as markdown from llms.txt index
# Usage: ./download.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_PARALLEL=10
FAILED_LOG="/tmp/openclaw-docs-failed.txt"
LLMS_TXT_CACHE="/tmp/openclaw-docs-urls.txt"

# --force flag is accepted for backward compat but is now a no-op
# (URL list is always re-fetched)

> "$FAILED_LOG"

# Always re-fetch to catch new/removed pages
echo "Fetching llms.txt index..."
curl -sL "https://docs.openclaw.ai/llms.txt" \
  | grep -oE 'https://docs\.openclaw\.ai/[^)]*\.md' \
  | sort -u > "$LLMS_TXT_CACHE"
echo "Found $(wc -l < "$LLMS_TXT_CACHE" | tr -d ' ') markdown files"

TOTAL=$(wc -l < "$LLMS_TXT_CACHE" | tr -d ' ')
echo "Downloading $TOTAL pages (max $MAX_PARALLEL parallel)..."

download_page() {
  local md_url="$1"
  local rel_path="${md_url#https://docs.openclaw.ai/}"
  local out_file="$SCRIPT_DIR/docs/$rel_path"

  mkdir -p "$(dirname "$out_file")"

  local http_code
  http_code=$(curl -sL -w '%{http_code}' -o "$out_file" "$md_url" 2>/dev/null)

  if [[ "$http_code" != "200" ]] || [[ ! -s "$out_file" ]]; then
    rm -f "$out_file"
    echo "$md_url" >> "$FAILED_LOG"
    echo "FAIL [$http_code] $rel_path"
  else
    echo "OK   $rel_path"
  fi
}

export -f download_page
export SCRIPT_DIR FAILED_LOG

cat "$LLMS_TXT_CACHE" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'download_page "$@"' _ {}

# Also download llms-full.txt if available
echo ""
echo "Downloading llms-full.txt..."
if curl -sL -o "$SCRIPT_DIR/docs/llms-full.txt" "https://docs.openclaw.ai/llms-full.txt" && [[ -s "$SCRIPT_DIR/docs/llms-full.txt" ]]; then
  full_lines=$(wc -l < "$SCRIPT_DIR/docs/llms-full.txt" | tr -d ' ')
  echo "OK   llms-full.txt ($full_lines lines)"
else
  rm -f "$SCRIPT_DIR/docs/llms-full.txt"
  echo "SKIP llms-full.txt (not available)"
fi

# Count results
FAILED_COUNT=0
if [[ -f "$FAILED_LOG" ]]; then
  FAILED_COUNT=$(grep -c . "$FAILED_LOG" 2>/dev/null || true)
fi
DOWNLOADED=$((TOTAL - FAILED_COUNT))

# Generate README with scrape metadata
SCRAPE_DATE="$(date '+%B %-d, %Y')"
SCRAPE_SHORT="$(date '+%-m-%-d-%y')"

# Count pages per section
section_table() {
  local dir="$1"
  # Top-level files
  local top_count
  top_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [[ "$top_count" -gt 0 ]]; then
    echo "| \`(top-level)\` | $top_count |"
  fi
  # Subdirectories
  for subdir in "$dir"/*/; do
    [[ -d "$subdir" ]] || continue
    local name
    name=$(basename "$subdir")
    local count
    count=$(find "$subdir" -name "*.md" | wc -l | tr -d ' ')
    [[ "$count" -eq 0 ]] && continue
    echo "| \`$name/\` | $count |"
  done | sort -t'|' -k3 -rn
}

cat > "$SCRIPT_DIR/README.md" <<EOF
# OpenClaw Docs Mirror

Local mirror of the OpenClaw documentation from [docs.openclaw.ai](https://docs.openclaw.ai), downloaded as raw markdown via \`llms.txt\` index.

## Scrape Info

| | |
|---|---|
| **Last scraped** | $SCRAPE_DATE |
| **Total pages** | $DOWNLOADED |
| **Source** | [llms.txt](https://docs.openclaw.ai/llms.txt) |

## Sections

| Directory | Pages |
|-----------|-------|
$(section_table "$SCRIPT_DIR/docs")

## Directory Structure

\`\`\`
$(tree "$SCRIPT_DIR/docs" -d -L 2 --noreport 2>/dev/null | sed 's|'"$SCRIPT_DIR/docs"'|docs|' || echo "docs")
\`\`\`

## Usage

Search with ripgrep:

\`\`\`bash
rg "query" docs/
rg "query" docs/llms-full.txt   # Full-text search
\`\`\`

## Updating

\`\`\`bash
bash download.sh --force   # Re-fetch URL list from llms.txt
\`\`\`

## How It Works

The OpenClaw docs site publishes an \`llms.txt\` index with direct \`.md\` URLs for every page. The download script fetches the index, extracts all URLs, and downloads them with $MAX_PARALLEL parallel connections. Directory structure is preserved from the URL paths.
EOF

echo ""
echo "=== Summary ==="
echo "Downloaded $DOWNLOADED/$TOTAL pages"
if [[ "$FAILED_COUNT" -gt 0 ]]; then
  echo "  Failures: $FAILED_COUNT (logged to $FAILED_LOG)"
fi
echo "Generated README.md (scraped $SCRAPE_SHORT)"

# Write machine-readable timestamp for freshness checks
date +%Y-%m-%d > "$SCRIPT_DIR/.last-updated"
