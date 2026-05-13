#!/usr/bin/env bash
# karmaiq-core SessionStart hook
# Surfaces the active karmaIQ domain to Claude, or prompts the user to run /karmaiq-core:setup.
# Fail-silent on any internal error — never disrupt session start.

set -uo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/karmaiq-core}"
DOMAIN_FILE="${DATA_DIR}/domain.txt"

# Detect non-default MCP URL (multi-tenant override)
URL_NOTE=""
if [[ -n "${KARMAIQ_MCP_URL:-}" ]]; then
  URL_NOTE=" karmaIQ MCP endpoint: \`${KARMAIQ_MCP_URL}\` (custom)."
fi

if [[ -f "$DOMAIN_FILE" ]]; then
  DOMAIN=$(tr -d '[:space:]' < "$DOMAIN_FILE" 2>/dev/null || true)
  if [[ -n "${DOMAIN:-}" ]]; then
    MSG="Active karmaIQ domain: \`${DOMAIN}\`. All karmaIQ tools query this domain. Switch with /karmaiq-core:domain <name>.${URL_NOTE}"
  else
    MSG="karmaIQ domain file is empty. Run /karmaiq-core:setup to pick a domain.${URL_NOTE}"
  fi
else
  MSG="karmaIQ domain not set yet. Run /karmaiq-core:setup to pick one before using karmaIQ tools.${URL_NOTE}"
fi

# Escape backslashes and double quotes for JSON embedding
ESCAPED=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${ESCAPED}"
  }
}
EOF

exit 0
