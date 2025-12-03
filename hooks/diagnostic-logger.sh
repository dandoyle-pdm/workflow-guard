#!/usr/bin/env bash
# diagnostic-logger.sh - Logs all hook input for debugging and development
#
# This diagnostic hook captures the complete JSON payload provided to PreToolUse
# hooks, enabling developers to understand what data is available for different
# tool types (Bash, Edit, Write, MCP tools).
#
# Enable with: export CLAUDE_HOOK_DIAGNOSTICS=true
# Logs to: ~/.claude/logs/hook-diagnostics.jsonl
#
# Security: Always exits 0 to never block operations

set -euo pipefail

# Configuration
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DIAG_LOG="${CLAUDE_HOME}/logs/hook-diagnostics.jsonl"

# Only run if explicitly enabled
if [[ "${CLAUDE_HOOK_DIAGNOSTICS:-false}" != "true" ]]; then
    exit 0
fi

# Create log directory
mkdir -p "$(dirname "${DIAG_LOG}")" 2>/dev/null || true

# Read full JSON input from stdin
json_input=$(cat)

# Create timestamped log entry
# Use jq to parse and reformat with timestamp
# If jq fails (malformed JSON), log the raw input for debugging
entry=$(jq -c --arg ts "$(date -Iseconds)" '{
    timestamp: $ts,
    data: .
}' <<< "$json_input" 2>/dev/null || {
    # Fallback for malformed JSON
    printf '{"timestamp":"%s","error":"malformed_json","raw":%s}\n' \
        "$(date -Iseconds)" \
        "$(jq -Rs . <<< "$json_input")"
})

# Append to log file (JSON Lines format - one JSON object per line)
echo "$entry" >> "$DIAG_LOG" 2>/dev/null || true

# Always allow operation to proceed (diagnostic only)
exit 0
