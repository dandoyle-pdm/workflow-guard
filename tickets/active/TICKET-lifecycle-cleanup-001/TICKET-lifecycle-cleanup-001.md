---
# Metadata
ticket_id: TICKET-lifecycle-cleanup-001
session_id: lifecycle-cleanup
sequence: 001
parent_ticket: null
title: Implement cleanup-merged-ticket.sh for post-merge cleanup
cycle_type: development
status: needs_changes
claimed_by: ddoyle
claimed_at: 2025-12-03 20:22
created: 2025-12-03 22:20
worktree_path: /home/ddoyle/workspace/worktrees/workflow-guard/TICKET-lifecycle-cleanup-001
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

Implemented `cleanup-merged-ticket.sh` following all patterns from `activate-ticket.sh`:

**Core Features Implemented:**
- Branch name argument validation with help text
- Protected branch rejection (main, master, production)
- PR merge verification via gh CLI (checks state=MERGED and mergedAt)
- Worktree discovery and safe removal
- Local branch deletion with `git branch -d` (fails on unmerged changes)
- Remote branch deletion via `git push origin --delete`
- Worktree pruning for stale references
- Detailed cleanup summary

**Security Measures:**
- `is_protected_branch()` function blocks cleanup of protected branches
- `verify_pr_merged()` requires PR state=MERGED (not just closed)
- Path validation: worktree must be under WORKTREE_BASE
- Uses `git branch -d` (not `-D`) to prevent deleting unmerged work
- All destructive operations logged to ~/.claude/logs/cleanup-ticket.log

**Error Handling:**
- Graceful handling when worktree/branches don't exist (skip, continue)
- Clear error messages for PR not found, not merged, or closed
- gh CLI authentication check
- Git repository validation

**Code Quality:**
- Follows activate-ticket.sh patterns (logging functions, get_main_repo_root)
- `set -euo pipefail` for strict error handling
- Comprehensive help text with examples
- Environment variable support (WORKTREE_BASE, CLAUDE_PROTECTED_BRANCHES)

## Questions/Concerns

None - implementation is straightforward following existing patterns.

## Changes Made
- File changes:
  - Created `scripts/cleanup-merged-ticket.sh` (330 lines, executable)
- Commits:
  - c63a082 - feat: implement cleanup-merged-ticket.sh

**Status Update**: [2025-12-03 22:30] - Changed status to `critic_review`

# Critic Section

## Audit Findings

Conducted comprehensive security review of `cleanup-merged-ticket.sh` with focus on destructive operations (branch and worktree deletion).

### CRITICAL Issues

- [x] `scripts/cleanup-merged-ticket.sh:35-50` - **Case sensitivity bypass in protected branch check**
  - **Vulnerability**: Branch names "Main", "Master", "PRODUCTION" bypass protection due to case-sensitive comparison
  - **Attack vector**: User could run `cleanup-merged-ticket.sh Main` and delete the main branch
  - **Root cause**: Line 45 uses `==` operator without normalizing case
  - **Fix required**: Convert both `$branch`, `$branch_base`, and `$protected` to lowercase before comparison
  - **Code location**: `is_protected_branch()` function
  - **Suggested fix**:
    ```bash
    # Normalize to lowercase for case-insensitive comparison
    local branch_lower="${branch,,}"
    local branch_base_lower="${branch_base,,}"
    local protected_lower="${protected,,}"
    if [[ "$branch_lower" == "$protected_lower" ]] || [[ "$branch_base_lower" == "$protected_lower" ]]; then
        return 0
    fi
    ```

### HIGH Issues

None found. All other security-critical areas are properly implemented:
- PR merge verification requires both state=MERGED AND mergedAt non-null (lines 87-98)
- Command injection prevented by consistent quoting throughout (lines 73, 160, 181, 196, 202)
- Path traversal prevented by realpath normalization and prefix validation (lines 147-157)
- Safe branch deletion using `git branch -d` not `-D` (line 181)

### MEDIUM Issues

- [x] `scripts/cleanup-merged-ticket.sh:15` - **WORKTREE_BASE validation**
  - **Issue**: Should validate WORKTREE_BASE is set and is an absolute path at startup
  - **Risk**: If WORKTREE_BASE is relative or malformed, path validation could fail incorrectly
  - **Current mitigation**: Fallback to `~/workspace/worktrees` is reasonable
  - **Suggested enhancement**: Add validation in main():
    ```bash
    if [[ ! "$WORKTREE_BASE" =~ ^/ ]]; then
        log_error "WORKTREE_BASE must be an absolute path: $WORKTREE_BASE"
        exit 1
    fi
    ```

- [x] `scripts/cleanup-merged-ticket.sh:238` - **No branch name format validation**
  - **Issue**: Accepts any string as branch name, could lead to confusing errors
  - **Risk**: LOW - not a security issue due to proper quoting, just UX
  - **Suggested enhancement**: Validate branch name matches git conventions (no spaces, no `..`, etc.)

## Security Strengths Verified

**PR Merge Verification (SECURE)**:
- Checks gh CLI availability and authentication (lines 58, 65)
- Requires state=MERGED (line 87)
- Requires mergedAt is non-null (line 94)
- Properly handles gh CLI failures (line 73)
- Safe JSON parsing with grep/cut (lines 80, 83)

**Worktree Path Validation (SECURE)**:
- Normalizes paths with realpath to resolve symlinks (lines 147-150)
- Validates worktree is under WORKTREE_BASE with regex prefix check (line 152)
- Regex `^${normalized_base}/` requires trailing slash, preventing "worktrees-evil" bypass
- Properly quoted in git command (line 160)

**Branch Deletion (SECURE)**:
- Uses `git branch -d` (not `-D`) to fail on unmerged changes (line 181)
- Properly quoted branch names prevent command injection (lines 174, 181, 196, 202)
- Git's own branch name validation provides additional protection

**Error Handling (SECURE)**:
- Uses `set -euo pipefail` for strict error handling (line 2)
- All destructive operations check return codes and exit on failure (lines 274, 284-289, 292-297, 300-305)
- Fail-fast approach prevents partial cleanup states

**Logging (SECURE)**:
- All destructive operations logged to `~/.claude/logs/cleanup-ticket.log` for audit trail
- Timestamps on all log entries (lines 21-23)

## Approval Decision

**NEEDS_CHANGES**

## Rationale

The implementation demonstrates strong security practices overall:
- Excellent PR verification logic requiring both state and timestamp
- Proper command injection prevention via consistent quoting
- Solid path traversal protection with realpath normalization
- Safe branch deletion using `-d` flag
- Comprehensive error handling and logging

However, the **case sensitivity bypass in protected branch check is a critical security vulnerability** that MUST be fixed before approval. This could allow accidental or malicious deletion of protected branches by simply using different casing (Main vs main).

The MEDIUM issues are nice-to-haves but not blockers:
- WORKTREE_BASE validation would add defense-in-depth
- Branch name format validation would improve UX

**Required for approval**: Fix the CRITICAL case sensitivity issue in `is_protected_branch()` function.

**Status Update**: [2025-12-03 22:45] - Changed status to `needs_changes` - creator must fix case sensitivity vulnerability

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

## [2025-12-03 20:22] - Activated
- Worktree: /home/ddoyle/workspace/worktrees/workflow-guard/TICKET-lifecycle-cleanup-001
- Branch: ticket/TICKET-lifecycle-cleanup-001
