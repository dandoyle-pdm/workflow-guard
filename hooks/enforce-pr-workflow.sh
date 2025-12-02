#!/usr/bin/env bash
# enforce-pr-workflow.sh - PreToolUse hook for PR workflow enforcement
#
# Detects and blocks direct merges to protected branches, routing users
# to the correct PR-based workflow with exact commands.
#
# Security hardened following patterns from enforce-quality-cycle.sh:
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
    printf '[%s] [enforce-pr-workflow] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${DEBUG_LOG}" 2>/dev/null || true
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

# Parse the merge target from a git merge command
parse_merge_target() {
    local command="$1"

    # Extract branch name from git merge command
    # Handles: git merge main, git merge origin/main, git merge --no-ff main, etc.

    # Remove leading/trailing whitespace and normalize
    local normalized_cmd
    normalized_cmd=$(printf '%s' "${command}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if this is a git merge command
    if [[ ! "${normalized_cmd}" =~ ^git[[:space:]]+merge ]]; then
        echo ""
        return
    fi

    # Extract arguments after 'git merge'
    local merge_args
    merge_args=$(printf '%s' "${normalized_cmd}" | sed 's/^git[[:space:]]\+merge[[:space:]]\+//')

    # Skip known flags and find the branch name
    local branch=""
    local skip_next=false

    # Use eval to properly parse quoted arguments
    # This is safe because we're only processing flags and branch names
    local -a args_array
    eval "args_array=(${merge_args})"

    for arg in "${args_array[@]}"; do
        # Skip this arg if previous flag consumed it
        if [[ "${skip_next}" == "true" ]]; then
            skip_next=false
            continue
        fi

        case "${arg}" in
            --)
                # Everything after -- is literal
                continue
                ;;
            --no-ff|--ff|--ff-only|--squash|--no-squash|--commit|--no-commit|--edit|--no-edit|--stat|--no-stat|--log|--no-log|--signoff|--no-signoff|--verify|--no-verify|--quiet|-q|--verbose|-v|--progress|--no-progress|--autostash|--no-autostash|--allow-unrelated-histories|--rerere-autoupdate|--no-rerere-autoupdate)
                continue
                ;;
            -m|--message|-S|--gpg-sign|-s|--strategy|-X|--strategy-option)
                # These flags take an argument - skip the next token
                skip_next=true
                continue
                ;;
            --message=*|--gpg-sign=*|--strategy=*|--strategy-option=*)
                # Long flags with = notation include their value
                continue
                ;;
            -*)
                # Other flags, skip
                continue
                ;;
            *)
                # This should be the branch name
                branch="${arg}"
                break
                ;;
        esac
    done

    printf '%s' "${branch}"
}

# Detect problematic merge patterns
# Returns: 0 if problematic, 1 if OK
# Sets: MERGE_ISSUE_TYPE, MERGE_TARGET, CURRENT_BRANCH
detect_problematic_merge() {
    local command="$1"
    local cwd="$2"

    # Reset globals
    MERGE_ISSUE_TYPE=""
    MERGE_TARGET=""
    CURRENT_BRANCH=""

    # Get current branch
    CURRENT_BRANCH=$(get_current_branch "${cwd}")

    if [[ -z "${CURRENT_BRANCH}" ]]; then
        debug_log "Could not determine current branch, skipping check"
        return 1
    fi

    # Parse merge target
    MERGE_TARGET=$(parse_merge_target "${command}")

    if [[ -z "${MERGE_TARGET}" ]]; then
        debug_log "Not a git merge command or no target found"
        return 1
    fi

    debug_log "Current branch: ${CURRENT_BRANCH}, Merge target: ${MERGE_TARGET}"

    # Strip origin/ for comparison
    local clean_target="${MERGE_TARGET#origin/}"

    # Case 1: On protected branch, trying to merge a feature branch
    # This is the dangerous case: directly merging features into main
    if is_protected_branch "${CURRENT_BRANCH}"; then
        if ! is_protected_branch "${clean_target}"; then
            MERGE_ISSUE_TYPE="merge_to_protected"
            debug_log "BLOCKED: Attempting to merge ${MERGE_TARGET} into protected branch ${CURRENT_BRANCH}"
            return 0
        fi
    fi

    # Case 2: On feature branch, merging main INTO feature (allowed)
    # git merge main or git merge origin/main while on feature branch is OK
    if ! is_protected_branch "${CURRENT_BRANCH}"; then
        if is_protected_branch "${clean_target}"; then
            debug_log "ALLOWED: Merging ${MERGE_TARGET} into feature branch ${CURRENT_BRANCH}"
            return 1
        fi
    fi

    # All other cases are OK
    return 1
}

# Generate helpful routing message
generate_routing_message() {
    local issue_type="$1"
    local merge_target="$2"
    local current_branch="$3"

    # Strip origin/ prefix for cleaner commands
    local clean_target="${merge_target#origin/}"

    cat <<EOFMSG

================================================================================
  PR WORKFLOW REQUIRED - Direct Merge Blocked
================================================================================

You are on branch '${current_branch}' (a protected branch) and attempted to
merge '${merge_target}' directly.

This bypasses code review and is not allowed.

--------------------------------------------------------------------------------
  CORRECT WORKFLOW
--------------------------------------------------------------------------------

Instead of merging directly into ${current_branch}:

1. First, switch to your feature branch:
   git checkout ${clean_target}

2. Merge ${current_branch} INTO your feature branch to get latest changes:
   git fetch origin ${current_branch}
   git merge origin/${current_branch}

3. Resolve any conflicts, then push:
   git push origin ${clean_target}

4. Create a Pull Request:
   gh pr create --base ${current_branch} --head ${clean_target}

Or in one command after switching to your feature branch:
   git fetch origin ${current_branch} && git merge origin/${current_branch} && git push origin ${clean_target} && gh pr create --base ${current_branch} --head ${clean_target}

--------------------------------------------------------------------------------
  WHY THIS MATTERS
--------------------------------------------------------------------------------

- Pull Requests enable code review before changes reach ${current_branch}
- CI/CD pipelines run on PRs to catch issues early
- Change history is preserved with proper merge commits
- Team visibility into what's being merged and why

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

    # Quick check: is this even a git merge command?
    if [[ ! "${command}" =~ git[[:space:]]+merge ]]; then
        exit 0
    fi

    debug_log "Git merge command detected, analyzing..."

    # Detect problematic merge patterns
    if detect_problematic_merge "${command}" "${cwd}"; then
        # Block the operation and provide routing
        generate_routing_message "${MERGE_ISSUE_TYPE}" "${MERGE_TARGET}" "${CURRENT_BRANCH}" >&2

        # Log for audit
        debug_log "AUDIT: Blocked merge - type=${MERGE_ISSUE_TYPE}, target=${MERGE_TARGET}, current=${CURRENT_BRANCH}"

        # Exit code 2 blocks the tool execution
        exit 2
    fi

    # Allow the operation
    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
