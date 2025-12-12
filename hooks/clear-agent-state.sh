#!/usr/bin/env bash
# clear-agent-state.sh - PostToolUse hook to clear active agent state
#
# This hook intercepts Task tool completion and clears the agent state file,
# indicating that the subagent has finished executing. This ensures the status
# line only shows the agent while it's actively running.
#
# State file: ~/.claude/current-agent

set -euo pipefail

# Configuration
readonly CLAUDE_HOME="${HOME}/.claude"
readonly AGENT_STATE="${CLAUDE_HOME}/current-agent"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [clear-agent-state] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse tool name
    local tool_name
    if command -v jq >/dev/null 2>&1; then
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi
    else
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Only process Task tool
    if [[ "${tool_name}" != "Task" ]]; then
        exit 0
    fi

    debug_log "Task tool completed, clearing agent state"

    # Remove agent state file
    if [[ -f "${AGENT_STATE}" ]]; then
        rm -f "${AGENT_STATE}" 2>/dev/null || {
            debug_log "ERROR: Failed to remove agent state file"
        }
        debug_log "Agent state cleared"
    else
        debug_log "No agent state file found"
    fi

    # Always allow operation to proceed
    exit 0
}

# Execute main
main "$@"
