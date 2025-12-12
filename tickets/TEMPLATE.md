<!--
TICKET LIFECYCLE

1. Create ticket in tickets/queue/ as TICKET-{session-id}.md (no sequence number)
2. Activate: ./scripts/activate-ticket.sh tickets/queue/TICKET-{session-id}.md
   - Assigns sequence number (001, 002, etc.) automatically
   - Renames to TICKET-{session-id}-{sequence}.md
   - Creates worktree at $WORKTREE_BASE/<project>/<session-id>
   - Moves ticket to tickets/active/<session-id>/ in worktree
   - Sets status to in_progress

3. Work in worktree (quality cycle: Creator → Critic → Expediter)

4. Complete: ./scripts/complete-ticket.sh
   - Moves ticket to tickets/completed/<branch>/
   - Sets status to approved
   - Commits the change

5. Create PR: gh pr create --base main
   - Squash merge includes ticket in completed/

6. Cleanup: ./scripts/cleanup-merged-ticket.sh <branch>
   - Removes worktree
   - Deletes local/remote branch

ENUM DEFINITIONS

Use these standardized values in ticket metadata and changelog entries:

CHANGELOG_ROLE (quality cycle roles):
  - Creator     : Plugin-engineer, code-developer, tech-writer (creates work)
  - Critic      : Plugin-reviewer, code-reviewer, tech-editor (reviews work)
  - Expediter   : Plugin-tester, code-tester, tech-publisher (validates work)

TICKET_STATUS (workflow states):
  - open                : Ticket created in queue/
  - claimed             : Ticket claimed, sequence assigned
  - in_progress         : Active development in worktree
  - critic_review       : Creator done, awaiting Critic audit
  - expediter_review    : Critic approved, awaiting Expediter validation
  - approved            : Ready for PR/merge
  - blocked             : Work cannot proceed (requires intervention)

ENTRY_TYPE (changelog entry types):
  - created     : Ticket created in queue/
  - claimed     : Ticket claimed (sequence assigned, moved to active/)
  - activated   : Worktree created for development
  - work_done   : Creator finished implementation
  - reviewed    : Critic completed audit
  - validated   : Expediter completed validation
  - completed   : Ticket moved to completed/, ready for PR

CHANGELOG FORMAT:
  ## [YYYY-MM-DD HH:MM] - ROLE: ENTRY_TYPE
  - Description of action taken
  - Additional details

  Examples:
    ## [2025-12-10 19:45] - Creator: created
    ## [2025-12-11 08:30] - Creator: activated
    ## [2025-12-11 15:20] - Creator: work_done
    ## [2025-12-11 16:00] - Critic: reviewed
    ## [2025-12-11 16:45] - Expediter: validated

  Entries MUST be in chronological order (oldest first).
-->
---
# Metadata
ticket_id: TICKET-{session-id}
session_id: {descriptive-session-id}
sequence: {assigned at activation: 001, 002, etc}
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

## [YYYY-MM-DD HH:MM] - Creator: created
- Ticket created in queue/
- Requirements defined

## [YYYY-MM-DD HH:MM] - Creator: claimed
- Ticket claimed by {user}
- Sequence assigned

## [YYYY-MM-DD HH:MM] - Creator: activated
- Worktree created for development
- Branch: ticket/{session-id}

## [YYYY-MM-DD HH:MM] - Creator: work_done
- Implementation completed
- Files modified: [list]
- Status changed to critic_review

## [YYYY-MM-DD HH:MM] - Critic: reviewed
- Audit completed
- Decision: [APPROVED/NEEDS_CHANGES]
- Status changed to expediter_review

## [YYYY-MM-DD HH:MM] - Expediter: validated
- Validation completed
- Decision: [APPROVE/REWORK/ESCALATE]
- Status changed to approved

## [YYYY-MM-DD HH:MM] - Creator: completed
- Ticket moved to completed/
- Ready for PR creation
