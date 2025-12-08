---
# Metadata
ticket_id: TICKET-kickoff-handoff-001
session_id: kickoff-handoff
sequence: 001
parent_ticket: TICKET-kickoff-cmd-001
title: Make /kickoff handoff-aware for seamless session continuity
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-07 23:30
created: 2025-12-08 01:28
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff
---

# Requirements

## What Needs to Be Done

Enhance `commands/kickoff.md` to recognize and parse handoff prompt structure, enabling seamless session continuity.

**Current state:** Kickoff takes `$ARGUMENTS` as generic input
**Desired state:** Kickoff detects handoff structure and extracts actionable context

## Acceptance Criteria
- [x] Detects handoff prompt structure (has "Session Type:", "Next Steps:", etc.)
- [x] Extracts session type → maps to quality chain
- [x] Extracts ticket reference → continues existing or creates new
- [x] Extracts next steps → immediate actions for agent
- [x] Passes full context to delegated agent
- [x] Falls back to generic analysis if not a handoff
- [x] Stays under 50 lines (37 substantive lines)

# Context

## Why This Work Matters

We control both artifacts:
- **Handoff output** (commands/handoff*.md) - what gets generated
- **Kickoff input** (commands/kickoff.md) - what gets consumed

Making them speak to each other enables true session continuity:
1. `/handoff` generates structured prompt with mental model
2. New session: `/kickoff <paste handoff>` resumes intelligently

## Handoff Structure to Detect

```markdown
## Session Type: {DEBUG|DEVELOPMENT|HOTFIX|INVESTIGATE}
## Next Steps
- Step 1
- Step 2
## Ticket Reference: TICKET-xxx-001 (if exists)
## Current Understanding
...context...
```

## Session Type → Quality Chain Mapping

| Session Type | Quality Chain | Starting Agent |
|--------------|---------------|----------------|
| DEBUG | R1 | code-tester |
| DEVELOPMENT | R1 | code-developer |
| HOTFIX | R5 | code-developer |
| INVESTIGATE | R4 | - (fast path) |

# Creator Section

## Implementation Notes

Added "Handoff Detection" section to kickoff.md with:
- **Detection markers**: Checks for "Session Type:", "Next Steps:", "TICKET-" references, "Current Understanding:"
- **Session type mapping**: DEBUG→R1(code-tester), DEVELOPMENT→R1(code-developer), HOTFIX→R5(code-developer), INVESTIGATE→R4(explore)
- **Context extraction**: Ticket ref, next steps, full context for agent delegation
- **Fallback behavior**: If no handoff detected, use generic work type analysis

The enhancement is compact (added ~12 substantive lines) and maintains single responsibility. Updated Process section to reflect handoff-aware analysis.

## Changes Made
- File changes: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff/commands/kickoff.md
  - Added "Handoff Detection" section (lines 11-25)
  - Updated "Process" section to include handoff path (lines 27-33)
- Total substantive lines: ~37 (well under 50 line limit)
- Commits: 48c3b4e - feat: add handoff detection to /kickoff command

# Critic Section

## Audit Findings
[To be filled during review]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

# Expediter Section

## Validation Results
[To be filled during validation]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

# Changelog

## [2025-12-08 01:28] - Ticket Created
- Enhancement to existing /kickoff command
- Parent: TICKET-kickoff-cmd-001

## [2025-12-08 01:35] - Implementation Complete
- Added handoff detection to kickoff.md
- Status updated to critic_review
- Commit: 48c3b4e

## [2025-12-07 23:30] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff
- Branch: ticket/kickoff-handoff
