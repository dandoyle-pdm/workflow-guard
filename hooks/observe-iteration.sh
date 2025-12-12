#!/usr/bin/env bash
# observe-iteration.sh - Utility to log qc-router Loop 1 iteration data to JSONL
#
# Captures within-cycle iteration data for quality transformers (agents).
# This is fail-safe utility - logging failures must NOT break agent dispatch.
#
# Expected JSON input format:
# {
#   "type": "agent-dispatch",
#   "timestamp": "ISO-8601",
#   "resource": "agent",
#   "correlation": "ticket-id or session-id",
#   "iteration": {
#     "loop": 1,
#     "cycle": "plugin|coding|prompt|tech",
#     "agent": "plugin-engineer|code-developer|etc",
#     "sequence": 1,
#     "status": "started|completed|blocked",
#     "findings": []
#   }
# }
#
# Loop values:
#   1 - Within-cycle iteration (quality transformer feedback loops)
#   2 - Cross-cycle tuning (future - learning from completed tickets)
#   3 - System evolution (future - meta-level improvements)
#
# Cycle values:
#   plugin - Plugin engineering cycle (plugin-engineer → plugin-reviewer → plugin-tester)
#   coding - Code development cycle (code-developer → code-reviewer → code-tester)
#   prompt - Prompt engineering cycle (prompt-engineer → prompt-reviewer → prompt-tester)
#   tech   - Technical writing cycle (tech-writer → tech-editor → tech-publisher)
#
# Status values:
#   started   - Agent iteration began
#   completed - Agent iteration finished successfully
#   blocked   - Agent iteration encountered blocking issue
#
# Findings array:
#   List of issues discovered during the iteration (for completed/blocked status)

set -euo pipefail

# Storage paths
readonly NOVACLOUD_HOME="${HOME}/.novacloud"
readonly OBSERVATIONS_DIR="${NOVACLOUD_HOME}/observations"
readonly ITERATIONS_FILE="${OBSERVATIONS_DIR}/iterations.jsonl"
readonly DEBUG_LOG="${HOME}/.claude/logs/hooks-debug.log"

# Debug logging function (fail-safe)
debug_log() {
    printf '[%s] [observe-iteration] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Main execution
main() {
    # Read JSON from stdin
    local iteration_json
    if ! iteration_json=$(cat); then
        debug_log "ERROR: Failed to read iteration JSON from stdin"
        exit 0  # Fail-safe: don't break caller
    fi

    # Validate JSON is not empty
    if [[ -z "${iteration_json}" ]]; then
        debug_log "ERROR: Empty iteration JSON received"
        exit 0
    fi

    # Create observations directory if needed
    if ! mkdir -p "${OBSERVATIONS_DIR}" 2>/dev/null; then
        debug_log "ERROR: Failed to create observations directory: ${OBSERVATIONS_DIR}"
        exit 0
    fi

    # Append iteration to JSONL file
    if ! printf '%s\n' "${iteration_json}" >> "${ITERATIONS_FILE}" 2>/dev/null; then
        debug_log "ERROR: Failed to append iteration to ${ITERATIONS_FILE}"
        exit 0
    fi

    debug_log "Iteration logged successfully"
    exit 0
}

# Execute with fail-safe error handling
main "$@" || exit 0
