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

# Check if file is a ticket in queue/ without sequence number
# Pattern: tickets/queue/TICKET-{session-id}.md (no sequence)
is_ticket_queue_file() {
    local file_path="$1"

    # Normalize path
    local normalized_path
    normalized_path=$(printf '%s' "$file_path" | sed 's|//|/|g; s|/\./|/|g')

    # Match pattern: tickets/queue/TICKET-{session-id}.md (no -NNN sequence)
    if [[ "$normalized_path" =~ tickets/queue/TICKET-[a-zA-Z0-9_-]+\.md$ ]] && \
       [[ ! "$normalized_path" =~ tickets/queue/TICKET-[a-zA-Z0-9_-]+-[0-9]+\.md$ ]]; then
        debug_log "Ticket queue file detected (no sequence): $file_path"
        return 0
    fi

    return 1
}

# Check if file is a ticket with sequence number
# Pattern: tickets/*/TICKET-{session-id}-{sequence}.md
is_ticket_with_sequence() {
    local file_path="$1"

    # Normalize path
    local normalized_path
    normalized_path=$(printf '%s' "$file_path" | sed 's|//|/|g; s|/\./|/|g')

    # Match pattern: tickets/any-dir/TICKET-{session-id}-{sequence}.md
    if [[ "$normalized_path" =~ tickets/.*/TICKET-[a-zA-Z0-9_-]+-[0-9]+\.md$ ]]; then
        debug_log "Ticket with sequence detected: $file_path"
        return 0
    fi

    return 1
}

