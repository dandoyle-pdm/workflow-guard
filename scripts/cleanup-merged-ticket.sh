#!/bin/bash
set -euo pipefail

# ============================================================================
# cleanup-merged-ticket.sh - Clean up worktree and branches after PR merge
# ============================================================================
#
# Usage: cleanup-merged-ticket.sh <branch-name>
#
# Verifies PR is merged, then safely removes worktree and deletes branches.
# This script DELETES resources - security is paramount.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_BASE="${WORKTREE_BASE:-${HOME}/.novacloud/worktrees}"
LOG_FILE="${HOME}/.claude/logs/cleanup-ticket.log"
PROTECTED_BRANCHES="${CLAUDE_PROTECTED_BRANCHES:-main,master,production}"

mkdir -p "$(dirname "$LOG_FILE")"

log_info()  { printf '[%s] INFO: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }
log_error() { printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE" >&2; }
log_success() { printf '[%s] SUCCESS: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }

get_main_repo_root() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ "$git_common_dir" == *".git/worktrees/"* ]]; then
        dirname "$(dirname "$git_common_dir")"
    else
        git rev-parse --show-toplevel 2>/dev/null
    fi
}

is_protected_branch() {
    local branch="$1"
    local protected_list="${PROTECTED_BRANCHES}"

    # Strip ticket/ prefix if present for comparison
    local branch_base="${branch#ticket/}"

    # Normalize to lowercase for case-insensitive comparison
    local branch_lower="${branch,,}"
    local branch_base_lower="${branch_base,,}"

    IFS=',' read -ra PROTECTED <<< "$protected_list"
    for protected in "${PROTECTED[@]}"; do
        protected=$(echo "$protected" | xargs)  # trim whitespace
        local protected_lower="${protected,,}"
        if [[ "$branch_lower" == "$protected_lower" ]] || [[ "$branch_base_lower" == "$protected_lower" ]]; then
            return 0
        fi
    done
    return 1
}

verify_pr_merged() {
    local branch="$1"

    log_info "Verifying PR status for branch: $branch"

    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed or not in PATH"
        log_error "Install from: https://cli.github.com/"
        return 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        return 1
    fi

    # Query PR status
    local pr_data
    if ! pr_data=$(gh pr view "$branch" --json state,mergedAt 2>&1); then
        log_error "Failed to find PR for branch: $branch"
        log_error "Details: $pr_data"
        return 1
    fi

    local state
    state=$(echo "$pr_data" | grep -o '"state":"[^"]*"' | cut -d'"' -f4)

    local merged_at
    merged_at=$(echo "$pr_data" | grep -o '"mergedAt":"[^"]*"' | cut -d'"' -f4)

    log_info "PR state: $state"

    if [[ "$state" != "MERGED" ]]; then
        log_error "PR is not merged (state: $state)"
        log_error "Only merged PRs can be cleaned up"
        log_error "If PR is closed but not merged, it may have unmerged changes"
        return 1
    fi

    if [[ -z "$merged_at" || "$merged_at" == "null" ]]; then
        log_error "PR state is MERGED but mergedAt is empty"
        log_error "This should not happen - PR may be in invalid state"
        return 1
    fi

    log_success "PR is merged (merged at: $merged_at)"
    return 0
}

find_worktree_path() {
    local branch="$1"

    log_info "Looking for worktree for branch: $branch" >&2

    local worktree_list
    worktree_list=$(git worktree list --porcelain)

    local worktree_path=""
    local current_path=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
            current_path="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
            local branch_name="${BASH_REMATCH[1]}"
            if [[ "$branch_name" == "$branch" ]]; then
                worktree_path="$current_path"
                break
            fi
        fi
    done <<< "$worktree_list"

    if [[ -z "$worktree_path" ]]; then
        log_info "No worktree found for branch: $branch" >&2
        return 1
    fi

    log_info "Found worktree: $worktree_path" >&2
    echo "$worktree_path"
    return 0
}

cleanup_worktree() {
    local branch="$1"

    local worktree_path
    if ! worktree_path=$(find_worktree_path "$branch"); then
        log_info "Skipping worktree removal - no worktree found"
        return 0
    fi

    # Security: verify path is under expected WORKTREE_BASE
    local normalized_worktree
    normalized_worktree=$(realpath "$worktree_path" 2>/dev/null || echo "$worktree_path")
    local normalized_base
    normalized_base=$(realpath "$WORKTREE_BASE" 2>/dev/null || echo "$WORKTREE_BASE")

    if [[ ! "$normalized_worktree" =~ ^${normalized_base}/ ]]; then
        log_error "Security check failed: worktree path is outside WORKTREE_BASE"
        log_error "Worktree: $normalized_worktree"
        log_error "Expected base: $normalized_base"
        return 1
    fi

    log_info "Removing worktree: $worktree_path"
    if git worktree remove "$worktree_path" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Worktree removed successfully"
        return 0
    else
        log_error "Failed to remove worktree"
        return 1
    fi
}

