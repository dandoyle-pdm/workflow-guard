---
# Metadata
ticket_id: TICKET-plugin-recipe-002
session_id: plugin-recipe
sequence: 002
parent_ticket: TICKET-plugin-recipe-001
title: Align CLAUDE.md with Plugin recipe guidance
cycle_type: documentation
status: approved
created: 2025-12-03 17:35
worktree_path: null
---

# Requirements

## What Needs to Be Done
Update CLAUDE.md to align with DEVELOPER.md's Plugin recipe guidance. Currently CLAUDE.md references R1/R2/R5 cycles, but DEVELOPER.md correctly establishes Plugin recipe as PRIMARY for all workflow-guard work.

**Files to Modify:**
1. `CLAUDE.md` - Update "Development Rules" section (lines 56-61)

## Acceptance Criteria
- [ ] CLAUDE.md line 59 references Plugin recipe instead of R1
- [ ] CLAUDE.md line 60 references Plugin recipe instead of R2
- [ ] CLAUDE.md line 61 clarified (most config is Plugin work)
- [ ] Consistent with DEVELOPER.md lines 273-335
- [ ] No contradictions between CLAUDE.md and DEVELOPER.md

# Context

## Why This Work Matters
CLAUDE.md is the project instructions file that Claude reads at session start. Inconsistent guidance between CLAUDE.md and DEVELOPER.md creates confusion and could lead developers to use the wrong quality cycle.

**Current Inconsistency:**
- CLAUDE.md line 59: "R1 (code-developer → code-reviewer → code-tester) for hook changes"
- DEVELOPER.md line 273: "workflow-guard is a Claude Code plugin. ALL work uses the Plugin recipe."

This contradiction was identified during plugin-tester validation of TICKET-plugin-recipe-001.

## References
- Parent ticket: TICKET-plugin-recipe-001
- DEVELOPER.md lines 273-335 (Plugin recipe guidance)
- CLAUDE.md lines 56-61 (Development Rules to update)

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
- Documentation consistency: [PASS/FAIL]
- CLAUDE.md aligns with DEVELOPER.md: [PASS/FAIL]
- No contradictions: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: Return to TICKET-plugin-recipe-001 for final approval | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-plugin-recipe-003`

# Changelog

## [2025-12-03 17:35] - plugin-tester
- Rework ticket created from TICKET-plugin-recipe-001 validation
- Identified inconsistency between CLAUDE.md and DEVELOPER.md
- Scope: Update CLAUDE.md lines 59-61 to reference Plugin recipe
