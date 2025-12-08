---
# Metadata
ticket_id: TICKET-kickoff-cmd-001
session_id: kickoff-cmd
sequence: 001
parent_ticket: null
title: Create /kickoff slash command for session coordination
cycle_type: development
status: claimed
claimed_by: ddoyle
claimed_at: 2025-12-07 23:02
created: 2025-12-07 20:45
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create `commands/kickoff.md` (~45 lines) - a slash command that kickstarts sessions with quality chain coordination.

## Acceptance Criteria
- [ ] Creates commands/kickoff.md
- [ ] Command analyzes work type from $ARGUMENTS
- [ ] Selects appropriate quality recipe (R1-R5)
- [ ] Creates ticket if tracked work
- [ ] Delegates to appropriate agent via Task tool
- [ ] ≤50 lines, single-responsibility

# Context

## Why This Work Matters

Enables consistent session starts. Currently sessions require manual quality chain coordination. This command automates the pattern.

## Command Specification

```markdown
---
description: Kickstart session with quality chain coordination
---

Use ultrathink to coordinate quality chains for this kickoff.

## Kickoff Prompt
$ARGUMENTS

## Process
1. Analyze - What type of work?
2. Select chain - Match to quality recipe
3. Ticket - Create if tracked, push immediately
4. Delegate - Invoke agent via Task tool

## Recipes
| Type | Chain | Agent |
|------|-------|-------|
| Code | R1 | code-developer |
| Docs | R2 | tech-writer |
| Plugin | Plugin | plugin-engineer |

## Rules
- 50 lines, single-responsibility, all artifacts
- Never implement in main thread
- Push tickets immediately
```

## References
- Existing commands: commands/*.md (handoff-*.md, activate.md)
- Quality recipes: qc-router CLAUDE.md

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] `file:line` - Issue description

### HIGH Issues
- [ ] `file:line` - Issue description

### MEDIUM Issues
- [ ] `file:line` - Suggestion

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Command syntax valid: [PASS/FAIL]
- ≤50 lines: [PASS/FAIL]
- References correct: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[Details]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-07 20:45] - Coordinator
- Ticket created for /kickoff command implementation
