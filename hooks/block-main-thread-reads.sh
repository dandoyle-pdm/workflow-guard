#!/usr/bin/env bash
# block-main-thread-reads.sh - PreToolUse hook to enforce agent context for read operations
#
# This hook intercepts Read, Glob, and Grep tool invocations and blocks them
# unless an agent context is detected in the transcript. This enforces the pattern:
# - Main thread coordinates
# - Explore subagent investigates
# - Quality agents implement
#
# Security hardened following patterns from block-unreviewed-edits.sh:
# - Command injection prevention via printf instead of echo
# - Proper jq error handling
# - Input validation
# - Audit logging

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Color codes for error messages
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

# Quality agents - can be extended via environment variable
# Includes both quality agents and investigation agents (Explore)
readonly DEFAULT_AGENTS="code-developer,code-reviewer,code-tester,plugin-engineer,plugin-reviewer,plugin-tester,prompt-engineer,prompt-reviewer,prompt-tester,tech-writer,tech-editor,tech-publisher,Explore"
readonly AGENT_PATTERN="${CLAUDE_QUALITY_AGENTS:-${DEFAULT_AGENTS}}"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [block-main-thread-reads] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Check if transcript contains agent identity
# Returns 0 if agent detected, 1 otherwise
has_agent_context() {
    local transcript_path="$1"

    # Validate transcript path exists
    if [[ ! -f "$transcript_path" ]]; then
        debug_log "WARNING: Transcript file not found: $transcript_path"
        return 1
    fi

    # Validate AGENT_PATTERN contains only safe characters (alphanumeric, comma, hyphen, underscore)
    if [[ ! "${AGENT_PATTERN}" =~ ^[a-zA-Z0-9,_-]+$ ]]; then
        debug_log "ERROR: Invalid AGENT_PATTERN format, blocking operation"
        exit 2  # Block on invalid configuration - fail-secure
    fi

    # Convert comma-separated list to pipe-separated for grep regex
    local agent_regex
    agent_regex=$(printf '%s' "${AGENT_PATTERN}" | sed 's/,/|/g')

    # Search for agent identity pattern in transcript
    # Pattern: "working as the {agent-name} agent" OR "You are {agent-name}" (for Explore)
    if grep -qE "working as the (${agent_regex}) agent" "$transcript_path" 2>/dev/null || \
       grep -qE "You are (${agent_regex})" "$transcript_path" 2>/dev/null; then
        local detected_agent
        detected_agent=$(grep -oE "(working as the|You are) (${agent_regex})( agent)?" "$transcript_path" 2>/dev/null | head -1 || echo "unknown")
        debug_log "Agent context detected: $detected_agent"
        return 0
    fi

    debug_log "No agent context detected in transcript"
    return 1
}

# Generate helpful guidance message
generate_error_message() {
    local tool_name="$1"

    cat <<EOFMSG

================================================================================
  INVESTIGATION AGENT REQUIRED - Read Operations Policy
================================================================================

You attempted to ${tool_name} without agent context.

All read operations (Read, Glob, Grep) must be performed within an agent
context to enforce proper separation of concerns:

- Main thread: Coordinates work and dispatches to agents
- Explore agent: Investigates codebase and gathers information
- Quality agents: Implement changes with proper review cycles

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

Use the Task tool to dispatch an Explore subagent for investigation:

  Task(subagent_type="general-purpose",
       prompt="You are Explore, an investigation agent. Your task is to...")

The Explore agent can freely use Read, Glob, and Grep to investigate
the codebase and report findings back to the main thread.

Once investigation is complete, the main thread can dispatch appropriate
quality agents for implementation work.

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Enforces clean separation: coordination vs investigation vs implementation
- Prevents ad-hoc exploration that bypasses documentation
- Maintains clear audit trail of investigation activities
- Ensures findings are properly summarized before action

--------------------------------------------------------------------------------
  EXCEPTION HANDLING
--------------------------------------------------------------------------------

If you believe this blocking is incorrect, verify that your transcript
contains one of these agent identity markers:

  - "working as the {agent-name} agent"
  - "You are {agent-name}"

Recognized agents include: Explore, code-developer, plugin-engineer, etc.

================================================================================
EOFMSG
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name transcript_path

    if command -v jq >/dev/null 2>&1; then
        # Use jq for reliable JSON parsing
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "${tool_name}" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        # Only process Read, Glob, Grep tools
        if [[ ! "${tool_name}" =~ ^(Read|Glob|Grep)$ ]]; then
            exit 0
        fi

        if ! transcript_path=$(printf '%s\n' "${json_input}" | jq -r '.transcript_path // ""' 2>/dev/null); then
            debug_log "WARNING: Failed to parse transcript_path from JSON"
            transcript_path=""
        fi
    else
        # Fallback to sed-based parsing (portable, no PCRE required)
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ ! "${tool_name}" =~ ^(Read|Glob|Grep)$ ]]; then
            exit 0
        fi

        transcript_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    debug_log "Checking ${tool_name} operation"

    # Check for agent context
    if [[ -n "${transcript_path}" ]] && has_agent_context "${transcript_path}"; then
        debug_log "ALLOWED: Agent context detected"
        debug_log "AUDIT: Agent read operation - tool=${tool_name}"
        exit 0
    fi

    # Block the operation - no agent context
    generate_error_message "${tool_name}" >&2

    # Log for audit
    debug_log "AUDIT: Blocked ${tool_name} without agent context"

    # Log violation for QC Observer (fail-safe - errors won't break blocking)
    # Use jq for safe JSON construction to prevent injection attacks
    local violation_json
    violation_json=$(jq -n \
        --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --arg tool "${tool_name}" \
        '{
            "type": "workflow-guard",
            "timestamp": $ts,
            "observation_type": "blocking",
            "cycle": "inferred",
            "session_id": "",
            "agent": null,
            "tool": $tool,
            "violation": "main_thread_read",
            "severity": "MEDIUM",
            "blocking": true,
            "context": {"required_agent": "Explore or quality agent"}
        }' 2>/dev/null || true)

    if [[ -n "${violation_json}" ]]; then
        printf '%s' "${violation_json}" | "${SCRIPT_DIR}/observe-violation.sh" 2>/dev/null || true
    fi

    # Exit code 2 blocks the tool execution
    exit 2
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
