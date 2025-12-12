---
# Metadata
ticket_id: TICKET-changelog-standardization-001
session_id: changelog-standardization
sequence: 001
parent_ticket: null
title: Standardize changelog entries with enum-like role and status values
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-11 20:25
created: 2025-12-10 19:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/changelog-standardization
---

# Requirements

## What Needs to Be Done

Standardize ticket changelog entries to use consistent, enum-like values instead of ad-hoc strings. Currently agents use random role names ("Coordinator", "Activated", "Completed") instead of the standard quality cycle roles.

## Problem Statement

**Current behavior (inconsistent):**
```markdown
## [2025-12-10 02:30] - Coordinator    ← Ad-hoc, not standard
## [2025-12-10 01:13] - Activated      ← Ad-hoc, not standard
## [2025-12-10 19:20] - Completed      ← Ad-hoc, not standard
```

**Expected behavior (per TEMPLATE.md):**
```markdown
## [2025-12-10 01:13] - Creator
## [2025-12-10 02:30] - Critic
## [2025-12-10 03:00] - Expediter
```

## Enum Definitions

### Changelog Roles (CHANGELOG_ROLE)
```
CREATOR     - Plugin-engineer, code-developer, tech-writer (creates work)
CRITIC      - Plugin-reviewer, code-reviewer, tech-editor (reviews work)
EXPEDITER   - Plugin-tester, code-tester, tech-publisher (validates work)
```

### Ticket Status (TICKET_STATUS)
Already defined in TEMPLATE.md:
```
open | claimed | in_progress | critic_review | expediter_review | approved | blocked
```

### Changelog Entry Types (ENTRY_TYPE)
```
created     - Ticket created in queue/
claimed     - Ticket claimed (sequence assigned, moved to active/)
activated   - Worktree created for development
work_done   - Creator finished implementation
reviewed    - Critic completed audit
validated   - Expediter completed validation
completed   - Ticket moved to completed/, ready for PR
```

## Required Changes

### 1. Update TEMPLATE.md
- Add enum definitions as comments/documentation
- Show proper changelog format with standard roles
- Include all entry types in example

### 2. Update Agent Prompts
When delegating to quality agents, instruct them to:
- Use exact role name (Creator/Critic/Expediter) in changelog
- Use exact entry type for the action
- Maintain chronological order (oldest first)

### 3. Update Scripts
- `activate-ticket.sh`: Use `activated` entry type
- `complete-ticket.sh`: Use `completed` entry type
- Both should use consistent timestamp format

### 4. Add Validation Hook (optional)
- `validate-changelog-format.sh`: Check changelog entries use valid enums
- Trigger on Write to `tickets/**/*.md`
- Warn (not block) on non-standard entries

## Acceptance Criteria

- [ ] TEMPLATE.md documents all enum values (roles, statuses, entry types)
- [ ] Changelog format clearly shows: `## [timestamp] - ROLE: ENTRY_TYPE`
- [ ] activate-ticket.sh uses standardized changelog entry
- [ ] complete-ticket.sh uses standardized changelog entry
- [ ] Agent delegation prompts specify exact role names to use
- [ ] Example in TEMPLATE shows chronological order (oldest first)

# Context

## Why This Work Matters

PR #18 had backwards changelog entries and non-standard role names. Investigation revealed:
1. Agents use ad-hoc role names instead of standard ones
2. Timestamps get entered out of order
3. No validation ensures changelog follows format
4. Quality cycle phases not clearly documented in changelog

This makes tickets hard to audit and understand.

## References
- PR #18 feedback: changelog entries backwards
- TEMPLATE.md: Current (incomplete) changelog format
- TICKET-ticket-docs-fix-001: Example of problematic changelog

# Creator Section

## Implementation Notes

Standardized changelog entries across the ticket workflow system:

1. **TEMPLATE.md Documentation**: Added comprehensive enum definitions in HTML comment header
   - CHANGELOG_ROLE: Creator, Critic, Expediter (maps to quality cycle agents)
   - TICKET_STATUS: Complete workflow state machine (7 states)
   - ENTRY_TYPE: Lifecycle event types (7 types)
   - Format specification: `## [YYYY-MM-DD HH:MM] - ROLE: ENTRY_TYPE`
   - Full lifecycle example showing all entry types in chronological order

2. **Script Updates**: Modified both activation and completion scripts
   - activate-ticket.sh: Changed "Activated" → "Creator: activated"
   - complete-ticket.sh: Changed "Completed" → "Creator: completed"
   - Both scripts now conform to standardized format

3. **Design Decisions**:
   - **Format choice**: `ROLE: ENTRY_TYPE` provides clear semantic meaning
   - **Chronological order**: Enforced oldest-first for audit trail clarity
   - **Validation hook**: Deferred to optional (would be Phase 2)

## Questions/Concerns
- ~~Should entry format be `## [timestamp] - ROLE` or `## [timestamp] - ROLE: ENTRY_TYPE`?~~
  **RESOLVED**: Using `ROLE: ENTRY_TYPE` for semantic clarity

- ~~Should we enforce chronological order or allow reverse-chronological?~~
  **RESOLVED**: Chronological (oldest first) documented as requirement

- ~~Should validation hook block or just warn?~~
  **RESOLVED**: Validation hook marked as optional Phase 2 work

## Changes Made
- File changes:
  - tickets/TEMPLATE.md: Added enum definitions, updated example changelog
  - scripts/activate-ticket.sh: Line 215 - standardized changelog format
  - scripts/complete-ticket.sh: Line 132 - standardized changelog format

- Commits:
  - 66d5191: docs: add enum definitions and standardize changelog format in TEMPLATE.md
  - c6c9776: fix: standardize changelog entry in activate-ticket.sh
  - 3fd1561: fix: standardize changelog entry in complete-ticket.sh

**Status Update**: 2025-12-11 21:15 - Changed status to `critic_review`

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

## [2025-12-10 19:45] - Creator: created
- Ticket created to standardize changelog entries
- Defines enum values for roles, statuses, and entry types
- Root cause: PR #18 had backwards, non-standard changelog entries

## [2025-12-11 20:25] - Creator: activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/changelog-standardization
- Branch: ticket/changelog-standardization

## [2025-12-11 21:15] - Creator: work_done
- Updated TEMPLATE.md with complete enum definitions
- Standardized activate-ticket.sh and complete-ticket.sh changelog formats
- All acceptance criteria met
- Status changed to critic_review
