---
# Metadata
ticket_id: TICKET-linear-qc-docs
session_id: linear-qc-docs
sequence: {assigned at activation}
parent_ticket: null
title: Document LINEAR quality cycle rule - no loops, rework creates -002
cycle_type: documentation
status: open
created: 2025-12-08 01:45
worktree_path: null
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
[To be filled by tech-writer]

# Critic Section
[To be filled by tech-editor]

# Expediter Section
[To be filled by tech-publisher]

# Changelog

## [2025-12-08 01:45] - Ticket Created
- Root cause: TICKET-kickoff-handoff-001 process violation
- Goal: Prevent future violations through clear documentation
