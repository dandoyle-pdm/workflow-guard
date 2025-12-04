---
# Metadata
ticket_id: TICKET-gitops-activation-001
session_id: gitops-activation
sequence: 001
parent_ticket: null
title: Implement ticket activation with GitOps locking
cycle_type: development
status: open
created: 2025-12-03 19:30
worktree_path: null
---

# Requirements

## What Needs to Be Done
Implement a two-phase ticket activation system that provides GitOps-style distributed locking to prevent duplicate work. The primary lock mechanism is a commit to main that moves the ticket from `queue/` to `active/`, with branch creation as a fallback safety net.

**Problem Solved:** Race condition where two developers both claim the same ticket and do duplicate work.

**Files to Create/Modify:**
1. `hooks/block-main-commits.sh` - Add surgical ticket lifecycle exception
2. `scripts/activate-ticket.sh` - Two-phase activation script (NEW)
3. `commands/activate.md` - Slash command for activation (NEW)
4. `README.md` - Document ticket activation workflow

## Acceptance Criteria
- [ ] `activate-ticket.sh` claims ticket atomically via push to main
- [ ] Concurrent activation attempts result in exactly one winner
- [ ] Losing developer sees clear error BEFORE any local work starts
- [ ] Ticket visibly leaves `queue/` on main immediately after claim
- [ ] Regular code commits to main remain blocked
- [ ] Ticket lifecycle commits on main are allowed (surgical exception)
- [ ] Audit logging captures allowed ticket commits
- [ ] `/workflow-guard:activate` command works
- [ ] README documents the ticket activation workflow

# Context

## Why This Work Matters
Currently, ticket activation lacks a distributed locking mechanism:

```
T0: Alice sees TICKET-foo-001.md in queue/
T1: Bob sees TICKET-foo-001.md in queue/
T2: Both run activate-ticket.sh locally
T3: Both create worktrees, both think they own the ticket
T4: Duplicate work happens, one developer's work is wasted
```

The solution provides:
1. **Deliberate locking** - explicit claim before work begins
2. **Atomic distributed lock** - git push conflict detection
3. **Visibility** - ticket leaves `queue/` immediately
4. **Fail early** - detect conflicts before creating worktree

## Technical Design

### Two-Phase Activation Architecture

```
PHASE 1: CLAIM (on main branch - deliberate, visible, atomic)
─────────────────────────────────────────────────────────────
1. git checkout main && git pull origin main
2. Verify ticket exists in tickets/queue/
3. Create directory: tickets/active/<branch-dir>/
4. git mv tickets/queue/TICKET-xxx.md → tickets/active/<branch-dir>/
5. Update ticket metadata: status=claimed, claimed_by, claimed_at
6. git commit -m "claim: TICKET-xxx"
7. git push origin main
   ├─ SUCCESS → Proceed to Phase 2
   └─ CONFLICT → Retry or abort if ticket gone

PHASE 2: WORK SETUP (only after Phase 1 succeeded)
──────────────────────────────────────────────────
8. git worktree add <path> -b ticket/TICKET-xxx
9. Update ticket: worktree_path, status=in_progress
10. git push -u origin ticket/TICKET-xxx
```

### Task 1: block-main-commits.sh Modification

Add `is_ticket_lifecycle_only()` function that returns 0 if ALL staged files match `^tickets/(queue|active|completed|archive)/`.

Modify blocking logic to allow ticket lifecycle commits:
```bash
if is_protected_branch && is_git_commit_command; then
    if is_ticket_lifecycle_only; then
        debug_log "ALLOWED: Ticket lifecycle commit"
        exit 0
    fi
    # existing blocking logic
fi
```

### Task 2: activate-ticket.sh Script

Full implementation provided in handoff. Key features:
- Two-phase activation (claim then work setup)
- Retry logic for push conflicts (max 3 attempts)
- Cleanup on failure (no orphaned state)
- Comprehensive logging
- Success banner with next steps

### Task 3: commands/activate.md

Slash command documentation explaining:
- What the command does
- Locking mechanism
- Conflict handling
- After activation steps

### Task 4: README.md Update

Add "Ticket Activation" section documenting:
- How GitOps locking works
- Commands available
- Why main commits are allowed for tickets

## References
- Handoff prompt with full implementation specs
- TEMPLATE.md ticket lifecycle documentation

# Creator Section

## Implementation Notes

**Design Review Findings:**
1. **Logic (Two-Phase Activation)**: APPROVED - Atomic lock via git push prevents race conditions effectively
2. **Design (Surgical Exception)**: APPROVED - `is_ticket_lifecycle_only()` correctly validates ticket-only commits
3. **Patterns**: APPROVED - Follows established plugin conventions for security, logging, and structure

**Implementation:**
- Task 1: Added `is_ticket_lifecycle_only()` function to block-main-commits.sh before protected branch check
- Task 2: Created comprehensive `scripts/activate-ticket.sh` with two-phase activation, retry logic, cleanup
- Task 3: Created `commands/activate.md` documenting the GitOps locking mechanism
- Task 4: Added "Ticket Activation" section to README.md with full workflow documentation

**Key Features Implemented:**
- Phase 1 claim with stash/unstash and cleanup on failure
- Retry logic (max 3 attempts) for push conflicts
- Phase 2 worktree creation only after successful claim
- Comprehensive logging to `~/.claude/logs/activate-ticket.log`
- Success banner with clear next steps
- Audit logging for allowed ticket lifecycle commits

## Questions/Concerns

None - design is solid and implementation follows spec exactly.

## Changes Made

**File changes:**
- `hooks/block-main-commits.sh` - Added ticket lifecycle exception
- `scripts/activate-ticket.sh` - NEW - Two-phase activation script
- `commands/activate.md` - NEW - Slash command documentation
- `README.md` - Added Ticket Activation section

**Commits:**
- 8546944a20fdb4a11282826924b140d71e8589b9 - feat: implement ticket activation with GitOps locking

**Status Update**: 2025-12-03 19:45 - Changed status to `critic_review`

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
- Single activation works: [PASS/FAIL]
- Concurrent activation (one wins): [PASS/FAIL]
- Non-ticket commits still blocked: [PASS/FAIL]
- Ticket lifecycle commits allowed: [PASS/FAIL]
- Audit logging works: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-03 19:30] - Coordinator
- Ticket created from handoff prompt
- Analyzed qc-router and ~/docs for existing patterns (none found)
- This is net-new infrastructure for workflow-guard
