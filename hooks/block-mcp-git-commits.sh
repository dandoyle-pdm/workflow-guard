#!/usr/bin/env bash
# block-mcp-git-commits.sh - PreToolUse hook to block MCP git commit on protected branches
#
# This hook intercepts MCP git tools (mcp__git__git_commit, mcp__git__git_add) and blocks
# them when the current branch is a protected branch (main, master, production).
#
# MCP git tools bypass the Bash tool entirely, so they need their own hook matcher.
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

# Protected branches - can be extended via environment variable
readonly DEFAULT_PROTECTED_BRANCHES="main production master"
readonly PROTECTED_BRANCHES="${CLAUDE_PROTECTED_BRANCHES:-${DEFAULT_PROTECTED_BRANCHES}}"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [block-mcp-git-commits] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
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
    local repo_path="${1:-$(pwd)}"

    # Try to get branch from git
    if git -C "${repo_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${repo_path}" branch --show-current 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Generate helpful routing message
generate_error_message() {
    local current_branch="$1"
    local tool_name="$2"
    local repo_path="$3"

    cat <<EOFMSG

================================================================================
  MCP GIT OPERATION BLOCKED - Worktree Workflow Required
================================================================================

You are on branch '${current_branch}' (a protected branch) and attempted to
use MCP tool: ${tool_name}

Repository: ${repo_path}

Direct git operations on protected branches are not allowed.

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

1. Create a worktree for your work:
   git worktree add ~/workspace/worktrees/<project>/<branch-name> -b <branch-name>

2. Navigate to the worktree and make your changes:
   cd ~/workspace/worktrees/<project>/<branch-name>
   # ... make changes, commit freely ...

3. Push and create a Pull Request:
   git push -u origin <branch-name>
   gh pr create --base ${current_branch}

Alternatively, use the activate-ticket.sh script:
   ~/.claude/scripts/activate-ticket.sh tickets/queue/TICKET-xxx.md

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Worktrees isolate experimental changes from the main codebase
- Pull Requests enable code review before merging
- CI/CD pipelines validate changes before they reach ${current_branch}
- Atomic, reversible changes via PR merge/revert

--------------------------------------------------------------------------------
  TECHNICAL NOTE
--------------------------------------------------------------------------------

This protection applies to BOTH Bash git commands AND MCP git tools.
MCP tools (mcp__git__*) provide direct git operations but must still
follow branch protection rules.

================================================================================
EOFMSG
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name repo_path

    if command -v jq >/dev/null 2>&1; then
        # Use jq for reliable JSON parsing
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "${tool_name}" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        # Only process MCP git tools
        if [[ "${tool_name}" != "mcp__git__git_commit" && "${tool_name}" != "mcp__git__git_add" ]]; then
            exit 0
        fi

        debug_log "Processing MCP git tool: ${tool_name}"

        # Extract repo_path from tool_input
        # MCP git tools have structure: {"repo_path": "...", "message": "...", ...}
        if ! repo_path=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.repo_path // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse repo_path from tool_input"
            exit 0
        fi

        if [[ -z "${repo_path}" ]]; then
            debug_log "WARN: repo_path is empty, using cwd"
            repo_path=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null) || repo_path=$(pwd)
        fi
    else
        # Fallback to sed-based parsing (portable, no PCRE required)
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ "${tool_name}" != "mcp__git__git_commit" && "${tool_name}" != "mcp__git__git_add" ]]; then
            exit 0
        fi

        debug_log "Processing MCP git tool (sed): ${tool_name}"

        repo_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"repo_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")

        if [[ -z "${repo_path}" ]]; then
            repo_path=$(printf '%s\n' "${json_input}" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        fi

        if [[ -z "${repo_path}" ]]; then
            repo_path=$(pwd)
        fi
    fi

    debug_log "Repository path: ${repo_path}"

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch "${repo_path}")

    if [[ -z "${current_branch}" ]]; then
        debug_log "Could not determine current branch, allowing operation"
        exit 0
    fi

    debug_log "Current branch: ${current_branch}"

    # Check if on protected branch
    if is_protected_branch "${current_branch}"; then
        # Block the operation
        generate_error_message "${current_branch}" "${tool_name}" "${repo_path}" >&2

        # Log for audit
        debug_log "AUDIT: Blocked MCP git operation on protected branch - tool=${tool_name}, branch=${current_branch}, repo=${repo_path}"

        # Exit code 2 blocks the tool execution
        exit 2
    fi

    debug_log "Branch ${current_branch} is not protected, allowing MCP git operation"

    # Allow the operation
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
