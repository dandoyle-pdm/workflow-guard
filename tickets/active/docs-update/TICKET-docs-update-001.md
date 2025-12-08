---
# Metadata
ticket_id: TICKET-docs-update-001
session_id: docs-update
sequence: 001
parent_ticket: null
title: Update README.md and documentation with current hook inventory
cycle_type: documentation
status: in_progress
created: 2025-12-07 17:55
worktree_path: ~/.novacloud/worktrees/workflow-guard/docs-update
---

# Requirements

## What Needs to Be Done

Update all documentation to reflect the current state of workflow-guard after PRs #7 and #8 merged:

### README.md Updates
1. Update hook count from "Four" to "Seven" PreToolUse hooks (actual count verified)
2. Add documentation for `block-unreviewed-edits.sh` (quality gate hook)
3. Add documentation for `validate-ticket-naming.sh` (naming validation hook)
4. Document the quality agent detection mechanism
5. Document ticket naming conventions enforced by the validation hook
6. Update any diagrams or tables showing hook inventory

### New Hooks to Document

**block-unreviewed-edits.sh**
- Purpose: Enforces quality agent context for file modifications
- Triggers on: Edit, Write, NotebookEdit
- Blocks unless: quality agent detected in transcript OR file is ticket/handoff
- 12 recognized agents from qc-router
- Environment variable: `CLAUDE_QUALITY_AGENTS`

**validate-ticket-naming.sh**
- Purpose: Enforces ticket naming conventions
- Triggers on: Write to tickets/ directory
- Validates: `^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$`
- Validates: Directory uses session-id (not full ticket name)
- Exception: tickets/queue/ only validates filename (not directory)

### Script Changes to Document
- `activate-ticket.sh` now uses session-id for branch/worktree naming
- `complete-ticket.sh` fixed worktree detection

## Acceptance Criteria
- [ ] README.md hook count updated to 7
- [ ] block-unreviewed-edits.sh fully documented
- [ ] validate-ticket-naming.sh fully documented
- [ ] Ticket naming convention documented
- [ ] Session-id vs ticket-id naming explained
- [ ] Environment variables documented
- [ ] All examples use correct naming patterns

# Context

## Why This Work Matters

Documentation is out of sync with implementation after merging:
- PR #7: activate-fix (session-id naming + validation hook)
- PR #8: quality-gate (quality enforcement hook)

Users and future sessions need accurate documentation to understand the current hook behavior.

## References
- PR #7: https://github.com/dandoyle-pdm/workflow-guard/pull/7
- PR #8: https://github.com/dandoyle-pdm/workflow-guard/pull/8
- Existing hooks: hooks/*.sh
- Current README.md needs updates

# Creator Section

## Implementation Notes
[To be filled by tech-writer]

## Questions/Concerns
[To be filled by tech-writer]

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
- Documentation accurate: [PASS/FAIL]
- All hooks documented: [PASS/FAIL]
- Examples correct: [PASS/FAIL]
- No stale information: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-07 18:15] - Ticket Activated
- Moved to active/docs-update/, worktree created
- Corrected hook count: 7 functional hooks (not 6)

## [2025-12-07 17:55] - Ticket Created
- Documentation update needed after PRs #7 and #8 merged
- Seven hooks now exist, README says four
