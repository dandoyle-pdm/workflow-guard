#!/usr/bin/env bash
# confirm-code-edits.sh - PreToolUse hook to require confirmation for code file edits
#
# This hook intercepts Edit/Write tool calls on code files and blocks them unless
# the user has explicitly requested the edit. This prevents unintended modifications
# during investigation or read-only workflows.
#
# Security hardened following patterns from block-mcp-git-commits.sh:
# - Command injection prevention via printf instead of echo
# - Proper jq error handling
# - Input validation
# - Audit logging

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Default code file extensions - can be overridden via environment variable
readonly DEFAULT_CODE_EXTENSIONS="go,py,sh,js,ts,tsx,jsx"
readonly CODE_FILE_EXTENSIONS="${CODE_FILE_EXTENSIONS:-${DEFAULT_CODE_EXTENSIONS}}"

# Test file patterns to allow without confirmation
readonly TEST_PATTERNS=(
    "_test.go$"
    "^test_.*\.py$"
    "_test\.py$"
    "\.test\.js$"
    "\.test\.ts$"
    "\.spec\.js$"
    "\.spec\.ts$"
    "\.test\.jsx$"
    "\.test\.tsx$"
    "\.spec\.jsx$"
    "\.spec\.tsx$"
)

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [confirm-code-edits] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Check if skip confirmation is enabled
should_skip_confirmation() {
    if [[ "${SKIP_EDIT_CONFIRMATION:-}" == "true" ]]; then
        debug_log "SKIP_EDIT_CONFIRMATION=true, allowing operation"
        return 0
    fi
    return 1
}

# Check if path contains /tickets/ directory
is_ticket_path() {
    local file_path="$1"
    if [[ "${file_path}" == */tickets/* ]]; then
        return 0
    fi
    return 1
}

# Check if filename matches test patterns
is_test_file() {
    local file_path="$1"
    local filename
    filename=$(basename "${file_path}")

    for pattern in "${TEST_PATTERNS[@]}"; do
        if [[ "${filename}" =~ ${pattern} ]]; then
            return 0
        fi
    done

    return 1
}

# Extract file extension
get_file_extension() {
    local file_path="$1"
    local filename
    filename=$(basename "${file_path}")

    # Handle files with no extension
    if [[ "${filename}" != *.* ]]; then
        echo ""
        return
    fi

    # Extract extension (everything after last dot)
    local ext="${filename##*.}"
    echo "${ext}"
}

# Check if extension is a code file extension
is_code_extension() {
    local ext="$1"

    # Convert comma-separated string to array
    local extensions_array=()
    IFS=',' read -ra extensions_array <<< "${CODE_FILE_EXTENSIONS}"

    for code_ext in "${extensions_array[@]}"; do
        # Trim whitespace
        code_ext=$(echo "${code_ext}" | xargs)
        if [[ "${ext}" == "${code_ext}" ]]; then
            return 0
        fi
    done

    return 1
}

# Generate confirmation message
generate_confirmation_message() {
    local file_path="$1"
    local tool_name="$2"

    cat <<EOFMSG

================================================================================
  CODE EDIT CONFIRMATION REQUIRED
================================================================================

File: ${file_path}
Tool: ${tool_name}

Did the user explicitly ask for this edit?

If YES: Ask the user to confirm, then retry this operation.
If NO:  Report your findings instead of making changes.

================================================================================
EOFMSG
}

# Main execution
main() {
    # Check if skip confirmation is enabled first
    if should_skip_confirmation; then
        exit 0
    fi

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

        # Only process Edit/Write tools
        if [[ "${tool_name}" != "Edit" && "${tool_name}" != "Write" ]]; then
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

        if [[ "${tool_name}" != "Edit" && "${tool_name}" != "Write" ]]; then
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

    # Check if path contains /tickets/ directory
    if is_ticket_path "${file_path}"; then
        debug_log "File is in tickets directory, allowing operation"
        exit 0
    fi

    # Check if file is a test file
    if is_test_file "${file_path}"; then
        debug_log "File is a test file, allowing operation"
        exit 0
    fi

    # Extract file extension
    local file_ext
    file_ext=$(get_file_extension "${file_path}")

    if [[ -z "${file_ext}" ]]; then
        debug_log "File has no extension, allowing operation"
        exit 0
    fi

    debug_log "File extension: ${file_ext}"

    # Check if extension is a code file extension
    if ! is_code_extension "${file_ext}"; then
        debug_log "File extension ${file_ext} is not a code extension, allowing operation"
        exit 0
    fi

    # Block the operation with confirmation message
    generate_confirmation_message "${file_path}" "${tool_name}" >&2

    # Log for audit
    debug_log "AUDIT: Blocked code edit - tool=${tool_name}, file=${file_path}"

    # Exit code 1 blocks with message (exit 2 would be silent)
    exit 1
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
