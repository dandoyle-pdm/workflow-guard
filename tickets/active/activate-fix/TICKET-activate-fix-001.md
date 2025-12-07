---
# Metadata
ticket_id: TICKET-activate-fix-001
session_id: activate-fix
sequence: 001
parent_ticket: null
title: Fix activate-ticket.sh to use session-id for branch/worktree naming
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-07 11:50
created: 2025-12-07 11:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/activate-fix
---

# Requirements

## What Needs to Be Done

Fix `scripts/activate-ticket.sh` to use session-id (not full ticket name) for:
1. Branch naming: `ticket/{session-id}` not `ticket/TICKET-{session-id}-{sequence}`
2. Worktree directory: `worktrees/{project}/{session-id}/`
3. Active ticket directory: `tickets/active/{session-id}/`

Currently line 222 does:
```bash
local branch_name="ticket/${ticket_id}"  # Wrong: ticket/TICKET-quality-gate-001
```

Should extract session-id and use:
```bash
local branch_name="ticket/${session_id}"  # Correct: ticket/quality-gate
```

## Acceptance Criteria
- [ ] Extract session-id from ticket metadata (preferred) or filename
- [ ] Branch created as `ticket/{session-id}`
- [ ] Worktree directory uses session-id
- [ ] Active directory uses session-id: `tickets/active/{session-id}/`
- [ ] Multiple tickets with same session-id can coexist (001, 002, etc.)
- [ ] Update complete-ticket.sh if needed for consistency
- [ ] Existing tests/validations still pass

# Context

## Why This Work Matters

The current implementation couples branch/directory names to full ticket IDs, causing:
1. Redundant naming: `TICKET-quality-gate-001` repeated in paths
2. Inconsistency with completed tickets which use session-id directories
3. Inability to have multiple sequential tickets on same branch

Completed tickets already use correct pattern:
- `tickets/completed/declarative-engine/TICKET-declarative-engine-001.md`
- `tickets/completed/quality-gate/TICKET-quality-gate-001.md`

## References
- Bug discovered during: TICKET-quality-gate-001 activation
- Related scripts: activate-ticket.sh, complete-ticket.sh
- Pattern reference: tickets/completed/*/

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
- Branch naming correct: [PASS/FAIL]
- Worktree naming correct: [PASS/FAIL]
- Directory naming correct: [PASS/FAIL]
- Existing tickets unaffected: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-07 11:45] - Ticket Created
- Defined requirements for fixing branch/worktree naming
- Session-id should be used instead of full ticket ID
