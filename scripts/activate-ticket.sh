#!/bin/bash
set -euo pipefail

# ============================================================================
# activate-ticket.sh - Claim and activate a ticket with GitOps locking
# ============================================================================
#
# Usage: activate-ticket.sh <ticket-path> [project-name]
#
# Phase 1: Claims ticket by moving it from queue/ to active/ on main
# Phase 2: Creates worktree and feature branch for development
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_BASE="${HOME}/workspace/worktrees"
LOG_FILE="${HOME}/.claude/logs/activate-ticket.log"

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

validate_ticket() {
    local ticket_path="$1"

    if [[ ! -f "$ticket_path" ]]; then
        log_error "Ticket file not found: $ticket_path"
        return 1
    fi

    if [[ ! "$ticket_path" =~ tickets/queue/ ]]; then
        log_error "Ticket must be in tickets/queue/ directory"
        return 1
    fi

    local filename
    filename=$(basename "$ticket_path")
    if [[ ! "$filename" =~ ^TICKET-[a-zA-Z0-9-]+-[0-9]+\.md$ ]]; then
        log_error "Invalid ticket filename format: $filename"
        log_error "Expected: TICKET-{session-id}-{sequence}.md"
        return 1
    fi

    return 0
}

phase1_claim() {
    local ticket_path="$1"
    local ticket_id="$2"
    local branch_dir="$3"
    local main_repo="$4"
    local max_retries=3
    local retry=0

    log_info "PHASE 1: Claiming ticket on main branch"

    cd "$main_repo"
    local original_branch
    original_branch=$(git branch --show-current)

    local stash_needed=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_info "Stashing uncommitted changes"
        git stash push -m "activate-ticket: temporary stash"
        stash_needed=true
    fi

    cleanup_phase1() {
        cd "$main_repo"
        if [[ "$(git branch --show-current)" != "$original_branch" ]]; then
            git checkout "$original_branch" 2>/dev/null || true
        fi
        if [[ "$stash_needed" == "true" ]]; then
            git stash pop 2>/dev/null || true
        fi
    }
    trap cleanup_phase1 EXIT

    while [[ $retry -lt $max_retries ]]; do
        git checkout main
        git pull origin main

        if [[ ! -f "$ticket_path" ]]; then
            log_error "Ticket no longer in queue/ - already claimed by another developer"
            return 1
        fi

        mkdir -p "tickets/active/${branch_dir}"
        git mv "$ticket_path" "tickets/active/${branch_dir}/"

        local active_ticket="tickets/active/${branch_dir}/$(basename "$ticket_path")"
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M')
        local user
        user=$(whoami)

        sed -i "s/^status:.*/status: claimed/" "$active_ticket"

        if ! grep -q "^claimed_by:" "$active_ticket"; then
            sed -i "/^status:/a claimed_by: ${user}" "$active_ticket"
        fi
        if ! grep -q "^claimed_at:" "$active_ticket"; then
            sed -i "/^claimed_by:/a claimed_at: ${timestamp}" "$active_ticket"
        fi

        git add tickets/
        git commit -m "claim: ${ticket_id}"

        if git push origin main 2>&1; then
            log_success "Ticket claimed successfully on main"
            trap - EXIT
            git checkout "$original_branch" 2>/dev/null || git checkout main
            if [[ "$stash_needed" == "true" ]]; then
                git stash pop 2>/dev/null || true
            fi
            return 0
        else
            log_info "Push conflict detected, retrying... (attempt $((retry + 1))/$max_retries)"
            git reset --hard HEAD~1
            ((retry++))
            sleep 1
        fi
    done

    log_error "Failed to claim ticket after $max_retries attempts"
    log_error "Another developer may have claimed it."
    return 1
}

phase2_activate() {
    local ticket_id="$1"
    local branch_name="$2"
    local branch_dir="$3"
    local project="$4"
    local main_repo="$5"

    log_info "PHASE 2: Creating worktree for development"

    local worktree_path="${WORKTREE_BASE}/${project}/${branch_dir}"

    cd "$main_repo"
    git pull origin main

    if [[ -d "$worktree_path" ]]; then
        log_error "Worktree already exists: $worktree_path"
        return 1
    fi

    mkdir -p "$(dirname "$worktree_path")"
    git worktree add "$worktree_path" -b "$branch_name" main

    cd "$worktree_path"

    local active_ticket
    active_ticket=$(find "tickets/active/${branch_dir}" -name "TICKET-*.md" 2>/dev/null | head -1)

    if [[ -n "$active_ticket" && -f "$active_ticket" ]]; then
        sed -i "s|^worktree_path:.*|worktree_path: ${worktree_path}|" "$active_ticket"
        sed -i "s/^status:.*/status: in_progress/" "$active_ticket"

        printf '\n## [%s] - Activated\n- Worktree: %s\n- Branch: %s\n' \
            "$(date '+%Y-%m-%d %H:%M')" "$worktree_path" "$branch_name" >> "$active_ticket"

        git add tickets/
        git commit -m "activate: ${ticket_id}"
    fi

    if ! git push -u origin "$branch_name" 2>&1; then
        log_error "Failed to push feature branch"
        return 1
    fi

    log_success "Ticket activated successfully!"
    printf '\n'
    printf '╔══════════════════════════════════════════════════════════════╗\n'
    printf '║  TICKET ACTIVATED                                            ║\n'
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  Ticket:    %s\n' "$ticket_id"
    printf '║  Branch:    %s\n' "$branch_name"
    printf '║  Worktree:  %s\n' "$worktree_path"
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  NEXT STEPS:                                                 ║\n'
    printf '║  1. cd %s\n' "$worktree_path"
    printf '║  2. Begin development work                                   ║\n'
    printf '║  3. When done: complete-ticket.sh                            ║\n'
    printf '╚══════════════════════════════════════════════════════════════╝\n'

    return 0
}

main() {
    local ticket_path="${1:-}"
    local project="${2:-}"

    if [[ -z "$ticket_path" ]]; then
        printf 'Usage: activate-ticket.sh <ticket-path> [project-name]\n'
        printf '\nExample: activate-ticket.sh tickets/queue/TICKET-foo-001.md myproject\n'
        exit 1
    fi

    ticket_path=$(realpath "$ticket_path")
    validate_ticket "$ticket_path" || exit 1

    local ticket_filename
    ticket_filename=$(basename "$ticket_path")
    local ticket_id="${ticket_filename%.md}"
    local branch_name="ticket/${ticket_id}"
    local branch_dir
    branch_dir=$(echo "$ticket_id" | tr '/' '-')

    local main_repo
    main_repo=$(get_main_repo_root)

    if [[ -z "$project" ]]; then
        project=$(basename "$main_repo")
    fi

    log_info "============================================"
    log_info "Activating ticket: $ticket_id"
    log_info "Project: $project"
    log_info "Branch: $branch_name"
    log_info "============================================"

    phase1_claim "$ticket_path" "$ticket_id" "$branch_dir" "$main_repo" || exit 1
    phase2_activate "$ticket_id" "$branch_name" "$branch_dir" "$project" "$main_repo" || exit 1

    exit 0
}

main "$@"
