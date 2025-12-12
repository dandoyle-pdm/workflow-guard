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

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Source shared counter library
if [[ -f "${SCRIPT_DIR}/lib/counter.sh" ]]; then
    # shellcheck source=lib/counter.sh
    source "${SCRIPT_DIR}/lib/counter.sh"
else
    debug_log "ERROR: counter library not found: ${SCRIPT_DIR}/lib/counter.sh"
    exit 0  # Fail-safe: don't break caller
fi

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
        debug_log "ERROR: Empty violation JSON received - not logging"
        exit 0
    fi

    # Validate JSON is well-formed using jq (fail-safe)
    if command -v jq >/dev/null 2>&1; then
        if ! printf '%s' "${violation_json}" | jq -e . >/dev/null 2>&1; then
            debug_log "ERROR: Invalid JSON received - not logging to prevent file corruption"
            exit 0
        fi
    else
        debug_log "WARNING: jq not available, skipping JSON validation"
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
