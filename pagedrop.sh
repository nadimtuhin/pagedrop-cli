#!/usr/bin/env bash
set -e

FILE=""
TTL="3d"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ttl) TTL="$2"; shift 2 ;;
    *) FILE="$1"; shift ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "Usage: pagedrop <file.html> [--ttl <duration>]" >&2
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: file '$FILE' not found" >&2
  exit 1
fi

# Build JSON payload with proper encoding
if command -v jq &>/dev/null; then
  PAYLOAD=$(jq -n --arg html "$(cat "$FILE")" --arg ttl "$TTL" '{html: $html, ttl: $ttl}')
elif command -v python3 &>/dev/null; then
  PAYLOAD=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    print(json.dumps({'html': f.read(), 'ttl': sys.argv[2]}))
" "$FILE" "$TTL")
else
  echo "Error: jq or python3 is required for JSON encoding" >&2
  exit 1
fi

RESPONSE=$(curl -sf -X POST https://pagedrop.io/api/upload \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Extract URL from response
if command -v jq &>/dev/null; then
  URL=$(echo "$RESPONSE" | jq -r '.url // .link // .data.url // .data.link // empty')
else
  URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$URL" ]; then
  echo "Error: could not extract URL from response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

echo "$URL"
