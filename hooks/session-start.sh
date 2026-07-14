#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read the start-flutter-craft skill content
SKILL_FILE="${PLUGIN_ROOT}/skills/start-flutter-craft/SKILL.md"

if [[ ! -f "$SKILL_FILE" ]]; then
    echo '{"error": "start-flutter-craft/SKILL.md not found"}'
    exit 1
fi

skill_content=$(cat "$SKILL_FILE")
# Strip CR so CRLF checkouts don't leak literal \r into the injected context
skill_content="${skill_content//$'\r'/}"

context="<EXTREMELY_IMPORTANT>
You have flutter-craft skills available.

${skill_content}
</EXTREMELY_IMPORTANT>"

# Output JSON for Claude Code to consume — jq guarantees valid escaping
if command -v jq &>/dev/null; then
    jq -n --arg ctx "$context" '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": $ctx
      }
    }'
    exit 0
fi

# Fallback without jq: pure-bash JSON escaping (backslash first, then the rest)
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

escaped_content=$(escape_for_json "$context")
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped_content"
