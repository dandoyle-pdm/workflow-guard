#!/usr/bin/env bash
# block-unreviewed-edits.sh - PreToolUse hook to enforce quality agent context for file edits
#
# This hook intercepts Edit, Write, and NotebookEdit tool invocations and blocks them
# unless a quality agent context is detected in the transcript OR the file is a
# workflow metadata file (tickets, handoffs).
#
# This ensures all file modifications go through appropriate quality cycles:
# - Code: code-developer → code-reviewer → code-tester
# - Plugin: plugin-engineer → plugin-reviewer → plugin-tester
# - Prompt: prompt-engineer → prompt-reviewer → prompt-tester
# - Documentation: tech-writer → tech-editor → tech-publisher
#
# Security hardened following patterns from block-main-commits.sh:
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
readonly DEFAULT_QUALITY_AGENTS="code-developer,code-reviewer,code-tester,plugin-engineer,plugin-reviewer,plugin-tester,prompt-engineer,prompt-reviewer,prompt-tester,tech-writer,tech-editor,tech-publisher"
readonly QUALITY_AGENTS="${CLAUDE_QUALITY_AGENTS:-${DEFAULT_QUALITY_AGENTS}}"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [block-unreviewed-edits] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Check if file path is a workflow metadata file (tickets, handoffs)
is_workflow_metadata() {
    local file_path="$1"

    # Extract filename
    local filename
    filename=$(basename "$file_path")

    # Canonicalize path to resolve any traversal sequences
    local canonical_path
    if [[ -e "$file_path" ]]; then
        canonical_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
    else
        # For new files, canonicalize the directory portion
        local dir_path
        dir_path=$(dirname "$file_path")
        if [[ -d "$dir_path" ]]; then
            canonical_path="$(realpath "$dir_path" 2>/dev/null)/${filename}"
        else
            canonical_path="$file_path"
        fi
    fi

    debug_log "Canonical path: ${canonical_path}"

    # Check if canonical path contains /tickets/ as a proper directory component
    if [[ "$canonical_path" =~ (^|/)tickets/ ]] && [[ "$filename" =~ ^TICKET-.*\.md$ ]]; then
        debug_log "Workflow metadata: ticket file ($canonical_path)"
        return 0
    fi

    # Check if file is a handoff file
    if [[ "$filename" =~ ^HANDOFF.*\.md$ ]]; then
        debug_log "Workflow metadata: handoff file ($filename)"
        return 0
    fi

    return 1
}

# Check if transcript contains quality agent identity
# Returns 0 if quality agent detected, 1 otherwise
has_quality_agent_context() {
    local transcript_path="$1"

    # Validate transcript path exists
    if [[ ! -f "$transcript_path" ]]; then
        debug_log "WARNING: Transcript file not found: $transcript_path"
        return 1
    fi

    # Validate QUALITY_AGENTS contains only safe characters (alphanumeric, comma, hyphen, underscore)
    if [[ ! "${QUALITY_AGENTS}" =~ ^[a-zA-Z0-9,_-]+$ ]]; then
        debug_log "ERROR: Invalid QUALITY_AGENTS format, blocking operation"
        exit 2  # Block on invalid configuration - fail-secure
    fi

    # Convert comma-separated list to pipe-separated for grep regex
    local agent_pattern
    agent_pattern=$(printf '%s' "${QUALITY_AGENTS}" | sed 's/,/|/g')

    # Search for agent identity pattern in transcript
    # Pattern: "working as the {agent-name} agent"
    if grep -qE "working as the (${agent_pattern}) agent" "$transcript_path" 2>/dev/null; then
        local detected_agent
        detected_agent=$(grep -oE "working as the (${agent_pattern}) agent" "$transcript_path" 2>/dev/null | head -1 || echo "unknown")
        debug_log "Quality agent detected: $detected_agent"
        return 0
    fi

    debug_log "No quality agent context detected in transcript"
    return 1
}

# Generate helpful guidance message
generate_error_message() {
    local file_path="$1"
    local tool_name="$2"

    cat <<EOFMSG

================================================================================
  QUALITY TRANSFORMER REQUIRED - Quality Cycle Enforcement
================================================================================

You attempted to ${tool_name} a file without quality agent context:
  ${file_path}

All file modifications require a quality agent context to ensure proper
review and validation cycles.

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

Use qc-router to dispatch the appropriate quality agent for your task:

  For implementation work:
    - Code:          code-developer
    - Plugins:       plugin-engineer
    - Prompts:       prompt-engineer
    - Documentation: tech-writer

  For review work:
    - Code:          code-reviewer
    - Plugins:       plugin-reviewer
    - Prompts:       prompt-reviewer
    - Documentation: tech-editor

  For testing/validation:
    - Code:          code-tester
    - Plugins:       plugin-tester
    - Prompts:       prompt-tester
    - Documentation: tech-publisher

Example dispatch using Task tool:
  Task(subagent_type="general-purpose",
       prompt="You are the plugin-engineer agent...")

See: ~/.claude/plugins/qc-router/agents/ for agent definitions

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Quality cycles ensure systematic Creator → Critic → Judge review
- Prevents accidental modifications outside review process
- Maintains audit trail of who reviewed and approved changes
- Ensures test coverage and validation before integration

Exceptions: Workflow metadata (tickets/**, HANDOFF*.md) can be edited directly
as they are session coordination, not production code.

================================================================================
EOFMSG
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name file_path transcript_path

    if command -v jq >/dev/null 2>&1; then
        # Use jq for reliable JSON parsing
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "${tool_name}" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        # Only process Edit, Write, NotebookEdit tools
        if [[ ! "${tool_name}" =~ ^(Edit|Write|NotebookEdit)$ ]]; then
            exit 0
        fi

        if ! file_path=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse file_path from JSON"
            exit 0
        fi

        if ! transcript_path=$(printf '%s\n' "${json_input}" | jq -r '.transcript_path // ""' 2>/dev/null); then
            debug_log "WARNING: Failed to parse transcript_path from JSON"
            transcript_path=""
        fi
    else
        # Fallback to sed-based parsing (portable, no PCRE required)
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ ! "${tool_name}" =~ ^(Edit|Write|NotebookEdit)$ ]]; then
            exit 0
        fi

        # Try file_path first, then notebook_path
        file_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        if [[ -z "${file_path}" ]]; then
            file_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"notebook_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        fi

        transcript_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Validate we got a file path
    if [[ -z "${file_path}" ]]; then
        debug_log "ERROR: Could not extract file_path from tool input"
        exit 0
    fi

    debug_log "Checking ${tool_name} operation on: ${file_path}"

    # Exception 1: Workflow metadata files (tickets, handoffs)
    if is_workflow_metadata "${file_path}"; then
        debug_log "ALLOWED: Workflow metadata file exception"
        exit 0
    fi

    # Exception 2: Quality agent context detected
    if [[ -n "${transcript_path}" ]] && has_quality_agent_context "${transcript_path}"; then
        debug_log "ALLOWED: Quality agent context detected"
        debug_log "AUDIT: Quality agent edit - tool=${tool_name}, file=${file_path}"
        exit 0
    fi

    # Block the operation - no quality agent context
    generate_error_message "${file_path}" "${tool_name}" >&2

    # Log for audit
    debug_log "AUDIT: Blocked ${tool_name} without quality agent - file=${file_path}"

    # Exit code 2 blocks the tool execution
    exit 2
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
