---
# Metadata
ticket_id: TICKET-lifecycle-complete-001
session_id: lifecycle-complete
sequence: 001
parent_ticket: null
title: Implement complete-ticket.sh for ticket lifecycle completion
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-03 20:01
created: 2025-12-03 22:15
worktree_path: /home/ddoyle/workspace/worktrees/workflow-guard/TICKET-lifecycle-complete-001
---

# Requirements

## What Needs to Be Done
Implement `scripts/complete-ticket.sh` - a script that moves a ticket from `tickets/active/{branch}/` to `tickets/completed/{branch}/`, updates its status to approved, adds a changelog entry, and commits the change.

## Acceptance Criteria
- [ ] Script auto-detects ticket from current worktree if no path provided
- [ ] Validates we're in a worktree (not main repo) for safety
- [ ] Updates ticket metadata: status → approved
- [ ] Moves ticket: active/{branch}/ → completed/{branch}/
- [ ] Adds changelog entry with timestamp
- [ ] Commits with message: "complete: TICKET-xxx"
- [ ] Pushes to feature branch (with option to skip)
- [ ] Outputs success message with next steps (create PR)
- [ ] Follows patterns from activate-ticket.sh (logging, error handling)

# Context

## Why This Work Matters
The ticket lifecycle has three phases: activate → complete → cleanup. `activate-ticket.sh` is done. This script completes the second phase, allowing developers to mark work as done and prepare for PR creation.

## References
- Related tickets: TICKET-gitops-activation-001 (parent feature)
- Related PRs: #4 (merged)
- Documentation: README.md, TEMPLATE.md
- Reference implementation: scripts/activate-ticket.sh

# Technical Specification

## Script Usage
```bash
# Auto-detect ticket from current worktree
complete-ticket.sh

# Explicit ticket path
complete-ticket.sh tickets/active/TICKET-xxx-001/TICKET-xxx-001.md

# Skip push
complete-ticket.sh --no-push
```

## Required Functions
Following patterns from activate-ticket.sh:
- `log_info`, `log_error`, `log_success` - Logging utilities
- `get_main_repo_root` - Detect main repo vs worktree
- `get_current_branch` - Extract branch name
- `find_active_ticket` - Locate ticket in active/
- `is_worktree` - Safety validation

## Main Flow
1. Detect if we're in a worktree (safety check - abort if main repo)
2. Get current branch name
3. Find ticket in tickets/active/{branch}/ (auto-detect or use provided path)
4. Validate ticket exists and is in expected state
5. Update status to 'approved'
6. Add changelog entry: "[timestamp] - Completed"
7. Create completed directory: mkdir -p tickets/completed/{branch}/
8. Move ticket: git mv tickets/active/{branch}/TICKET-xxx.md tickets/completed/{branch}/
9. Commit: "complete: TICKET-xxx"
10. Push to feature branch (unless --no-push)
11. Output success message with next steps

## Edge Cases
- User in main repo → Error with helpful message
- No ticket found → Error listing possible locations
- Ticket already in completed → Skip with warning
- Git operations fail → Proper cleanup and error message
- Multiple tickets in active/ → Error, require explicit path

## Security Considerations
- Must validate worktree context before modifying files
- Use git mv (not mv) to track the move properly
- Validate ticket filename format before operations

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
- Worktree detection: [PASS/FAIL]
- Ticket move works: [PASS/FAIL]
- Commit created: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-03 22:15] - Ticket Created
- Defined requirements and acceptance criteria
- Technical specification based on activate-ticket.sh patterns

## [2025-12-03 20:01] - Activated
- Worktree: /home/ddoyle/workspace/worktrees/workflow-guard/TICKET-lifecycle-complete-001
- Branch: ticket/TICKET-lifecycle-complete-001
