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
WORKTREE_BASE="${WORKTREE_BASE:-${HOME}/.novacloud/worktrees}"
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
    # Queue tickets use format: TICKET-{session-id}.md (no sequence)
    if [[ ! "$filename" =~ ^TICKET-[a-zA-Z0-9-]+\.md$ ]]; then
        log_error "Invalid ticket filename format: $filename"
        log_error "Expected: TICKET-{session-id}.md"
        return 1
    fi

    return 0
}

# Determine next sequence number for a session
get_next_sequence() {
    local session_id="$1"
    local main_repo="$2"
    local max_seq=0

    # Check existing tickets in active and completed directories
    for dir in "tickets/active/${session_id}" "tickets/completed/${session_id}"; do
        if [[ -d "${main_repo}/${dir}" ]]; then
            for ticket in "${main_repo}/${dir}"/TICKET-*-[0-9][0-9][0-9].md; do
                if [[ -f "$ticket" ]]; then
                    local seq
                    seq=$(basename "$ticket" | sed 's/.*-\([0-9]\{3\}\)\.md$/\1/' | sed 's/^0*//')
                    if [[ -n "$seq" && "$seq" -gt "$max_seq" ]]; then
                        max_seq=$seq
                    fi
                fi
            done
        fi
    done

    printf "%03d" $((max_seq + 1))
}

phase1_claim() {
    local ticket_path="$1"
    local ticket_id="$2"
    local branch_dir="$3"
    local main_repo="$4"
    local session_id="$5"
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

        # Determine sequence number for this ticket
        local sequence
        sequence=$(get_next_sequence "$session_id" "$main_repo")
        local new_ticket_id="TICKET-${session_id}-${sequence}"
        local new_filename="${new_ticket_id}.md"

        log_info "Assigning sequence: ${sequence} -> ${new_ticket_id}"

        mkdir -p "tickets/active/${branch_dir}"
        # Move and rename: TICKET-session-id.md -> TICKET-session-id-001.md
        git mv "$ticket_path" "tickets/active/${branch_dir}/${new_filename}"

        local active_ticket="tickets/active/${branch_dir}/${new_filename}"

        # Update ticket_id in the file metadata
        sed -i "s/^ticket_id:.*/ticket_id: ${new_ticket_id}/" "$active_ticket"
        sed -i "s/^sequence:.*/sequence: ${sequence}/" "$active_ticket"
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M' | tr -d '\n\r')
        local user
        user=$(whoami | tr -d '\n\r')

        sed -i "s/^status:.*/status: claimed/" "$active_ticket"

        if ! grep -q "^claimed_by:" "$active_ticket"; then
            sed -i "/^status:/a claimed_by: ${user}" "$active_ticket"
        fi
        if ! grep -q "^claimed_at:" "$active_ticket"; then
            sed -i "/^claimed_by:/a claimed_at: ${timestamp}" "$active_ticket"
        fi

        git add tickets/
        git commit -m "claim: ${new_ticket_id}"

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
        # Sanitize variables for sed safety
        local safe_worktree_path
        safe_worktree_path=$(printf '%s' "$worktree_path" | tr -d '\n\r')

        sed -i "s|^worktree_path:.*|worktree_path: ${safe_worktree_path}|" "$active_ticket"
        sed -i "s/^status:.*/status: in_progress/" "$active_ticket"

        printf '\n## [%s] - Creator: activated\n- Worktree: %s\n- Branch: %s\n' \
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
        printf '\nExample: activate-ticket.sh tickets/queue/TICKET-my-feature.md myproject\n'
        printf '\nNote: Queue tickets use format TICKET-{session-id}.md (no sequence).\n'
        printf '      Sequence (-001, -002, etc.) is assigned automatically at activation.\n'
        exit 1
    fi

    ticket_path=$(realpath "$ticket_path")
    validate_ticket "$ticket_path" || exit 1

    local ticket_filename
    ticket_filename=$(basename "$ticket_path")
    local queue_ticket_id="${ticket_filename%.md}"

    # Extract session_id from ticket metadata (preferred) or filename
    local session_id
    if [[ -f "$ticket_path" ]] && session_id=$(grep "^session_id:" "$ticket_path" | head -1 | cut -d: -f2 | tr -d ' \t\n\r'); then
        if [[ -z "$session_id" ]]; then
            # Fallback to extracting from filename: TICKET-{session-id}.md (queue format)
            session_id=$(echo "$queue_ticket_id" | sed 's/^TICKET-//')
        fi
    else
        # Fallback to extracting from filename: TICKET-{session-id}.md (queue format)
        session_id=$(echo "$queue_ticket_id" | sed 's/^TICKET-//')
    fi

    local branch_name="ticket/${session_id}"
    local branch_dir="${session_id}"

    local main_repo
    main_repo=$(get_main_repo_root)

    if [[ -z "$project" ]]; then
        project=$(basename "$main_repo")
    fi

    log_info "============================================"
    log_info "Activating ticket: $queue_ticket_id"
    log_info "Session ID: $session_id"
    log_info "Project: $project"
    log_info "Branch: $branch_name"
    log_info "============================================"

    phase1_claim "$ticket_path" "$queue_ticket_id" "$branch_dir" "$main_repo" "$session_id" || exit 1

    # Find the actual ticket_id after sequence assignment
    cd "$main_repo"
    local active_ticket
    active_ticket=$(find "tickets/active/${branch_dir}" -name "TICKET-*.md" 2>/dev/null | head -1)
    local ticket_id
    if [[ -n "$active_ticket" ]]; then
        ticket_id=$(basename "$active_ticket" .md)
    else
        ticket_id="TICKET-${session_id}-001"
    fi

    phase2_activate "$ticket_id" "$branch_name" "$branch_dir" "$project" "$main_repo" || exit 1

    exit 0
}

main "$@"
