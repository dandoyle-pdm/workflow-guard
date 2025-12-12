---
# Metadata
ticket_id: TICKET-scm-state-verification
session_id: scm-state-verification
sequence: null
parent_ticket: null
title: Add SCM state verification to ticket workflow scripts
cycle_type: development
status: open
created: 2025-12-12 09:45
worktree_path: null
---

# Requirements

## What Needs to Be Done

Add SCM state verification to ticket workflow scripts following fundamental SCM practices that predate git. Scripts must verify repository state before operations and provide actionable feedback to Claude when prereqs fail.

**Deliverables:**

1. `scripts/lib/scm-utils.sh` - Shared SCM verification utilities
2. Update `scripts/activate-ticket.sh` - Add prereq state check at start
3. Create `scripts/complete-ticket.sh` - Post-merge workflow with state verification
4. Create `scripts/prepare-pr.sh` - Pre-PR workflow (merge main, test, push)

## Acceptance Criteria

- [ ] `check_branch_sync_state()` function detects: synced, behind, ahead, diverged
- [ ] activate-ticket.sh fails fast if main is ahead or diverged
- [ ] complete-ticket.sh verifies state before pulling main
- [ ] prepare-pr.sh merges origin/main into feature branch before PR
- [ ] All scripts return structured error messages Claude can parse
- [ ] AHEAD state: warning, do not auto-resolve
- [ ] DIVERGED state: error, do not auto-resolve, require manual intervention
- [ ] BEHIND state: safe to auto-pull/merge
- [ ] Scripts exit with clear PREREQ_FAILED messages

# Context

## Why This Work Matters

Current scripts operate without verifying repository state first. This violates fundamental SCM practice: "always know your baseline before making changes."

**Problem scenarios:**
1. Local main 17 commits behind origin - script proceeds with stale state
2. Dev work done directly on main (violating workflow) - script doesn't detect
3. Main diverged from origin - script could corrupt state

**Solution:**
Scripts must detect state and either:
- Auto-resolve safe states (behind → pull)
- Fail fast with actionable messages for unsafe states (ahead, diverged)

## References

- Related tickets: TICKET-subagent-visibility-001 (exposed this gap)
- Documentation: SCM practices, gitops workflows

# Technical Approach

## Shared Library: scripts/lib/scm-utils.sh

```bash
# check_branch_sync_state <branch> <remote>
# Returns: "state:ahead_count:behind_count"
# States: synced, behind, ahead, diverged

check_branch_sync_state() {
    local branch="${1:-main}"
    local remote="${2:-origin}"

    git fetch "$remote" "$branch" --quiet 2>/dev/null || return 1

    local local_sha=$(git rev-parse "$branch" 2>/dev/null)
    local remote_sha=$(git rev-parse "$remote/$branch" 2>/dev/null)
    local base=$(git merge-base "$branch" "$remote/$branch" 2>/dev/null)

    if [[ "$local_sha" == "$remote_sha" ]]; then
        echo "synced:0:0"
    elif [[ "$local_sha" == "$base" ]]; then
        local behind=$(git rev-list --count "$branch".."$remote/$branch")
        echo "behind:0:$behind"
    elif [[ "$remote_sha" == "$base" ]]; then
        local ahead=$(git rev-list --count "$remote/$branch".."$branch")
        echo "ahead:$ahead:0"
    else
        local ahead=$(git rev-list --count "$base".."$branch")
        local behind=$(git rev-list --count "$base".."$remote/$branch")
        echo "diverged:$ahead:$behind"
    fi
}

# format_prereq_error <state> <ahead> <behind>
# Returns structured error message for Claude
format_prereq_error() {
    local state="$1" ahead="$2" behind="$3"

    case "$state" in
        ahead)
            cat <<EOF
PREREQ_FAILED: MAIN_AHEAD
DESCRIPTION: Local main is $ahead commits ahead of origin/main
ACTION_REQUIRED: Local commits on main violate workflow. Move to feature branch or push.
CONTEXT: Dev work should not happen on main. These commits need to be moved to a ticket.
EOF
            ;;
        diverged)
            cat <<EOF
PREREQ_FAILED: MAIN_DIVERGED
DESCRIPTION: Local main has diverged from origin/main ($ahead ahead, $behind behind)
ACTION_REQUIRED: DO NOT auto-resolve. Investigate divergence. Move local commits to ticket.
CONTEXT: Both local and remote have unique commits. Manual reconciliation required.
EOF
            ;;
    esac
}
```

## activate-ticket.sh Changes

Add at start of main():
```bash
source "${SCRIPT_DIR}/lib/scm-utils.sh"

verify_main_state() {
    local result=$(check_branch_sync_state main origin)
    local state=$(echo "$result" | cut -d: -f1)
    local ahead=$(echo "$result" | cut -d: -f2)
    local behind=$(echo "$result" | cut -d: -f3)

    case "$state" in
        synced) log_info "Main is in sync with origin/main"; return 0 ;;
        behind) log_info "Main is $behind behind - will fast-forward"; return 0 ;;
        ahead|diverged)
            format_prereq_error "$state" "$ahead" "$behind" >&2
            return 1 ;;
    esac
}
```

## complete-ticket.sh (NEW)

Flow:
1. Detect current ticket from branch or argument
2. Verify PR is merged (feature branch deleted or PR closed)
3. Check main state - fail if ahead/diverged
4. Pull origin/main if behind
5. Move ticket: active/{session}/ → completed/{session}/
6. Update status to completed
7. Commit and push metadata to main
8. Delete feature branch (local + remote)
9. Remove worktree

## prepare-pr.sh (NEW)

Flow:
1. Verify on feature branch (not main)
2. Fetch origin/main
3. Check if feature branch behind origin/main
4. If behind: merge origin/main into feature branch
5. Run tests (configurable via env var or argument)
6. If tests fail: exit with message
7. Push updated feature branch
8. Output ready message or create PR

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
[To be filled by plugin-engineer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] `file:line` - Issue description and fix required

### HIGH Issues
- [ ] `file:line` - Issue description and fix required

### MEDIUM Issues
- [ ] `file:line` - Suggestion for improvement

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [PASS/FAIL]
- Security scans: [PASS/FAIL]
- Build: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-12 09:45] - Creator: created
- Ticket created in queue/
- Requirements defined from session discussion
- Technical approach specified with shared library design
- Structured error message format for Claude feedback
