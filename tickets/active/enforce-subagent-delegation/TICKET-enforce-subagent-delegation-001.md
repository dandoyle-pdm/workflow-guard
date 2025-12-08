---
# Metadata
ticket_id: TICKET-enforce-subagent-delegation-001
session_id: enforce-subagent-delegation
sequence: 001
parent_ticket: null
title: Hook to enforce subagent delegation for code edits
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-08 16:19
created: 2024-12-08 09:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/enforce-subagent-delegation
---

# Requirements

## What Needs to Be Done

Create a hook that blocks direct code modifications in the main thread. All code changes must go through quality cycles via subagents (code-developer, tech-writer, etc.).

The hook should:
1. Intercept Edit, Write, NotebookEdit tool calls
2. Check if the target is a code file (*.go, *.py, *.sh, *.ts, *.js, etc.)
3. Detect if running in main thread vs subagent context
4. Block with actionable error message if violation detected

## Acceptance Criteria

- [ ] Hook blocks Edit/Write/NotebookEdit on code files in main thread
- [ ] Hook allows edits in subagent context (Task tool invocations)
- [ ] Hook allows ticket files (tickets/*.md)
- [ ] Hook allows CLAUDE.md and documentation files
- [ ] Error message explains required process (create ticket → spawn agent)
- [ ] Hook integrates with existing hooks.json configuration
- [ ] Unit tests cover all scenarios

# Context

## Why This Work Matters

**Incident:** During PR #12 review, the main agent directly edited code files instead of:
1. Creating a ticket
2. Spawning code-developer agent
3. Letting quality cycle run

This violates CLAUDE.md which states:
> **DO NOT implement in main thread** - this wastes context
> **Invoke appropriate agent** (code-developer, tech-writer, etc.) with Task tool

Direct edits bypass:
- Code review (critic phase)
- Testing (expediter phase)
- Ticket tracking
- Quality transformers

## References

- Related: block-unreviewed-edits.sh (may need enhancement or replacement)
- CLAUDE.md quality cycle requirements
- kickoff.md delegation rules

# Creator Section

## Implementation Notes
[To be filled by code-developer agent]

## Questions/Concerns
- How to reliably detect subagent context vs main thread?
- Should hook warn or hard-block?
- Integration with existing block-unreviewed-edits.sh?

## Changes Made
- File changes:
- Commits:

# Critic Section

## Audit Findings
[To be filled by code-reviewer agent]

# Expediter Section

## Validation Results
[To be filled by code-tester agent]

# Changelog

## 2024-12-08 09:45 - Main Thread
- Ticket created in queue/
- Awaiting activation and agent delegation

## [2025-12-08 16:19] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/enforce-subagent-delegation
- Branch: ticket/enforce-subagent-delegation
