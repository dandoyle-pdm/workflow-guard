#!/usr/bin/env bash
# detect-protected-commits.sh - PostToolUse hook to detect commits on protected branches
#
# This hook runs AFTER git commit commands complete (PostToolUse hook) and detects
# when commits land on protected branches. This provides comprehensive detection
# for scenarios where PreToolUse hooks are bypassed due to allowlisted commands.
#
# WHY THIS EXISTS:
# The `git commit` command is in Claude Code's allowlist, meaning PreToolUse hooks
# never evaluate it. This creates a detection gap. PostToolUse hooks DO fire for
# allowlisted commands (after execution), so this hook provides after-the-fact
# detection and violation logging.
#
# IMPORTANT: This is detection-only, not blocking. The commit has already happened
# when this hook runs. We log violations for audit/alerting purposes.
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

# Color codes for warning messages
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
    printf '[%s] [detect-protected-commits] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
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

# Generate warning message (shown to user)
generate_warning_message() {
    local current_branch="$1"
    local command="$2"
    local commit_sha="$3"

    cat <<EOFMSG

================================================================================
  WARNING: Protected Branch Commit Detected
================================================================================

A commit was made to protected branch '${current_branch}':
  Command: ${command:0:80}
  Commit:  ${commit_sha}

This commit has been logged for audit purposes.

Protected branches should use worktree + PR workflow for changes.

Next steps:
  1. If this was intentional (e.g., ticket lifecycle), no action needed
  2. If unintentional, consider reverting: git reset --soft HEAD~1
  3. Follow worktree workflow for future changes

See: ~/.claude/logs/hooks-debug.log for details
================================================================================
EOFMSG
}

# Check if staged changes are ticket lifecycle only
# Returns 0 if ONLY ticket files modified, 1 otherwise
is_ticket_lifecycle_only() {
    local commit_sha="$1"

    # Get files changed in the commit
    local changed_files
    changed_files=$(git diff-tree --no-commit-id --name-only -r "${commit_sha}" 2>/dev/null)

    # If no files, something is wrong
    [[ -z "$changed_files" ]] && return 1

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
    done <<< "$changed_files"

    debug_log "Ticket lifecycle commit validated (all files are valid ticket files)"
    return 0
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

    debug_log "PostToolUse checking command: ${command:0:100}"

    # Quick check: is this a git commit command?
    if ! is_git_commit_command "${command}"; then
        exit 0
    fi

    debug_log "Git commit command detected, checking if on protected branch..."

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch "${cwd}")

    if [[ -z "${current_branch}" ]]; then
        debug_log "Could not determine current branch, skipping detection"
        exit 0
    fi

    debug_log "Current branch: ${current_branch}"

    # Check if on protected branch
    if is_protected_branch "${current_branch}"; then
        # Get the commit SHA (HEAD after commit)
        local commit_sha
        commit_sha=$(git -C "${cwd}" rev-parse HEAD 2>/dev/null || echo "unknown")

        debug_log "DETECTED: Commit on protected branch - branch=${current_branch}, commit=${commit_sha}"

        # Exception: Allow ticket lifecycle commits
        if is_ticket_lifecycle_only "${commit_sha}"; then
            debug_log "ALLOWED: Ticket lifecycle commit detected (commit=${commit_sha})"
            debug_log "AUDIT: Ticket lifecycle commit on protected branch - branch=${current_branch}, commit=${commit_sha}"
            exit 0
        fi

        # Log violation for QC Observer (fail-safe - errors won't break hook)
        # Use jq for safe JSON construction to prevent injection attacks
        local violation_json
        violation_json=$(jq -n \
            --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
            --arg tool "Bash" \
            --arg cmd "${command:0:200}" \
            --arg branch "${current_branch}" \
            --arg sha "${commit_sha}" \
            '{
                "type": "workflow-guard",
                "timestamp": $ts,
                "observation_type": "detection",
                "cycle": "inferred",
                "session_id": "",
                "agent": null,
                "tool": $tool,
                "tool_input": {"command": $cmd},
                "violation": "protected_branch_commit_detected",
                "severity": "HIGH",
                "blocking": false,
                "context": {
                    "branch": $branch,
                    "commit_sha": $sha,
                    "protected_branches": "main,master,production",
                    "detection_type": "PostToolUse"
                }
            }' 2>/dev/null || true)

        if [[ -n "${violation_json}" ]]; then
            printf '%s' "${violation_json}" | "${SCRIPT_DIR}/observe-violation.sh" 2>/dev/null || true
        fi

        # Show warning message to user (non-blocking)
        generate_warning_message "${current_branch}" "${command}" "${commit_sha}" >&2

        # Log for audit
        debug_log "AUDIT: Protected branch commit detected (PostToolUse) - branch=${current_branch}, commit=${commit_sha}, command=${command:0:100}"

        # Exit 0 - this is detection only, not blocking
        exit 0
    fi

    debug_log "Branch ${current_branch} is not protected, commit allowed"

    # Allow the operation
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
