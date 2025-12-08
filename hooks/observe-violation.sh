#!/usr/bin/env bash
# observe-violation.sh - Utility to log quality violations to JSONL
#
# Reads violation JSON from stdin and appends to violations.jsonl storage.
# This is fail-safe utility - logging failures must NOT break blocking behavior.
#
# Expected JSON input format:
# {
#   "timestamp": "ISO-8601",
#   "observation_type": "blocking",
#   "cycle": "coding|plugin|prompt|tech",
#   "session_id": "session-id",
#   "agent": "agent-name or null",
#   "tool": "Edit|Write|NotebookEdit",
#   "file": "absolute-path",
#   "violation": "description",
#   "severity": "CRITICAL|HIGH|MEDIUM|LOW",
#   "blocking": true|false,
#   "context": {}
# }

set -euo pipefail

# Storage paths
readonly NOVACLOUD_HOME="${HOME}/.novacloud"
readonly OBSERVATIONS_DIR="${NOVACLOUD_HOME}/observations"
readonly VIOLATIONS_FILE="${OBSERVATIONS_DIR}/violations.jsonl"
readonly DEBUG_LOG="${HOME}/.claude/logs/hooks-debug.log"

# Debug logging function (fail-safe)
debug_log() {
    printf '[%s] [observe-violation] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
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

    # Append violation to JSONL file
    if ! printf '%s\n' "${violation_json}" >> "${VIOLATIONS_FILE}" 2>/dev/null; then
        debug_log "ERROR: Failed to append violation to ${VIOLATIONS_FILE}"
        exit 0
    fi

    debug_log "Violation logged successfully"
    exit 0
}

# Execute with fail-safe error handling
main "$@" || exit 0
