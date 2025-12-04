#!/bin/bash
set -euo pipefail

# ============================================================================
# complete-ticket.sh - Mark ticket as complete and prepare for PR
# ============================================================================
#
# Usage: complete-ticket.sh [ticket-path] [--no-push]
#
# Auto-detects ticket from current worktree if no path provided
# Updates status to approved, moves to completed/, commits, and pushes
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOME}/.claude/logs/complete-ticket.log"

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

get_current_branch() {
    git branch --show-current 2>/dev/null
}

is_worktree() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    [[ "$git_common_dir" == *".git/worktrees/"* ]]
}

find_active_ticket() {
    local branch="$1"
    local branch_dir
    branch_dir=$(echo "$branch" | sed 's|^ticket/||' | tr '/' '-')

    local active_dir="tickets/active/${branch_dir}"

    if [[ ! -d "$active_dir" ]]; then
        log_error "Active directory not found: $active_dir"
        log_error "Expected active ticket for branch: $branch"
        return 1
    fi

    local tickets
    tickets=$(find "$active_dir" -maxdepth 1 -name "TICKET-*.md" 2>/dev/null)

    if [[ -z "$tickets" ]]; then
        log_error "No ticket found in $active_dir"
        return 1
    fi

    local ticket_count
    ticket_count=$(echo "$tickets" | wc -l)

    if [[ $ticket_count -gt 1 ]]; then
        log_error "Multiple tickets found in $active_dir"
        log_error "Please specify ticket path explicitly:"
        echo "$tickets"
        return 1
    fi

    echo "$tickets"
}

validate_ticket() {
    local ticket_path="$1"

    if [[ ! -f "$ticket_path" ]]; then
        log_error "Ticket file not found: $ticket_path"
        return 1
    fi

    if [[ ! "$ticket_path" =~ tickets/active/ ]]; then
        log_error "Ticket must be in tickets/active/ directory"
        log_error "Found: $ticket_path"
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

complete_ticket() {
    local ticket_path="$1"
    local do_push="$2"

    # Extract ticket metadata
    local ticket_filename
    ticket_filename=$(basename "$ticket_path")
    local ticket_id="${ticket_filename%.md}"

    # Extract branch directory from active path
    local active_dir
    active_dir=$(dirname "$ticket_path")
    local branch_dir
    branch_dir=$(basename "$active_dir")

    log_info "Completing ticket: $ticket_id"
    log_info "Branch directory: $branch_dir"

    # Create completed directory structure
    local completed_dir="tickets/completed/${branch_dir}"
    mkdir -p "$completed_dir"

    # Update ticket status to approved
    log_info "Updating ticket status to 'approved'"
    sed -i "s/^status:.*/status: approved/" "$ticket_path"

    # Add changelog entry
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M')
    log_info "Adding changelog entry"
    printf '\n## [%s] - Completed\n- Status changed to approved\n- Ready for PR creation\n' \
        "$timestamp" >> "$ticket_path"

    # Move ticket to completed/
    local completed_path="${completed_dir}/${ticket_filename}"
    log_info "Moving ticket: $ticket_path -> $completed_path"
    git mv "$ticket_path" "$completed_path"

    # Check if active directory is now empty and remove if so
    if [[ -d "$active_dir" ]] && [[ -z "$(ls -A "$active_dir")" ]]; then
        log_info "Removing empty active directory: $active_dir"
        rmdir "$active_dir"
    fi

    # Commit the changes
    log_info "Committing changes"
    git add tickets/
    git commit -m "complete: ${ticket_id}"

    # Push to feature branch
    if [[ "$do_push" == "true" ]]; then
        local branch
        branch=$(get_current_branch)
        log_info "Pushing to branch: $branch"
        if git push origin "$branch" 2>&1; then
            log_success "Changes pushed successfully"
        else
            log_error "Failed to push changes"
            log_error "You can push manually: git push origin $branch"
            return 1
        fi
    else
        log_info "Skipping push (--no-push flag set)"
    fi

    # Success message with next steps
    log_success "Ticket completed successfully!"
    printf '\n'
    printf '╔══════════════════════════════════════════════════════════════╗\n'
    printf '║  TICKET COMPLETED                                            ║\n'
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  Ticket:    %-48s ║\n' "$ticket_id"
    printf '║  Location:  tickets/completed/%-30s ║\n' "$branch_dir"
    printf '║  Status:    approved                                         ║\n'
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    printf '║  NEXT STEPS:                                                 ║\n'
    printf '║  1. Create PR: gh pr create                                  ║\n'
    printf '║  2. After merge: cleanup-ticket.sh                           ║\n'
    printf '╚══════════════════════════════════════════════════════════════╝\n'

    return 0
}

show_help() {
    cat <<EOF
complete-ticket.sh - Mark ticket as complete and prepare for PR

USAGE:
    complete-ticket.sh [OPTIONS] [TICKET_PATH]

DESCRIPTION:
    Marks a ticket as complete by:
    - Updating status to 'approved'
    - Moving from tickets/active/ to tickets/completed/
    - Adding changelog entry
    - Committing and pushing changes
    - Displaying next steps (create PR)

ARGUMENTS:
    TICKET_PATH     Optional path to ticket file
                    Auto-detects from current worktree if not provided

OPTIONS:
    --no-push       Skip pushing to remote branch
    --help, -h      Show this help message

EXAMPLES:
    # Auto-detect ticket from current worktree
    complete-ticket.sh

    # Explicit ticket path
    complete-ticket.sh tickets/active/TICKET-foo-001/TICKET-foo-001.md

    # Complete without pushing
    complete-ticket.sh --no-push

SAFETY:
    - Must be run from a worktree (not main repo)
    - Validates ticket is in tickets/active/ directory
    - Uses git mv to properly track file moves
    - Commits all changes atomically

NEXT STEPS:
    After completion, create a PR with:
        gh pr create

    After PR is merged, cleanup with:
        cleanup-ticket.sh

EOF
}

main() {
    local ticket_path=""
    local do_push="true"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-push)
                do_push="false"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$ticket_path" ]]; then
                    ticket_path="$1"
                else
                    log_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Safety check: must be in a worktree
    if ! is_worktree; then
        log_error "This script must be run from a worktree, not the main repository"
        log_error "Worktrees are created automatically by activate-ticket.sh"
        log_error ""
        log_error "To find existing worktrees:"
        log_error "  git worktree list"
        exit 1
    fi

    # Auto-detect ticket if not provided
    if [[ -z "$ticket_path" ]]; then
        local branch
        branch=$(get_current_branch)

        if [[ -z "$branch" ]]; then
            log_error "Could not determine current branch"
            exit 1
        fi

        log_info "Auto-detecting ticket for branch: $branch"
        ticket_path=$(find_active_ticket "$branch") || exit 1
        log_info "Found ticket: $ticket_path"
    else
        ticket_path=$(realpath "$ticket_path")
    fi

    # Validate ticket
    validate_ticket "$ticket_path" || exit 1

    # Complete the ticket
    log_info "============================================"
    log_info "Starting ticket completion process"
    log_info "============================================"

    complete_ticket "$ticket_path" "$do_push" || exit 1

    exit 0
}

main "$@"
