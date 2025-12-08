Workflow-Guard Session: Ticket Naming Validation Hook

Context

Working in ~/.claude/plugins/workflow-guard - the enforcement plugin that pairs with qc-router.

A session in qc-router discovered ticket naming inconsistencies. Example bad name: TICKET-MWAA-002-go-rewrite.md (uppercase letters, sequence in wrong position).

Question First

Before implementing, I need to understand the current blocking behavior:

1. What hook blocks Edit/Write operations that aren't from quality agents? The qc-router README describes this integration, but I couldn't identify which hook implements it.
2. Is there existing ticket filename validation? Check if any hook already validates TICKET-\*.md naming patterns.

If No Existing Validation, Implement:

New hook: hooks/validate-ticket-naming.sh

Pattern to enforce: ^TICKET-[a-z0-9]+(-[a-z0-9]+)\*-[0-9]{3}\.md$

Valid: TICKET-mwaa-go-rewrite-001.md, TICKET-qc-hook-fix-002.md

Invalid (block these):
| Example | Problem |
|-------------------------------|---------------------------------------|
| TICKET-MWAA-002-go-rewrite.md | Uppercase, sequence in wrong position |
| ticket-foo-001.md | Lowercase prefix |
| TICKET-foo_bar-001.md | Underscore separator |
| TICKET-foo-1.md | Sequence not 3 digits |

Register in: hooks/hooks.json under Edit|Write matcher

Exempt: TEMPLATE.md

Implementation Notes

An implementation exists in qc-router branch ticket-naming-hook commit ae68900 - can be adapted for workflow-guard patterns. Use as reference only; follow workflow-guard conventions.

Process

1. Create ticket in tickets/queue/
2. Activate with worktree
3. Quality cycle through implementation
4. PR to merge
