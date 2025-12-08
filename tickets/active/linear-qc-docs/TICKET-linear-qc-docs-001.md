---
# Metadata
ticket_id: TICKET-linear-qc-docs-001
session_id: linear-qc-docs
sequence: 001
parent_ticket: null
title: Document LINEAR quality cycle rule - no loops, rework creates -002
cycle_type: documentation
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-07 23:58
created: 2025-12-08 01:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/linear-qc-docs
---

# Requirements

## What Needs to Be Done

Document the LINEAR quality cycle rule to prevent process violations where critics call creators directly.

**Problem discovered:** In TICKET-kickoff-handoff-001, when critic said NEEDS_CHANGES, the main thread incorrectly re-invoked creator to fix within the same ticket. This violates the linear flow.

## Acceptance Criteria
- [ ] Add "Linear Flow (NO LOOPS)" section to global ~/.claude/CLAUDE.md
- [ ] Document in workflow-guard that expediter creates rework tickets
- [ ] Update kickoff.md to emphasize linear delegation
- [ ] Clear examples of correct vs incorrect flow

# Context

## Why This Work Matters

Quality cycles must be LINEAR for:
1. **Clear audit trail** - each ticket = one pass through chain
2. **Role separation** - critics audit, don't coordinate rework
3. **Sequence numbers matter** - -002, -003 show rework history
4. **Prevents infinite loops** - clear termination conditions

## Correct Flow

```
TICKET-xxx-001:
  Creator → produces work
  Critic → audits, documents issues (APPROVED or NEEDS_CHANGES)
  Expediter → validates, decides:
    - APPROVE: merge ready
    - CREATE_REWORK_TICKET: creates TICKET-xxx-002
    - ESCALATE: needs human

If rework needed:
TICKET-xxx-002:
  Creator → fixes issues from -001
  Critic → re-audits
  Expediter → decides again
```

## Key Rules to Document

1. **ONE PASS per ticket** - no loops within a ticket
2. **Critic NEVER calls Creator** - documents issues only
3. **Expediter creates rework tickets** - not critic, not main thread
4. **Sequence numbers track rework** - -001, -002, -003...

# Creator Section

## Implementation Notes

### What Was Documented

Added "Linear Quality Cycle" section to README.md (lines 398-481) covering:

1. **The Rule** - ONE PASS per ticket, NO LOOPS
2. **Role Boundaries** - Critics audit only, expediter creates rework tickets
3. **Sequence Numbers** - Track rework iterations (-001, -002, -003)
4. **Why This Matters** - Role separation, audit trail, loop prevention
5. **Correct vs Incorrect Flow** - Examples showing proper linear flow vs violations

### Structure and Placement

Positioned after "Integration with qc-router" and before "Declarative Hook Configuration" for logical flow:
- qc-router integration explains the agent system
- Linear Quality Cycle explains how agents coordinate
- Hook configuration explains technical enforcement

### Documentation Style

- Clear visual diagrams using code blocks
- Concrete examples (TICKET-kickoff-001 process violation)
- Explicit "DO NOT DO THIS" warnings
- Bulleted explanations of why violations are wrong
- Under 100 lines as specified (83 lines total)

### Key Messages Emphasized

1. Critics NEVER call creators directly
2. Expediter (not main thread) creates rework tickets
3. Each ticket = ONE PASS through chain
4. Sequence numbers provide audit trail

# Critic Section
[To be filled by tech-editor]

# Expediter Section
[To be filled by tech-publisher]

# Changelog

## [2025-12-08 01:45] - Ticket Created
- Root cause: TICKET-kickoff-handoff-001 process violation
- Goal: Prevent future violations through clear documentation

## [2025-12-07 23:58] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/linear-qc-docs
- Branch: ticket/linear-qc-docs
