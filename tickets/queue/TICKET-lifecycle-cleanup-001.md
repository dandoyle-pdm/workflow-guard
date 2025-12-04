---
# Metadata
ticket_id: TICKET-lifecycle-cleanup-001
session_id: lifecycle-cleanup
sequence: 001
parent_ticket: null
title: Implement cleanup-merged-ticket.sh for post-merge cleanup
cycle_type: development
status: open
created: 2025-12-03 22:20
worktree_path: null
---

# Requirements

## What Needs to Be Done
Implement `scripts/cleanup-merged-ticket.sh` - a script that removes the worktree, deletes local and remote branches after a PR has been merged.

## Acceptance Criteria
- [ ] Accepts branch-name as argument
- [ ] Verifies PR is MERGED (not just closed) before cleanup
- [ ] Rejects cleanup of protected branches (main, master, production)
- [ ] Removes worktree if it exists
- [ ] Deletes local branch
- [ ] Deletes remote branch
- [ ] Prunes stale worktree references
- [ ] Outputs cleanup summary
- [ ] Follows patterns from activate-ticket.sh (logging, error handling)

# Context

## Why This Work Matters
The ticket lifecycle has three phases: activate → complete → cleanup. After a PR is merged, developers need to clean up the worktree and branches. This script automates that cleanup safely, with proper verification that the PR was actually merged.

## References
- Related tickets: TICKET-gitops-activation-001 (parent feature), TICKET-lifecycle-complete-001
- Documentation: README.md
- Reference implementation: scripts/activate-ticket.sh

# Technical Specification

## Script Usage
```bash
# Cleanup after PR merge
cleanup-merged-ticket.sh <branch-name>

# Example
cleanup-merged-ticket.sh ticket/TICKET-lifecycle-complete-001
```

## Required Functions
Following patterns from activate-ticket.sh:
- `log_info`, `log_error`, `log_success` - Logging utilities
- `is_protected_branch` - Security validation
- `verify_pr_merged` - Check PR state via gh CLI
- `find_worktree_path` - Locate worktree for branch
- `cleanup_worktree` - Safe worktree removal
- `cleanup_branches` - Delete local and remote branches

## Main Flow
1. Validate branch-name argument provided
2. Safety check: reject protected branch names (main, master, production)
3. Verify PR status: `gh pr view <branch> --json state,mergedAt`
4. If NOT merged → abort with clear error
5. Find worktree path: `git worktree list | grep <branch>`
6. Remove worktree if exists: `git worktree remove <path>`
7. Delete local branch: `git branch -d <branch>` (uses -d to fail if unmerged)
8. Delete remote branch: `git push origin --delete <branch>`
9. Prune stale references: `git worktree prune`
10. Output cleanup summary

## Security Considerations (CRITICAL)
- NEVER allow cleanup of protected branches (main, master, production)
- MUST verify PR is in MERGED state (not just closed)
- Use `git branch -d` (not `-D`) to prevent deleting unmerged work
- Verify worktree path is under expected WORKTREE_BASE before removal
- Log all destructive operations for audit

## Edge Cases
- Branch doesn't exist → Error with message
- PR not found → Error with helpful message
- PR closed but not merged → Error, prevent cleanup
- Worktree doesn't exist → Skip worktree removal, continue with branch cleanup
- Local branch doesn't exist → Skip local deletion, continue
- Remote branch doesn't exist → Skip remote deletion
- Protected branch name → Immediate abort

## Environment Variables
- `WORKTREE_BASE` - Base path for worktrees (default: ~/workspace/worktrees)
- `CLAUDE_PROTECTED_BRANCHES` - Comma-separated protected branches (default: main,master,production)

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
- Script syntax valid: [PASS/FAIL]
- Help text works: [PASS/FAIL]
- Protected branch rejection: [PASS/FAIL]
- PR merge verification: [PASS/FAIL]
- Worktree removal: [PASS/FAIL]
- Branch deletion: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-03 22:20] - Ticket Created
- Defined requirements and acceptance criteria
- Technical specification with security considerations
- Priority: MEDIUM (complete-ticket.sh is higher priority)
