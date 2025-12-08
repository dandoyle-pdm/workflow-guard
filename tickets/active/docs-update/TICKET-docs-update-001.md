---
# Metadata
ticket_id: TICKET-docs-update-001
session_id: docs-update
sequence: 001
parent_ticket: null
title: Update README.md and documentation with current hook inventory
cycle_type: documentation
status: critic_review
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

Successfully updated all documentation to reflect the current hook inventory of 7 functional hooks (plus 1 diagnostic utility).

**Documentation approach:**
- Each hook documented with consistent structure: purpose, behavior, examples
- Added session-id vs ticket-id naming convention section to clarify automation patterns
- Updated all configuration examples to show complete hook inventory
- Updated architecture diagram to visualize all hooks
- Updated CLAUDE.md for developer quick reference

**Key additions:**
1. `block-mcp-git-commits.sh` - Documented MCP tool protection with explanation of why it's needed
2. `confirm-code-edits.sh` - Documented code edit confirmation with configuration options
3. `validate-ticket-naming.sh` - Documented naming validation with valid/invalid examples
4. Session-ID vs Ticket-ID section - Explains automation patterns and resource naming

## Questions/Concerns

None. All hooks are accurately documented with their current behavior verified from source code.

## Changes Made

**File changes:**
- `/home/ddoyle/.novacloud/worktrees/workflow-guard/docs-update/README.md`
  - Updated hook count from "Four" to "Seven" (line 50)
  - Added documentation for `block-mcp-git-commits` hook
  - Added documentation for `confirm-code-edits` hook
  - Added documentation for `validate-ticket-naming` hook
  - Added "Session-ID vs Ticket-ID Naming" section
  - Updated hooks.json example with all 7 hooks
  - Updated architecture diagram with all 7 hooks
  - Added "Code Edit Confirmation" configuration section

- `/home/ddoyle/.novacloud/worktrees/workflow-guard/docs-update/CLAUDE.md`
  - Updated directory structure to show all 8 hook files
  - Updated Hooks Reference table with all 7 functional hooks

**Commits:**
1. `252f90b` - docs: update hook count from four to seven
2. `bfec2af` - docs: add documentation for block-mcp-git-commits hook
3. `2fd0592` - docs: add documentation for confirm-code-edits hook
4. `5daae00` - docs: add documentation for validate-ticket-naming hook
5. `7a3e44a` - docs: add session-id vs ticket-id naming convention section
6. `4b4449e` - docs: update hooks.json example with all 7 hooks
7. `77018d2` - docs: update architecture diagram with all 7 hooks
8. `e9ce528` - docs: add configuration section for code edit confirmation
9. `cc67945` - docs: update CLAUDE.md with all 7 hooks

**Status Update**: 2025-12-07 18:30 - Changed status to `critic_review`

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
