#!/usr/bin/env bash
# track-agent-state.sh - PreToolUse hook to track active quality cycle agent
#
# This hook intercepts Task tool invocations and writes the agent name to a state
# file when a quality cycle agent is being invoked. This enables the status line
# to display which agent role is currently executing.
#
# Tracked agents:
# - Quality cycle: code-developer, code-reviewer, code-tester
# - Plugin cycle: plugin-engineer, plugin-reviewer, plugin-tester
# - Prompt cycle: prompt-engineer, prompt-reviewer, prompt-tester
# - Documentation: tech-writer, tech-editor, tech-publisher
# - Investigation: Explore, Plan
#
# State file: ~/.claude/current-agent

set -euo pipefail

# Configuration
readonly CLAUDE_HOME="${HOME}/.claude"
readonly AGENT_STATE="${CLAUDE_HOME}/current-agent"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Create necessary directories
mkdir -p "$(dirname "${AGENT_STATE}")" 2>/dev/null || true
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [track-agent-state] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Quality cycle agents
readonly QUALITY_AGENTS=(
    "code-developer"
    "code-reviewer"
    "code-tester"
    "plugin-engineer"
    "plugin-reviewer"
    "plugin-tester"
    "prompt-engineer"
    "prompt-reviewer"
    "prompt-tester"
    "tech-writer"
    "tech-editor"
    "tech-publisher"
    "Explore"
    "Plan"
)

# Check if value is a quality agent
is_quality_agent() {
    local agent="$1"
    for qa in "${QUALITY_AGENTS[@]}"; do
        if [[ "$agent" == "$qa" ]]; then
            return 0
        fi
    done
    return 1
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

    debug_log "Task tool detected, checking for quality agent"

    # Extract subagent_type from parameters
    # The Task tool has a parameter called subagent_type
    local subagent_type
    if command -v jq >/dev/null 2>&1; then
        subagent_type=$(printf '%s\n' "${json_input}" | jq -r '.parameters.subagent_type // ""' 2>/dev/null || echo "")
    else
        # Fallback to sed-based parsing
        subagent_type=$(printf '%s\n' "${json_input}" | sed -n 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    if [[ -z "${subagent_type}" ]]; then
        debug_log "No subagent_type found in Task parameters"
        exit 0
    fi

    debug_log "Subagent type: ${subagent_type}"

    # Check if it's a quality agent
    if is_quality_agent "${subagent_type}"; then
        debug_log "Quality agent detected: ${subagent_type}"
        # Write agent name to state file
        printf '%s' "${subagent_type}" > "${AGENT_STATE}" 2>/dev/null || {
            debug_log "ERROR: Failed to write agent state"
        }
        debug_log "Agent state written to ${AGENT_STATE}"
    else
        debug_log "Not a quality agent: ${subagent_type}"
    fi

    # Always allow operation to proceed
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
