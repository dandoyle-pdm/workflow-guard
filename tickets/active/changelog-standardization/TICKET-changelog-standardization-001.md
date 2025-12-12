---
# Metadata
ticket_id: TICKET-changelog-standardization-001
session_id: changelog-standardization
sequence: 001
parent_ticket: null
title: Standardize changelog entries with enum-like role and status values
cycle_type: development
status: claimed
claimed_by: ddoyle
claimed_at: 2025-12-11 20:25
created: 2025-12-10 19:45
worktree_path: null
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
[To be filled by plugin-engineer]

## Questions/Concerns
- Should entry format be `## [timestamp] - ROLE` or `## [timestamp] - ROLE: ENTRY_TYPE`?
- Should we enforce chronological order or allow reverse-chronological?
- Should validation hook block or just warn?

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

## [2025-12-10 19:45] - Creator: created
- Ticket created to standardize changelog entries
- Defines enum values for roles, statuses, and entry types
- Root cause: PR #18 had backwards, non-standard changelog entries
