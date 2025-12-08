---
# Metadata
ticket_id: TICKET-kickoff-handoff
session_id: kickoff-handoff
sequence: {assigned at activation}
parent_ticket: TICKET-kickoff-cmd-001
title: Make /kickoff handoff-aware for seamless session continuity
cycle_type: development
status: open
created: 2025-12-08 01:28
worktree_path: null
---

# Requirements

## What Needs to Be Done

Enhance `commands/kickoff.md` to recognize and parse handoff prompt structure, enabling seamless session continuity.

**Current state:** Kickoff takes `$ARGUMENTS` as generic input
**Desired state:** Kickoff detects handoff structure and extracts actionable context

## Acceptance Criteria
- [ ] Detects handoff prompt structure (has "Session Type:", "Next Steps:", etc.)
- [ ] Extracts session type → maps to quality chain
- [ ] Extracts ticket reference → continues existing or creates new
- [ ] Extracts next steps → immediate actions for agent
- [ ] Passes full context to delegated agent
- [ ] Falls back to generic analysis if not a handoff
- [ ] Stays under 50 lines

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
[To be filled during implementation]

## Changes Made
- File changes: [To be filled]
- Commits: [To be filled]

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
