---
description: Activate a ticket with GitOps locking to claim ownership
---

Activate a ticket for development work with distributed locking.

## What This Command Does

1. **Claims the ticket** by moving it from `queue/` to `active/` on main branch
2. **Pushes to origin** - the push serves as an atomic distributed lock
3. **Creates a worktree** with a feature branch for isolated development
4. **Updates ticket metadata** with worktree path and status

## Usage

Run the activation script with the ticket path:

```bash
scripts/activate-ticket.sh tickets/queue/TICKET-{session-id}-{sequence}.md
```

## Locking Mechanism

- **Primary lock:** Commit + push to main (moving ticket file)
- **Fallback:** Feature branch push
- **Conflict handling:** If push fails, another developer claimed the ticket

## What Happens on Conflict

If another developer claims the ticket first:
- Your push to main will fail
- The script retries up to 3 times
- If ticket is gone from queue/, abort with clear message
- No worktree is created, no wasted work

## After Activation

Navigate to the worktree and begin development:

```bash
cd $WORKTREE_BASE/{project}/{ticket-id}
```

Use Plugin recipe agents (plugin-engineer, plugin-reviewer, plugin-tester) for implementation.

When complete, run `scripts/complete-ticket.sh`.
