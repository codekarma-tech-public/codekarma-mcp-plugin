#!/usr/bin/env bash
# karmaiq-impact PreToolUse hook on Bash(git commit *)
# Scans the staged diff for changed method/function definitions in code files.
# Injects an additionalContext hint listing the detected methods and recommending
# an impact check before the commit lands.
#
# Warn-only — never blocks the commit (exit 0 always).
# Opt out: KARMAIQ_NO_PRECOMMIT_IMPACT=1

set -uo pipefail

# Opt-out
if [[ "${KARMAIQ_NO_PRECOMMIT_IMPACT:-}" == "1" ]]; then
  exit 0
fi

# Require git and a repo
if ! command -v git >/dev/null 2>&1; then
  exit 0
fi
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# Consume stdin to avoid SIGPIPE issues; we don't actually need the hook input here
cat >/dev/null 2>&1 || true

# Code-file globs we care about
CODE_GLOBS=('*.py' '*.go' '*.java' '*.ts' '*.tsx' '*.js' '*.jsx' '*.rb' '*.kt' '*.scala' '*.rs' '*.cs')

# Changed code files (staged)
CHANGED_FILES=$(git diff --cached --name-only -- "${CODE_GLOBS[@]}" 2>/dev/null | head -20 || true)
if [[ -z "${CHANGED_FILES:-}" ]]; then
  exit 0
fi

# Extract changed method/function names from added/removed lines of the staged diff.
# Heuristics per language family — keep simple and lang-overlapping:
#   - Python:     def NAME(, async def NAME(, class NAME
#   - Go:         func NAME(, func (recv) NAME(
#   - Java/Kotlin/Scala/C#: (public|private|protected|static)+ ReturnType NAME(
#   - TS/JS:      function NAME(, async function NAME(, NAME: function, NAME = (
#   - Rust:       fn NAME(, pub fn NAME(
#   - Ruby:       def NAME
#
# We grep the unified diff for lines that start with + or - and match these patterns.
# Run diff with per-language funcname patterns inlined via -c so hunk headers
# include enclosing function/class names. Avoids requiring user .gitattributes.
DIFF=$(git \
  -c 'diff.python.xfuncname=^[[:space:]]*((class|(async[[:space:]]+)?def)[[:space:]].*)' \
  -c 'diff.golang.xfuncname=^[[:space:]]*(func[[:space:]].*)' \
  -c 'diff.ruby.xfuncname=^[[:space:]]*((class|module|def)[[:space:]].*)' \
  -c 'diff.rust.xfuncname=^[[:space:]]*((pub[[:space:]]+)?(async[[:space:]]+)?fn[[:space:]].*|impl[[:space:]].*|trait[[:space:]].*)' \
  diff --cached -U0 -- "${CODE_GLOBS[@]}" 2>/dev/null || true)
if [[ -z "${DIFF:-}" ]]; then
  exit 0
fi

# 1. Method signatures CHANGED (added/removed/edited signature lines)
SIG_METHODS=$(printf '%s' "$DIFF" \
  | grep -E '^[+-][[:space:]]*(export[[:space:]]+)?(pub[[:space:]]+)?(async[[:space:]]+)?(def|func|function|fn|class|public|private|protected|static)' 2>/dev/null \
  | grep -oE '(def|func|function|fn|class)[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' 2>/dev/null \
  | awk '{print $NF}' \
  | sort -u || true)

# 2. Methods whose BODY changed — git diff hunk headers include the enclosing
#    function/class name as the section heading: "@@ -A,B +C,D @@ <heading>"
#    This catches body-only edits that don't touch the signature line.
HUNK_METHODS=$(printf '%s' "$DIFF" \
  | grep -E '^@@.*@@ ' 2>/dev/null \
  | sed -E 's/^@@.*@@ //' \
  | grep -oE '(def|func|function|fn|class)[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(' 2>/dev/null \
  | sed -E 's/[[:space:]]*\($//; s/^(def|func|function|fn|class)[[:space:]]+//' \
  | sort -u || true)

# 3. Arrow / var-assigned function patterns (TS/JS):
#    NAME = (...) => / NAME: (...) =>
ARROW_METHODS=$(printf '%s' "$DIFF" \
  | grep -E '^[+-][[:space:]]*(export[[:space:]]+)?(const|let|var)?[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[:=][[:space:]]*(async[[:space:]]+)?\(' 2>/dev/null \
  | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[:=]' 2>/dev/null \
  | sed -E 's/[[:space:]]*[:=]$//' \
  | sort -u || true)

# Merge all three sources, dedupe, cap at 12, comma-join.
# Strip language keywords that slip through pattern matching.
METHODS=$(printf '%s\n%s\n%s\n' "$SIG_METHODS" "$HUNK_METHODS" "$ARROW_METHODS" \
  | grep -v '^$' \
  | grep -vwE '(def|func|function|fn|class|module|impl|trait|const|let|var|export|return|if|else|for|while|switch|case|new|throw|await|async|public|private|protected|static|self|this|pub)' \
  | sort -u \
  | head -12 \
  | tr '\n' ',' \
  | sed 's/,$//' || true)

# Backward-compat var for message rendering below
ARROW=""

# File count + line counts for context
FILE_COUNT=$(printf '%s\n' "$CHANGED_FILES" | grep -c . || echo 0)
ADD_COUNT=$(printf '%s' "$DIFF" | grep -c '^+' || echo 0)
DEL_COUNT=$(printf '%s' "$DIFF" | grep -c '^-' || echo 0)

# Build the message
PARTS=""
if [[ -n "${METHODS:-}" ]]; then
  PARTS="${PARTS} Methods/functions/classes touched: ${METHODS}."
fi
if [[ -n "${ARROW:-}" ]]; then
  PARTS="${PARTS} Possible arrow/assigned functions: ${ARROW}."
fi

# Compose first lines of changed file list (≤5 paths)
FILES_FOR_MSG=$(printf '%s\n' "$CHANGED_FILES" | head -5 | tr '\n' ',' | sed 's/,$//')
EXTRA_FILES=""
if [[ "$FILE_COUNT" -gt 5 ]]; then
  EXTRA_FILES=" (+$((FILE_COUNT - 5)) more)"
fi

if [[ -z "$PARTS" ]]; then
  MSG="karmaIQ pre-commit: staged diff covers ${FILE_COUNT} code file(s) [${FILES_FOR_MSG}${EXTRA_FILES}] (+${ADD_COUNT}/-${DEL_COUNT} lines) but no method definitions were detected by the heuristic. If any modified code is in a production-loaded service, consider running /karmaiq-impact:method <service> <method> for affected methods before committing."
else
  MSG="karmaIQ pre-commit: staged diff covers ${FILE_COUNT} code file(s) [${FILES_FOR_MSG}${EXTRA_FILES}] (+${ADD_COUNT}/-${DEL_COUNT} lines).${PARTS} Recommend running /karmaiq-impact:method <service> <method> on production-loaded targets before this commit lands, or delegate the batch check to the karmaiq-impact-analyzer subagent."
fi

# Escape for JSON embedding (backslashes + double quotes)
ESCAPED=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "${ESCAPED}"
  }
}
EOF

exit 0
