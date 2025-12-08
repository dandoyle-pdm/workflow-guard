---
# Metadata
ticket_id: TICKET-kickoff-cmd-001
session_id: kickoff-cmd
sequence: 001
parent_ticket: null
title: Create /kickoff slash command for session coordination
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-07 23:02
created: 2025-12-07 20:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-cmd
---

# Requirements

## What Needs to Be Done

Create `commands/kickoff.md` (~45 lines) - a slash command that kickstarts sessions with quality chain coordination.

## Acceptance Criteria
- [x] Creates commands/kickoff.md
- [x] Command analyzes work type from $ARGUMENTS
- [x] Selects appropriate quality recipe (R1-R5)
- [x] Creates ticket if tracked work
- [x] Delegates to appropriate agent via Task tool
- [x] ≤50 lines, single-responsibility

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

The `/kickoff` command has been successfully implemented in `commands/kickoff.md` (44 lines).

**Design decisions:**
1. **Comprehensive recipe table** - Includes all quality recipes (R1-R5) plus Plugin and Prompt recipes for complete coverage
2. **Clear 5-step process** - Analyze → Select chain → Ticket → Push → Delegate
3. **Ultrathink instruction** - Command starts with "Use ultrathink to coordinate quality chains" to ensure proper reasoning
4. **$ARGUMENTS placeholder** - Captures user's kickoff request verbatim
5. **Explicit rules section** - Reinforces 50-line limit, single responsibility, and delegation requirements
6. **Ticket template guidance** - References project's `tickets/TEMPLATE.md` with key field examples

**Implementation approach:**
- Followed existing command format (handoff.md, activate.md style)
- Used markdown table for recipe mapping with Starting Agent column
- Included enforcement rules to prevent common anti-patterns
- Added ticket template section for workflow integration

**Line count:** 44 lines (6 under the 50-line limit)

## Changes Made
- File changes:
  - `commands/kickoff.md` - Created new slash command (44 lines)
- Commits:
  - `1a2df52` - "feat: add /kickoff command for session coordination"

**Status Update**: 2025-12-07 23:15 - Changed status to `critic_review`

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

## [2025-12-07 23:02] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-cmd
- Branch: ticket/kickoff-cmd

## [2025-12-07 23:15] - plugin-engineer
- Implemented `commands/kickoff.md` (44 lines)
- All acceptance criteria met
- Status changed to `critic_review`
