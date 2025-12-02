#!/usr/bin/env bash
# enforce-ticket-completion.sh - PreToolUse hook to enforce ticket in completed/ before PR
#
# Detects `gh pr create` commands and verifies that:
# 1. We're in a worktree (not main repo)
# 2. The ticket for this branch is in tickets/completed/<branch>/
#
# Blocks PR creation if ticket is still in active/ or queue/

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Create log directory
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    printf '[%s] [enforce-ticket-completion] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# Get the branch directory name
get_branch_dir() {
    local branch="$1"
    echo "$branch" | tr '/' '-'
}

# Check if we're in a worktree
is_worktree() {
    local cwd="$1"
    local git_dir
    git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || echo "")
    [[ "$git_dir" == *".git/worktrees/"* ]]
}

# Get current branch
get_current_branch() {
    local cwd="$1"
    git -C "$cwd" branch --show-current 2>/dev/null || echo ""
}

# Check if ticket is in completed/
check_ticket_completed() {
    local cwd="$1"
    local branch_dir="$2"

    local completed_path="${cwd}/tickets/completed/${branch_dir}"

    if [[ -d "$completed_path" ]]; then
        # Check for ticket file
        if find "$completed_path" -name "TICKET-*.md" -type f 2>/dev/null | grep -q .; then
            return 0
        fi
    fi

    return 1
}

# Check if ticket is in active/
check_ticket_active() {
    local cwd="$1"
    local branch_dir="$2"

    local active_path="${cwd}/tickets/active/${branch_dir}"

    if [[ -d "$active_path" ]]; then
        if find "$active_path" -name "TICKET-*.md" -type f 2>/dev/null | grep -q .; then
            return 0
        fi
    fi

    return 1
}

# Generate error message
generate_error_message() {
    local branch="$1"
    local branch_dir="$2"

    cat <<EOFMSG

================================================================================
  PR BLOCKED - Ticket Not in completed/
================================================================================

Before creating a PR, you must move the ticket to completed/:

Current ticket location: tickets/active/${branch_dir}/
Required location:       tickets/completed/${branch_dir}/

--------------------------------------------------------------------------------
  TO FIX
--------------------------------------------------------------------------------

Run the completion script:
  ~/.claude/scripts/complete-ticket.sh

This will:
  1. Move ticket from active/ to completed/
  2. Update ticket status to 'approved'
  3. Commit the change

Then retry:
  gh pr create --base main

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

The ticket completion is part of the work product. By moving to completed/
before PR creation, the ticket status is included in the squash merge,
keeping the ticket lifecycle atomic with the code changes.

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
        tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || tool_name=""
        cwd=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null) || cwd=""
        command=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.command // ""' 2>/dev/null) || command=""
    else
        # Fallback to sed-based parsing
        tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        cwd=$(printf '%s\n' "${json_input}" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
        command=$(printf '%s\n' "${json_input}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
    fi

    # Only process Bash tool
    if [[ "${tool_name}" != "Bash" ]]; then
        exit 0
    fi

    # Use current directory if cwd not provided
    if [[ -z "${cwd}" ]]; then
        cwd=$(pwd)
    fi

    debug_log "Checking command: ${command:0:100}"

    # Quick check: is this a gh pr create command?
    if [[ ! "${command}" =~ gh[[:space:]]+pr[[:space:]]+create ]]; then
        exit 0
    fi

    debug_log "PR create command detected, checking ticket status..."

    # Check if we're in a worktree
    if ! is_worktree "$cwd"; then
        debug_log "Not in a worktree, skipping ticket check"
        exit 0
    fi

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch "$cwd")

    if [[ -z "$current_branch" ]]; then
        debug_log "Could not determine current branch"
        exit 0
    fi

    # Skip if on protected branch (shouldn't happen, but safety)
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        debug_log "On protected branch, skipping"
        exit 0
    fi

    local branch_dir
    branch_dir=$(get_branch_dir "$current_branch")

    debug_log "Checking ticket status for branch: $current_branch (dir: $branch_dir)"

    # Check if ticket is in completed/
    if check_ticket_completed "$cwd" "$branch_dir"; then
        debug_log "Ticket found in completed/ - allowing PR creation"
        exit 0
    fi

    # Check if ticket is in active/ (common case - needs to be moved)
    if check_ticket_active "$cwd" "$branch_dir"; then
        debug_log "BLOCKED: Ticket still in active/, not completed/"
        generate_error_message "$current_branch" "$branch_dir" >&2
        exit 2
    fi

    # No ticket found at all - warn but allow (might be non-ticket work)
    debug_log "No ticket found for branch - allowing PR (might be non-ticket work)"
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
