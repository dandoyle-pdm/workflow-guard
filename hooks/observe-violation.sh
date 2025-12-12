#!/usr/bin/env bash
# observe-violation.sh - Utility to log quality violations to JSONL
#
# Reads violation JSON from stdin and appends to violations.jsonl storage.
# This is fail-safe utility - logging failures must NOT break blocking behavior.
#
# Expected JSON input format:
# {
#   "type": "workflow-guard|claude-mem|session-lifecycle|mcp-health|agent-dispatch",
#   "timestamp": "ISO-8601",
#   "observation_type": "blocking",
#   "resource": "plugin|hook|agent|command|skill",
#   "correlation": "ticket-id or session-id",
#   "cycle": "coding|plugin|prompt|tech|inferred",
#   "session_id": "session-id",
#   "agent": "agent-name or null",
#   "tool": "Edit|Write|NotebookEdit",
#   "file": "absolute-path",
#   "violation": "description",
#   "severity": "CRITICAL|HIGH|MEDIUM|LOW",
#   "blocking": true|false,
#   "context": {}
# }
#
# Type values:
#   workflow-guard    - QC enforcement, branch protection (quality cycle violations)
#   claude-mem        - Memory MCP (future - knowledge storage events)
#   session-lifecycle - Claude Code core (future - session events)
#   mcp-health        - MCP servers (future - server availability)
#   agent-dispatch    - Task tool (future - subagent tracking)
#
# Resource values:
#   plugin   - Plugin resources (plugin.json, hooks, commands)
#   hook     - Bash hooks (PreToolUse, PostToolUse)
#   agent    - Quality agents (code-developer, plugin-engineer, etc.)
#   command  - Slash commands and skills
#   skill    - Injectable skills for prompt context
#
# Correlation field:
#   Links related observations together using common identifiers:
#   - ticket-id: For observations related to specific tickets
#   - session-id: For observations within a Claude Code session
#   - agent-session-id: For observations within a quality agent invocation

set -euo pipefail

# Storage paths
readonly NOVACLOUD_HOME="${HOME}/.novacloud"
readonly OBSERVATIONS_DIR="${NOVACLOUD_HOME}/observations"
readonly VIOLATIONS_FILE="${OBSERVATIONS_DIR}/violations.jsonl"
readonly COUNTER_FILE="${OBSERVATIONS_DIR}/.counter"
readonly DEBUG_LOG="${HOME}/.claude/logs/hooks-debug.log"

# Debug logging function (fail-safe)
debug_log() {
    printf '[%s] [observe-violation] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Get next sequence number (fail-safe)
# Returns 0 on failure, caller should proceed without sequence
get_next_sequence() {
    local counter_file="$1"
    local counter_dir
    counter_dir=$(dirname "${counter_file}")

    # Ensure directory exists
    if ! mkdir -p "${counter_dir}" 2>/dev/null; then
        debug_log "ERROR: Failed to create counter directory: ${counter_dir}"
        echo "0"
        return 1
    fi

    # Try to acquire lock with timeout (5 seconds max)
    local lock_file="${counter_file}.lock"
    local lock_timeout=50  # 50 * 0.1s = 5 seconds
    local lock_attempts=0

    while [[ ${lock_attempts} -lt ${lock_timeout} ]]; do
        if mkdir "${lock_file}" 2>/dev/null; then
            break
        fi
        sleep 0.1
        lock_attempts=$((lock_attempts + 1))
    done

    if [[ ${lock_attempts} -ge ${lock_timeout} ]]; then
        debug_log "ERROR: Failed to acquire lock after ${lock_timeout} attempts"
        echo "0"
        return 1
    fi

    # Lock acquired - read current counter
    local current_seq=0
    if [[ -f "${counter_file}" ]]; then
        current_seq=$(cat "${counter_file}" 2>/dev/null || echo "0")
        # Validate counter is numeric
        if ! [[ "${current_seq}" =~ ^[0-9]+$ ]]; then
            debug_log "WARNING: Invalid counter value '${current_seq}', resetting to 0"
            current_seq=0
        fi
    fi

    # Increment and write back
    local next_seq=$((current_seq + 1))
    if ! printf '%d\n' "${next_seq}" > "${counter_file}" 2>/dev/null; then
        debug_log "ERROR: Failed to write counter file: ${counter_file}"
        # Release lock
        rmdir "${lock_file}" 2>/dev/null || true
        echo "0"
        return 1
    fi

    # Release lock
    rmdir "${lock_file}" 2>/dev/null || true

    # Return next sequence
    echo "${next_seq}"
    return 0
}

# Main execution
main() {
    # Read JSON from stdin
    local violation_json
    if ! violation_json=$(cat); then
        debug_log "ERROR: Failed to read violation JSON from stdin"
        exit 0  # Fail-safe: don't break caller
    fi

    # Validate JSON is not empty
    if [[ -z "${violation_json}" ]]; then
        debug_log "ERROR: Empty violation JSON received"
        exit 0
    fi

    # Create observations directory if needed
    if ! mkdir -p "${OBSERVATIONS_DIR}" 2>/dev/null; then
        debug_log "ERROR: Failed to create observations directory: ${OBSERVATIONS_DIR}"
        exit 0
    fi

    # Get next sequence number (fail-safe)
    local sequence
    sequence=$(get_next_sequence "${COUNTER_FILE}")
    if [[ "${sequence}" == "0" ]]; then
        debug_log "WARNING: Failed to get sequence number, proceeding without it"
    fi

    # Inject sequence number into JSON if we have jq
    local final_json="${violation_json}"
    if command -v jq >/dev/null 2>&1 && [[ "${sequence}" != "0" ]]; then
        final_json=$(printf '%s' "${violation_json}" | jq --arg seq "${sequence}" '. + {sequence: ($seq | tonumber)}' 2>/dev/null || echo "${violation_json}")
        if [[ "${final_json}" == "${violation_json}" ]]; then
            debug_log "WARNING: Failed to inject sequence via jq, using original JSON"
        else
            debug_log "Injected sequence number: ${sequence}"
        fi
    fi

    # Append violation to JSONL file
    if ! printf '%s\n' "${final_json}" >> "${VIOLATIONS_FILE}" 2>/dev/null; then
        debug_log "ERROR: Failed to append violation to ${VIOLATIONS_FILE}"
        exit 0
    fi

    debug_log "Violation logged successfully (sequence: ${sequence})"
    exit 0
}

# Execute with fail-safe error handling
main "$@" || exit 0
