#!/usr/bin/env bash
# block-main-commits.sh - PreToolUse hook to block git commit on protected branches
#
# This hook intercepts `git commit` commands and blocks them when the current
# branch is a protected branch (main, master, production). This ensures all
# changes go through the worktree + PR workflow.
#
# Security hardened following patterns from enforce-pr-workflow.sh:
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

# Protected branches - can be extended via environment variable
readonly DEFAULT_PROTECTED_BRANCHES="main production master"
readonly PROTECTED_BRANCHES="${CLAUDE_PROTECTED_BRANCHES:-${DEFAULT_PROTECTED_BRANCHES}}"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [block-main-commits] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Check if staged changes are ticket lifecycle only
# Returns 0 if ONLY ticket files modified, 1 otherwise
is_ticket_lifecycle_only() {
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null)

    # If no staged files, not a ticket lifecycle commit
    [[ -z "$staged_files" ]] && return 1

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        # Must be in ticket workflow directories
        if [[ ! "$file" =~ ^tickets/(queue|active|completed|archive)/ ]]; then
            debug_log "Non-ticket directory: $file"
            return 1
        fi

        # Extract filename from path
        local filename
        filename=$(basename "$file")

        # Must be a ticket or handoff markdown file
        if [[ ! "$filename" =~ ^(TICKET|HANDOFF)-[a-zA-Z0-9-]+\.md$ ]]; then
            debug_log "Invalid ticket filename: $filename (must be TICKET-*.md or HANDOFF-*.md)"
            return 1
        fi
    done <<< "$staged_files"

    debug_log "Ticket lifecycle commit validated (all files are valid ticket files)"
    return 0
}

# Check if a branch name is protected
is_protected_branch() {
    local branch="$1"

    # Strip origin/ prefix if present for comparison
    local clean_branch="${branch#origin/}"

    # Convert space-separated string to array for safe iteration
    local protected_array=()
    read -ra protected_array <<< "${PROTECTED_BRANCHES}"

    for protected in "${protected_array[@]}"; do
        if [[ "${clean_branch}" == "${protected}" ]]; then
            return 0
        fi
    done

    return 1
}

# Get the current git branch
get_current_branch() {
    local cwd="${1:-$(pwd)}"

    # Try to get branch from git
    if git -C "${cwd}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${cwd}" branch --show-current 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if command is a git commit
is_git_commit_command() {
    local command="$1"

    # Normalize whitespace
    local normalized_cmd
    normalized_cmd=$(printf '%s' "${command}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Match git commit patterns
    # Handles: git commit, git commit -m "msg", git commit --amend, etc.
    if [[ "${normalized_cmd}" =~ ^git[[:space:]]+commit([[:space:]]|$) ]]; then
        return 0
    fi

    # Also catch: git -C /path commit, git --git-dir=/path commit
    if [[ "${normalized_cmd}" =~ ^git[[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+[[:space:]]+|--git-dir=[^[:space:]]+[[:space:]]+|--work-tree=[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$) ]]; then
        return 0
    fi

    return 1
}

# Generate helpful routing message
generate_error_message() {
    local current_branch="$1"
    local command="$2"

    cat <<EOFMSG

================================================================================
  DIRECT COMMIT BLOCKED - Worktree Workflow Required
================================================================================

You are on branch '${current_branch}' (a protected branch) and attempted to
run: ${command:0:80}

Direct commits to protected branches are not allowed.

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

1. Create a worktree for your work:
   git worktree add \$WORKTREE_BASE/<project>/<branch-name> -b <branch-name>

2. Navigate to the worktree and make your changes:
   cd \$WORKTREE_BASE/<project>/<branch-name>
   # ... make changes, commit freely ...

3. Push and create a Pull Request:
   git push -u origin <branch-name>
   gh pr create --base ${current_branch}

Alternatively, use the activate-ticket.sh script:
   scripts/activate-ticket.sh tickets/queue/TICKET-xxx.md

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Worktrees isolate experimental changes from the main codebase
- Pull Requests enable code review before merging
- CI/CD pipelines validate changes before they reach ${current_branch}
- Atomic, reversible changes via PR merge/revert

================================================================================
EOFMSG
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name cwd command

    if command -v jq >/dev/null 2>&1; then
        # Use jq for reliable JSON parsing
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "${tool_name}" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        cwd=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null) || cwd=""

        # Only process Bash tool
        if [[ "${tool_name}" != "Bash" ]]; then
            exit 0
        fi

        if ! command=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.command // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse command from JSON"
            exit 0
        fi
    else
        # Fallback to sed-based parsing (portable, no PCRE required)
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ "${tool_name}" != "Bash" ]]; then
            exit 0
        fi

        cwd=$(printf '%s\n' "${json_input}" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        command=$(printf '%s\n' "${json_input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Use current directory if cwd not provided
    if [[ -z "${cwd}" ]]; then
        cwd=$(pwd)
    fi

    debug_log "Checking command: ${command:0:100}"

    # Quick check: is this a git commit command?
    if ! is_git_commit_command "${command}"; then
        exit 0
    fi

    debug_log "Git commit command detected, checking branch..."

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch "${cwd}")

    if [[ -z "${current_branch}" ]]; then
        debug_log "Could not determine current branch, allowing operation"
        exit 0
    fi

    debug_log "Current branch: ${current_branch}"

    # Check if on protected branch
    if is_protected_branch "${current_branch}"; then
        # Exception: Allow ticket lifecycle commits on protected branches
        if is_ticket_lifecycle_only; then
            debug_log "ALLOWED: Ticket lifecycle commit on protected branch"
            debug_log "AUDIT: Ticket lifecycle commit - branch=${current_branch}, files=$(git diff --cached --name-only 2>/dev/null | tr '\n' ' ')"
            exit 0
        fi

        # Block the commit
        generate_error_message "${current_branch}" "${command}" >&2

        # Log for audit
        debug_log "AUDIT: Blocked git commit on protected branch - branch=${current_branch}, command=${command:0:100}"

        # Exit code 2 blocks the tool execution
        exit 2
    fi

    debug_log "Branch ${current_branch} is not protected, allowing commit"

    # Allow the operation
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
