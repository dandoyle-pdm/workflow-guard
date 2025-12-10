---
# Metadata
ticket_id: TICKET-ticket-docs-fix-001
session_id: ticket-docs-fix
sequence: 001
parent_ticket: null
title: Fix critical documentation gaps in ticket workflow
cycle_type: documentation
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-10 01:13
created: 2025-12-10 02:30
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/ticket-docs-fix
---

# Requirements

## What Needs to Be Done

Fix critical documentation gaps that caused a process violation where implementation commits landed on main instead of in a worktree.

**Audit found 10 major gaps. Priority fixes:**

### 1. Global CLAUDE.md (~/.claude/CLAUDE.md)

Add to Commit Workflow section:
- "Push immediately after ticket creation commit"
- "Code changes happen in worktree ONLY. Main branch only receives ticket metadata commits (creation, claiming, completion)."

Clarify terminology:
- "main thread" = Claude agent context (subagent vs coordinator)
- "main branch" = git branch (protected, ticket metadata only)

### 2. workflow-guard TEMPLATE.md

Add "claimed" to status list (line 34):
```
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-10 01:13
```

### 3. workflow-guard README.md

Add to Workflow Overview section:
- Explicit statement: "Implementation happens ONLY in worktree, never on main branch"
- Explain GitOps locking pattern (push to main = claim = distributed lock)
- Explain Phase 1 (claiming on main) vs Phase 2 (worktree creation)
- Explain "availability" (ticket pushed to main) vs "locking" (ticket activated/claimed)

## Acceptance Criteria

- [ ] Global CLAUDE.md has explicit "push immediately" rule
- [ ] Global CLAUDE.md has explicit "worktree only" rule for code changes
- [ ] Global CLAUDE.md clarifies "main thread" vs "main branch"
- [ ] TEMPLATE.md includes "claimed" in status list
- [ ] README.md explains GitOps locking pattern
- [ ] README.md explicitly states worktree-only development rule
- [ ] README.md explains Phase 1 vs Phase 2 distinction

# Context

## Why This Work Matters

A process violation occurred where 4 commits landed on main branch instead of in a worktree:
- `61a47be` - ticket creation (correct)
- `2fbd6bd` - fix implementation (WRONG - should be in worktree)
- `be749a8` - ticket update (probably OK)
- `0f9c6c2` - binary rebuild (WRONG - should be in worktree)

Root cause: Documentation doesn't explicitly state that code changes must happen in worktree only, doesn't mention push requirement, and doesn't explain the GitOps locking pattern.

## References

- Audit agent ID: 557ec63b (full audit findings)
- Affected files: ~/.claude/CLAUDE.md, TEMPLATE.md, README.md
- Related: Global CLAUDE.md already updated with directives 7 & 8 (commit e055bbc)

# Creator Section

## Implementation Notes

Fixed all three critical documentation gaps identified in the audit:

### 1. Global CLAUDE.md (~/.claude/CLAUDE.md)
**Location:** Outside worktree (edited directly at ~/.claude/CLAUDE.md)

Added to Commit Workflow section:
- Core Rule: "For ticket creation: push to remote immediately after commit (GitOps locking)"
- Branch Rules subsection with three explicit rules:
  - "Code changes happen in worktree ONLY"
  - "Main branch only receives ticket metadata commits (creation, claiming, completion)"
  - "All implementation must go through feature branch + PR"

Added Terminology Clarification to Process Anti-Patterns section:
- "main thread" = Claude agent context (coordinator vs subagent)
- "main branch" = git branch (protected, ticket metadata only)
- Clear statement these are DIFFERENT concepts

### 2. TEMPLATE.md (in worktree)
Added "claimed" to status list on line 34:
```
status: {open|claimed|in_progress|critic_review|expediter_review|approved|blocked}
```

### 3. README.md (in worktree)
Restructured Workflow Overview section with three new subsections:

**Critical Rule: Worktree-Only Development**
- Explicit statement: "Implementation happens ONLY in worktree, never on main branch"
- Clarifies main branch is for ticket metadata only

**GitOps Locking Pattern**
- Phase 1 (Claiming): Ticket moves queue/ → active/, push to main = distributed lock
- Phase 2 (Activation): Worktree creation on feature branch for development
- Push success = lock acquired, push failure = contention

**Terminology**
- Availability = ticket pushed to main, visible to all
- Locking = ticket activated/claimed, developer owns it

## Questions/Concerns
None - all requirements addressed comprehensively.

## Changes Made
- File changes:
  - ~/.claude/CLAUDE.md (direct edit, outside worktree)
  - tickets/TEMPLATE.md (in worktree)
  - README.md (in worktree)
- Commits:
  - 812a4a9: docs: fix critical workflow documentation gaps (worktree files only)

**Status Update**: 2025-12-10 02:45 - Changed status to `critic_review`

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

## [2025-12-10 02:30] - Coordinator
- Ticket created after audit revealed 10 critical documentation gaps
- Root cause of process violation: missing explicit rules about worktree-only development

## [2025-12-10 01:13] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/ticket-docs-fix
- Branch: ticket/ticket-docs-fix
