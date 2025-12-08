#!/usr/bin/env bash
# validate-ticket-naming.sh - PreToolUse hook to validate ticket naming conventions
#
# This hook intercepts Write tool calls on ticket files and validates:
# 1. Ticket filename follows pattern: TICKET-{session-id}-{sequence}.md
#    - session-id: lowercase with hyphens (e.g., quality-gate, activate-fix)
#    - sequence: 3-digit number (e.g., 001, 002)
# 2. Ticket directory uses session-id (not full ticket name)
#    - Correct: tickets/active/quality-gate/TICKET-quality-gate-001.md
#    - Wrong: tickets/active/TICKET-quality-gate-001/TICKET-quality-gate-001.md
#
# Security hardened following patterns from existing hooks:
# - Command injection prevention via printf instead of echo
# - Proper jq error handling
# - Input validation
# - Audit logging

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Ticket filename pattern: TICKET-{session-id}-{sequence}.md
# session-id: lowercase letters, numbers, hyphens (no uppercase)
# sequence: exactly 3 digits
readonly TICKET_FILENAME_PATTERN='^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$'

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [validate-ticket-naming] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Extract session-id from ticket filename
# TICKET-quality-gate-001.md -> quality-gate
extract_session_id() {
    local filename="$1"
    # Remove TICKET- prefix and -NNN.md suffix
    echo "$filename" | sed 's/^TICKET-//;s/-[0-9]\{3\}\.md$//'
}

# Validate ticket filename pattern
validate_filename() {
    local filename="$1"

    if [[ ! "$filename" =~ $TICKET_FILENAME_PATTERN ]]; then
        return 1
    fi

    return 0
}

# Validate directory uses session-id
validate_directory() {
    local file_path="$1"
    local filename="$2"

    # Check if path contains tickets/ directory
    if [[ ! "$file_path" =~ tickets/ ]]; then
        # Not a ticket path, skip validation
        return 0
    fi

    # Exception: tickets/queue/ doesn't follow session-id directory pattern
    # Queue files are created BEFORE activation, so they can't have session-id directories yet
    if [[ "$file_path" =~ tickets/queue/ ]]; then
        debug_log "Queue directory exception - skipping directory structure validation"
        return 0
    fi

    # Extract session-id from filename
    local session_id
    session_id=$(extract_session_id "$filename")

    # Extract the immediate parent directory
    local parent_dir
    parent_dir=$(dirname "$file_path")
    local dir_name
    dir_name=$(basename "$parent_dir")

    # Directory name should match session-id
    # Only enforced for tickets/active/ and tickets/completed/
    if [[ "$dir_name" != "$session_id" ]]; then
        debug_log "ERROR: Directory name '$dir_name' does not match session-id '$session_id'"
        return 1
    fi

    return 0
}

# Generate helpful error message
generate_error_message() {
    local file_path="$1"
    local filename="$2"
    local error_type="$3"

    cat <<EOFMSG

================================================================================
  TICKET NAMING VALIDATION FAILED
================================================================================

File: ${file_path}

EOFMSG

    if [[ "$error_type" == "filename" ]]; then
        cat <<EOFMSG
ERROR: Invalid ticket filename format

The filename must follow this pattern:
  TICKET-{session-id}-{sequence}.md

Where:
  - session-id: lowercase letters, numbers, hyphens (e.g., quality-gate, activate-fix)
  - sequence: exactly 3 digits (e.g., 001, 002, 003)

Examples of VALID filenames:
  ✓ TICKET-quality-gate-001.md
  ✓ TICKET-activate-fix-001.md
  ✓ TICKET-foo-002.md
  ✓ TICKET-my-feature-123.md

Examples of INVALID filenames:
  ✗ TICKET-Quality-Gate-001.md  (uppercase not allowed)
  ✗ TICKET-quality_gate-001.md  (underscores not allowed)
  ✗ TICKET-quality-gate-01.md   (sequence must be 3 digits)
  ✗ ticket-quality-gate-001.md  (must start with TICKET-)

EOFMSG
    elif [[ "$error_type" == "directory" ]]; then
        local session_id
        session_id=$(extract_session_id "$filename")
        cat <<EOFMSG
ERROR: Directory name does not match session-id

The ticket file must be placed in a directory matching its session-id.
This validation applies to tickets/active/ and tickets/completed/ only.
(tickets/queue/ is exempt - files are placed there before activation)

For filename: ${filename}
Expected directory: tickets/*/${session_id}/
Found directory: $(dirname "$file_path")

Examples of CORRECT paths:
  ✓ tickets/queue/TICKET-quality-gate-001.md           (queue is flat, no subdirs)
  ✓ tickets/active/quality-gate/TICKET-quality-gate-001.md
  ✓ tickets/active/quality-gate/TICKET-quality-gate-002.md
  ✓ tickets/completed/activate-fix/TICKET-activate-fix-001.md

Examples of INCORRECT paths:
  ✗ tickets/active/TICKET-quality-gate-001/TICKET-quality-gate-001.md
  ✗ tickets/active/quality-gate-001/TICKET-quality-gate-001.md
  ✗ tickets/active/qg/TICKET-quality-gate-001.md

EOFMSG
    fi

    cat <<EOFMSG

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Consistent naming enables automation (activate-ticket.sh, complete-ticket.sh)
- Session-id based directories allow multiple sequential tickets (001, 002, etc.)
- Lowercase-with-hyphens prevents case-sensitivity issues across platforms
- Automated workflows rely on these patterns to function correctly

================================================================================
EOFMSG
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name file_path

    if command -v jq >/dev/null 2>&1; then
        # Use jq for reliable JSON parsing
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "${tool_name}" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        # Only process Write tool
        if [[ "${tool_name}" != "Write" ]]; then
            exit 0
        fi

        debug_log "Processing tool: ${tool_name}"

        # Extract file_path from tool_input
        if ! file_path=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.file_path // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse file_path from tool_input"
            exit 0
        fi

        if [[ -z "${file_path}" ]]; then
            debug_log "WARN: file_path is empty, allowing operation"
            exit 0
        fi
    else
        # Fallback to sed-based parsing (portable, no PCRE required)
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ "${tool_name}" != "Write" ]]; then
            exit 0
        fi

        debug_log "Processing tool (sed): ${tool_name}"

        file_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ -z "${file_path}" ]]; then
            debug_log "WARN: file_path is empty (sed), allowing operation"
            exit 0
        fi
    fi

    debug_log "File path: ${file_path}"

    # Only validate files in tickets/ directory
    if [[ ! "$file_path" =~ tickets/ ]]; then
        debug_log "Not a ticket file, skipping validation"
        exit 0
    fi

    # Extract filename
    local filename
    filename=$(basename "${file_path}")

    # Only validate TICKET-*.md files
    if [[ ! "$filename" =~ ^TICKET-.*\.md$ ]]; then
        debug_log "Not a TICKET-*.md file, skipping validation"
        exit 0
    fi

    debug_log "Validating ticket file: ${filename}"

    # Validate filename pattern
    if ! validate_filename "${filename}"; then
        generate_error_message "${file_path}" "${filename}" "filename" >&2
        debug_log "AUDIT: Blocked invalid ticket filename - file=${file_path}"
        exit 2
    fi

    # Validate directory naming
    if ! validate_directory "${file_path}" "${filename}"; then
        generate_error_message "${file_path}" "${filename}" "directory" >&2
        debug_log "AUDIT: Blocked invalid ticket directory - file=${file_path}"
        exit 2
    fi

    debug_log "Ticket naming validation passed: ${file_path}"

    # Allow the operation
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