cleanup_local_branch() {
    local branch="$1"

    log_info "Checking for local branch: $branch"

    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        log_info "Local branch does not exist - skipping"
        return 0
    fi

    log_info "Deleting local branch: $branch"
    # Use -d (not -D) to fail if branch has unmerged changes
    if git branch -d "$branch" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Local branch deleted successfully"
        return 0
    else
        log_error "Failed to delete local branch"
        log_error "Branch may have unmerged changes - use git branch -D if you're sure"
        return 1
    fi
}

cleanup_remote_branch() {
    local branch="$1"

    log_info "Checking for remote branch: origin/$branch"

    if ! git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
        log_info "Remote branch does not exist - skipping"
        return 0
    fi

    log_info "Deleting remote branch: origin/$branch"
    if git push origin --delete "$branch" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Remote branch deleted successfully"
        return 0
    else
        log_error "Failed to delete remote branch"
        return 1
    fi
}

show_help() {
    cat << EOF
Usage: cleanup-merged-ticket.sh <branch-name>

Clean up worktree and branches after a PR has been merged.

Arguments:
  branch-name    Name of the branch to clean up (e.g., ticket/TICKET-foo-001)

Security:
  - Verifies PR is MERGED before cleanup
  - Rejects protected branches (main, master, production)
  - Uses git branch -d (fails if unmerged changes)
  - Validates worktree paths before removal

Examples:
  cleanup-merged-ticket.sh ticket/TICKET-foo-001
  cleanup-merged-ticket.sh feature/add-logging

Environment Variables:
  WORKTREE_BASE              Base path for worktrees (default: ~/workspace/worktrees)
  CLAUDE_PROTECTED_BRANCHES  Comma-separated protected branches (default: main,master,production)

EOF
}

main() {
    local branch="${1:-}"

    if [[ -z "$branch" ]]; then
        log_error "Branch name is required"
        show_help
        exit 1
    fi

    if [[ "$branch" == "-h" ]] || [[ "$branch" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Security check: reject protected branches
    if is_protected_branch "$branch"; then
        log_error "SECURITY: Cannot cleanup protected branch: $branch"
        log_error "Protected branches: $PROTECTED_BRANCHES"
        exit 1
    fi

    local main_repo
    main_repo=$(get_main_repo_root)

    if [[ -z "$main_repo" ]]; then
        log_error "Not in a git repository"
        exit 1
    fi

    log_info "============================================"
    log_info "Cleaning up merged branch: $branch"
    log_info "Repository: $main_repo"
    log_info "============================================"

    cd "$main_repo"

    # Verify PR is merged
    if ! verify_pr_merged "$branch"; then
        exit 1
    fi

    # Track what was cleaned up
    local cleaned_worktree=false
    local cleaned_local=false
    local cleaned_remote=false

    # Clean up worktree
    if cleanup_worktree "$branch"; then
        cleaned_worktree=true
    else
        log_error "Worktree cleanup failed - stopping"
        exit 1
    fi

    # Clean up local branch
    if cleanup_local_branch "$branch"; then
        cleaned_local=true
    else
        log_error "Local branch cleanup failed - stopping"
        exit 1
    fi

    # Clean up remote branch
    if cleanup_remote_branch "$branch"; then
        cleaned_remote=true
    else
        log_error "Remote branch cleanup failed - stopping"
        exit 1
    fi

    # Prune stale worktree references
    log_info "Pruning stale worktree references"
    if git worktree prune 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Worktree references pruned"
    fi

    # Summary
    log_success "Cleanup completed successfully!"
    printf '\n'
    printf '╔══════════════════════════════════════════════════════════════╗\n'
    printf '║  CLEANUP COMPLETE                                            ║\n'
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  Branch:         %s\n' "$branch"
    printf '║  Worktree:       %s\n' "$([[ "$cleaned_worktree" == "true" ]] && echo "Removed" || echo "Not found")"
    printf '║  Local branch:   %s\n' "$([[ "$cleaned_local" == "true" ]] && echo "Deleted" || echo "Not found")"
    printf '║  Remote branch:  %s\n' "$([[ "$cleaned_remote" == "true" ]] && echo "Deleted" || echo "Not found")"
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  All resources cleaned up successfully                       ║\n'
    printf '╚══════════════════════════════════════════════════════════════╝\n'

    exit 0
}

main "$@"
