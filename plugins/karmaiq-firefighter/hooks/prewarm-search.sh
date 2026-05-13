#!/usr/bin/env bash
# karmaiq-firefighter UserPromptSubmit hook
# Scans the user's prompt for likely API paths and service names. If detected,
# injects a hint to Claude to resolve them via search_catalog before any graph tool.
#
# Fail-silent: any internal error → exit 0 with no output.
# Opt out: KARMAIQ_NO_PREWARM=1

set -uo pipefail

# Opt-out
if [[ "${KARMAIQ_NO_PREWARM:-}" == "1" ]]; then
  exit 0
fi

# Read hook input from stdin
INPUT=$(cat 2>/dev/null || true)
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract the user prompt text — try jq if available, else crude regex fallback
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // .user_prompt // empty' 2>/dev/null || true)
fi
if [[ -z "${PROMPT:-}" ]]; then
  # Fallback: grep for "prompt":"..." or "user_prompt":"..."
  PROMPT=$(printf '%s' "$INPUT" | grep -oE '"(prompt|user_prompt)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"(prompt|user_prompt)"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

if [[ -z "${PROMPT:-}" ]]; then
  exit 0
fi

# Detect API paths: /api/v<digit>/<segments>
API_PATHS=$(printf '%s' "$PROMPT" \
  | grep -oE '/api/v[0-9]+/[a-zA-Z0-9_/{}.\-]+' 2>/dev/null \
  | sort -u \
  | head -5 \
  | tr '\n' ',' \
  | sed 's/,$//' || true)

# Detect service-like tokens: lowercase hyphenated words with ≥2 segments (e.g. payments-service, cb-app, checkout-api)
SERVICES=$(printf '%s' "$PROMPT" \
  | grep -oE '\b[a-z][a-z0-9]*(-[a-z][a-z0-9]*){1,}\b' 2>/dev/null \
  | sort -u \
  | head -5 \
  | tr '\n' ',' \
  | sed 's/,$//' || true)

if [[ -z "$API_PATHS" && -z "$SERVICES" ]]; then
  exit 0
fi

CANDIDATES=""
[[ -n "$API_PATHS" ]] && CANDIDATES="${CANDIDATES} APIs: ${API_PATHS};"
[[ -n "$SERVICES" ]] && CANDIDATES="${CANDIDATES} Services: ${SERVICES};"

MSG="karmaIQ pre-warm: detected possible service-mesh entity mentions in user prompt —${CANDIDATES} If this is a karmaIQ question, resolve via mcp__karma-iq__search_catalog(catalog=\"graph\", query=<name>) BEFORE any graph tool call. The system does exact string match on node_ids — guessing or hand-typing names returns empty results. Preserve route paths byte-for-byte (regex form like /api/v2/foo/([^/]+)/? — never rewrite to {id})."

# Escape for JSON
ESCAPED=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "${ESCAPED}"
  }
}
EOF

exit 0
