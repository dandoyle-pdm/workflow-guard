<!--
TICKET LIFECYCLE

1. Create ticket in tickets/queue/
2. Activate: ./scripts/activate-ticket.sh tickets/queue/TICKET-xxx.md
   - Creates worktree at ~/workspace/worktrees/<project>/<branch>
   - Moves ticket to tickets/active/<branch>/ in worktree
   - Sets status to in_progress

3. Work in worktree (quality cycle: Creator → Critic → Judge)

4. Complete: ./scripts/complete-ticket.sh
   - Moves ticket to tickets/completed/<branch>/
   - Sets status to approved
   - Commits the change

5. Create PR: gh pr create --base main
   - Squash merge includes ticket in completed/

6. Cleanup: ./scripts/cleanup-merged-ticket.sh <branch>
   - Removes worktree
   - Deletes local/remote branch
-->
---
# Metadata
ticket_id: TICKET-{session-id}-{sequence}
session_id: {descriptive-session-id}
sequence: {001, 002, etc}
parent_ticket: {null or TICKET-session-id-###}
title: {Brief description of work}
cycle_type: {development|documentation|architecture|product|design}
status: {open|in_progress|critic_review|expediter_review|approved|blocked}
created: {YYYY-MM-DD HH:MM}
worktree_path: {/path/to/worktree or null}
---

# Requirements

## What Needs to Be Done
[Clear description of the work required]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

# Context

## Why This Work Matters
[Rationale, background, business value]

## References
- Related tickets:
- Related PRs:
- Related issues:
- Documentation:

# Creator Section

## Implementation Notes
[What was built, decisions made, approach taken]

## Questions/Concerns
[Anything unclear or requiring discussion]

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

## [YYYY-MM-DD HH:MM] - Creator
- Ticket created
- Work implemented in worktree

## [YYYY-MM-DD HH:MM] - Critic
- Audit completed
- Decision: [APPROVED/NEEDS_CHANGES]

## [YYYY-MM-DD HH:MM] - Expediter
- Validation completed
- Decision: [APPROVE/REWORK/ESCALATE]
