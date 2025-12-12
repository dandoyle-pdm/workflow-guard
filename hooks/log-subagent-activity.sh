#!/usr/bin/env bash
# log-subagent-activity.sh - PostToolUse hook to log subagent activity
#
# This hook intercepts Task tool completion and logs subagent activity for
# audit trails and session continuity. Logs include session ID, agent type,
# task description, and completion status.
#
# Log file: ~/.claude/logs/subagent-activity.log

set -euo pipefail

# Configuration
readonly CLAUDE_HOME="${HOME}/.claude"
readonly ACTIVITY_LOG="${CLAUDE_HOME}/logs/subagent-activity.log"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Create log directory
mkdir -p "$(dirname "${ACTIVITY_LOG}")" 2>/dev/null || true
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [log-subagent-activity] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse fields from JSON
    local tool_name session_id subagent_type description
    if command -v jq >/dev/null 2>&1; then
        tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
        session_id=$(printf '%s\n' "${json_input}" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
        subagent_type=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.subagent_type // "unspecified"' 2>/dev/null || echo "unspecified")
        description=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.description // ""' 2>/dev/null || echo "")
    else
        # Fallback to sed parsing
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        session_id=$(printf '%s\n' "${json_input}" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "unknown")
        subagent_type=$(printf '%s\n' "${json_input}" | sed -n 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "unspecified")
        description=$(printf '%s\n' "${json_input}" | sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Only process Task tool
    if [[ "${tool_name}" != "Task" ]]; then
        exit 0
    fi

    debug_log "Task tool completed: session=${session_id} agent=${subagent_type}"

    # Log activity
    printf '[%s] SESSION:%s AGENT:%s TASK:%s STATUS:completed\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "${session_id}" \
        "${subagent_type}" \
        "${description}" \
        >> "${ACTIVITY_LOG}" 2>/dev/null || {
            debug_log "ERROR: Failed to write to activity log"
        }

    # Always allow operation to proceed
    exit 0
}

# Execute main
main "$@"
