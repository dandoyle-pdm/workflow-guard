---
# Metadata
ticket_id: TICKET-cleanup-script-fix-001
session_id: cleanup-script-fix
sequence: 001
parent_ticket: null
title: Fix variable capture bug in cleanup-merged-ticket.sh
cycle_type: development
status: claimed
claimed_by: ddoyle
claimed_at: 2025-12-07 21:49
created: 2025-12-07 23:39
worktree_path: null
---

# Requirements

## What Needs to Be Done
Fix the bug in `scripts/cleanup-merged-ticket.sh` where `find_worktree_path()` output includes log messages, causing the security path validation to fail.

**Bug Location:** `cleanup_worktree()` function, lines 145-149

**Current Code:**
```bash
if ! worktree_path=$(find_worktree_path "$branch"); then
    log_info "Skipping worktree removal - no worktree found"
    return 0
fi
```

**Problem:** `find_worktree_path()` uses `log_info` which writes to stdout via `tee`. The captured variable contains:
```
[2025-12-08 04:30:00] INFO: Looking for worktree for branch: ticket/docs-update
[2025-12-08 04:30:00] INFO: Found worktree: /home/user/.novacloud/worktrees/workflow-guard/docs-update
/home/user/.novacloud/worktrees/workflow-guard/docs-update
```

This causes the security check at line 157 to fail:
```bash
if [[ ! "$normalized_worktree" =~ ^${normalized_base}/ ]]; then
    log_error "Security check failed: worktree path is outside WORKTREE_BASE"
```

## Acceptance Criteria
- [ ] `find_worktree_path()` returns ONLY the path, not log messages
- [ ] Log messages still appear in the log file for debugging
- [ ] Security path validation works correctly
- [ ] Script successfully cleans up worktrees when run from outside the worktree
- [ ] Existing behavior preserved (verify PR merged, delete branches, etc.)

# Context

## Why This Work Matters
The cleanup script is a key part of the ticket lifecycle workflow. When it fails, users must perform manual cleanup, which is error-prone and time-consuming. This bug was discovered during the docs-update cleanup when running the script from inside the worktree being cleaned up.

## References
- Related tickets: TICKET-docs-update-001 (where bug was discovered)
- Related PRs: PR #9 (required manual cleanup due to this bug)
- Documentation: README.md - Ticket Lifecycle section

# Creator Section

## Implementation Notes
[To be filled during implementation]

**Recommended Fix Options:**
1. **Redirect log_info to stderr in find_worktree_path():**
   ```bash
   log_info "Looking for worktree for branch: $branch" >&2
   ```

2. **Create separate logging function for functions that return values:**
   ```bash
   log_debug() { printf '[%s] DEBUG: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"; }
   ```

3. **Capture only the last line of output:**
   ```bash
   worktree_path=$(find_worktree_path "$branch" | tail -1)
   ```

Option 1 is cleanest - log_info should go to stderr anyway for functions that return values.

## Questions/Concerns
- Should all `log_info` calls in value-returning functions use stderr?
- Consider adding integration test for cleanup script

## Changes Made
- File changes: [To be filled]
- Commits: [To be filled]

**Status Update**: [To be filled] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] [To be filled during review]

### HIGH Issues
- [ ] [To be filled during review]

### MEDIUM Issues
- [ ] [To be filled during review]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[To be filled during review]

**Status Update**: [To be filled] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: [To be filled]
- Linting: shellcheck [To be filled]
- Build: N/A (shell script)
- Manual testing: [To be filled]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[To be filled]

**Status Update**: [To be filled] - Changed status to `approved` or created rework ticket

# Changelog

## [2025-12-07 23:39] - Ticket Created
- Bug identified during TICKET-docs-update-001 cleanup
- Root cause analysis completed
- Fix options documented