# Get current git branch
get_current_branch() {
    local cwd="${1:-$(pwd)}"

    # Try to get branch from git
    if git -C "${cwd}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${cwd}" branch --show-current 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if branch is protected
is_protected_branch() {
    local branch="$1"

    # Protected branches - can be extended via environment variable
    local default_protected="main master production"
    local protected_branches="${CLAUDE_PROTECTED_BRANCHES:-${default_protected}}"

    # Strip origin/ prefix if present
    local clean_branch="${branch#origin/}"

    # Convert space-separated string to array
    local protected_array=()
    read -ra protected_array <<< "${protected_branches}"

    for protected in "${protected_array[@]}"; do
        if [[ "${clean_branch}" == "${protected}" ]]; then
            return 0
        fi
    done

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
    local reason="${3:-no_agent}"

    if [[ "$reason" == "protected_branch" ]]; then
        cat <<EOFMSG

================================================================================
  WORKTREE REQUIRED - Protected Branch Write Restriction
================================================================================

You attempted to ${tool_name} a file on a protected branch:
  ${file_path}

Writes to protected branches must occur in worktrees, not directly on main.

--------------------------------------------------------------------------------
  TICKET LIFECYCLE RULES
--------------------------------------------------------------------------------

On protected branches (main/master/production):

  ALLOWED:
    - Ticket creation: tickets/queue/TICKET-{session-id}.md (no sequence)
    - Ticket lifecycle: activate-ticket.sh, complete-ticket.sh

  BLOCKED:
    - Tickets with sequence: tickets/*/TICKET-{session-id}-NNN.md
    - Implementation files: code, configs, docs
    - Any file modifications during development

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

1. Create ticket on main:
   Write tickets/queue/TICKET-my-work.md

2. Activate ticket (creates worktree):
   scripts/activate-ticket.sh tickets/queue/TICKET-my-work.md

3. Work in worktree:
   cd \$WORKTREE_BASE/<project>/<branch>
   # Make changes, commits happen here with sequence numbers

4. Complete and PR:
   scripts/complete-ticket.sh tickets/active/<branch>/TICKET-my-work-001.md
   gh pr create --base main

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Protected branches remain stable during development
- Worktrees isolate experimental changes
- Pull Requests enable review before merge
- Prevents accidental commits to main

================================================================================
EOFMSG
    else
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
    fi
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name file_path transcript_path cwd

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

        if ! cwd=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null); then
            cwd=""
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
        cwd=$(printf '%s\n' "${json_input}" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Fallback for subagent contexts where Claude Code passes /dev/null
    # This occurs when using the Task tool - the PreToolUse hook receives
    # transcript_path="/dev/null" instead of the actual transcript location
    if [[ "$transcript_path" == "/dev/null" || -z "$transcript_path" || ! -f "$transcript_path" ]]; then
        debug_log "Transcript path invalid or missing ($transcript_path), attempting fallback discovery"

        # Strategy 1: Try environment variable (can be set by wrapper scripts)
        if [[ -n "${CLAUDE_TRANSCRIPT_FILE:-}" && -f "${CLAUDE_TRANSCRIPT_FILE}" ]]; then
            transcript_path="${CLAUDE_TRANSCRIPT_FILE}"
            debug_log "Using CLAUDE_TRANSCRIPT_FILE fallback: $transcript_path"
        else
            # Strategy 2: Find most recent transcript in Claude projects directory
            # Security: Only search within ~/.claude/ to prevent path traversal
            local claude_projects="${CLAUDE_HOME}/projects"
            if [[ -d "$claude_projects" ]]; then
                # Find .jsonl files modified in last 5 minutes (active session)
                # Use -print0 and process substitution for safe path handling
                local found_transcript=""
                while IFS= read -r -d '' transcript; do
                    found_transcript="$transcript"
                    break
                done < <(find "$claude_projects" -name "*.jsonl" -type f -mmin -5 -print0 2>/dev/null |
                        xargs -0 -r ls -t 2>/dev/null | head -n1 | tr '\n' '\0')

                if [[ -n "$found_transcript" ]]; then
                    transcript_path="$found_transcript"
                    debug_log "Using discovered transcript fallback: $transcript_path"
                else
                    debug_log "No recent transcript found in $claude_projects"
                fi
            else
                debug_log "Claude projects directory not found: $claude_projects"
            fi
        fi
    fi

    # Validate we got a file path
    if [[ -z "${file_path}" ]]; then
        debug_log "ERROR: Could not extract file_path from tool input"
        exit 0
    fi

    debug_log "Checking ${tool_name} operation on: ${file_path}"

    # Exception 1: Workflow metadata files (tickets, handoffs) - but with branch rules
    if is_workflow_metadata "${file_path}"; then
        debug_log "Workflow metadata file detected, checking branch rules..."

        # Get current branch (use cwd if provided, else file's directory)
        local current_branch
        local branch_cwd="${cwd}"
        if [[ -z "${branch_cwd}" ]]; then
            debug_log "WARNING: cwd is empty, falling back to dirname for branch detection"
            branch_cwd=$(dirname "${file_path}")
        fi

        # Validate we're in a git repo before trusting branch detection
        if ! git -C "${branch_cwd}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            debug_log "BLOCKED: Cannot reliably determine branch (not in git repo) - fail-secure"
            printf '%sERROR: Cannot determine git branch for safe operation%s\n' "${RED}" "${NC}" >&2
            printf 'Directory checked: %s\n' "${branch_cwd}" >&2
            printf 'This operation requires reliable branch detection for security.\n' >&2
            exit 2
        fi

        current_branch=$(get_current_branch "${branch_cwd}")

        # If on protected branch, apply additional ticket rules
        if [[ -n "${current_branch}" ]] && is_protected_branch "${current_branch}"; then
            debug_log "On protected branch: ${current_branch}"

            # Allow ticket queue files (no sequence) on protected branches
            if is_ticket_queue_file "${file_path}"; then
                debug_log "ALLOWED: Ticket queue file on protected branch"
                exit 0
            fi

            # Block tickets with sequence numbers on protected branches
            if is_ticket_with_sequence "${file_path}"; then
                debug_log "BLOCKED: Ticket with sequence on protected branch (must use worktree)"
                generate_error_message "${file_path}" "${tool_name}" "protected_branch" >&2
                debug_log "AUDIT: Blocked ticket with sequence on protected branch - file=${file_path}, branch=${current_branch}"
                exit 2
            fi

            # Allow other workflow metadata (handoffs, ticket lifecycle scripts)
            debug_log "ALLOWED: Workflow metadata on protected branch"
            exit 0
        fi

        # Not on protected branch - allow all workflow metadata
        debug_log "ALLOWED: Workflow metadata file exception"
        exit 0
    fi

    # Exception 2: Quality agent context detected
    if [[ -n "${transcript_path}" ]] && has_quality_agent_context "${transcript_path}"; then
        debug_log "Quality agent context detected, checking branch rules..."

        # Get current branch (use cwd if provided, else file's directory)
        local current_branch
        local branch_cwd="${cwd}"
        if [[ -z "${branch_cwd}" ]]; then
            debug_log "WARNING: cwd is empty, falling back to dirname for branch detection"
            branch_cwd=$(dirname "${file_path}")
        fi

        # Validate we're in a git repo before trusting branch detection
        if ! git -C "${branch_cwd}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            debug_log "BLOCKED: Cannot reliably determine branch (not in git repo) - fail-secure"
            printf '%sERROR: Cannot determine git branch for safe operation%s\n' "${RED}" "${NC}" >&2
            printf 'Directory checked: %s\n' "${branch_cwd}" >&2
            printf 'This operation requires reliable branch detection for security.\n' >&2
            exit 2
        fi

        current_branch=$(get_current_branch "${branch_cwd}")

        # If on protected branch, block non-ticket file modifications
        if [[ -n "${current_branch}" ]] && is_protected_branch "${current_branch}"; then
            debug_log "BLOCKED: Quality agent write on protected branch (must use worktree)"
            generate_error_message "${file_path}" "${tool_name}" "protected_branch" >&2
            debug_log "AUDIT: Blocked quality agent write on protected branch - file=${file_path}, branch=${current_branch}"
            exit 2
        fi

        # Not on protected branch - allow with quality agent context
        debug_log "ALLOWED: Quality agent context detected"
        debug_log "AUDIT: Quality agent edit - tool=${tool_name}, file=${file_path}"
        exit 0
    fi

    # Block the operation - no quality agent context
    generate_error_message "${file_path}" "${tool_name}" "no_agent" >&2

    # Log for audit
    debug_log "AUDIT: Blocked ${tool_name} without quality agent - file=${file_path}"

    # Log violation for QC Observer (fail-safe - errors won't break blocking)
    # Use jq for safe JSON construction to prevent injection attacks
    local violation_json
    violation_json=$(jq -n \
        --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --arg tool "${tool_name}" \
        --arg file "${file_path}" \
        '{
            "type": "workflow-guard",
            "timestamp": $ts,
            "observation_type": "blocking",
            "cycle": "inferred",
            "session_id": "",
            "agent": null,
            "tool": $tool,
            "file": $file,
            "violation": "quality_bypass",
            "severity": "HIGH",
            "blocking": true,
            "context": {}
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
