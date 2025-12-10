---
# Metadata
ticket_id: TICKET-hook-enforcement-gaps
session_id: hook-enforcement-gaps
sequence: null
parent_ticket: null
title: Enforce agent context for all operations and branch rules for writes
cycle_type: development
status: open
created: 2025-12-10 03:00
worktree_path: null
---

# Requirements

## What Needs to Be Done

Implement comprehensive hook enforcement so that:
1. ALL operations require agent context (no main thread operations)
2. Writes are restricted by branch (worktree only, except ticket metadata)
3. Reads require Explore subagent (no main thread investigation)

## Use Cases

### UC-1: Read/Glob/Grep Operations

| Scenario | Agent Context | Decision |
|----------|---------------|----------|
| Main thread reads file | None | **BLOCK** - must use Explore subagent |
| Explore subagent reads | Explore | ALLOW |
| Any quality agent reads | code-developer, etc. | ALLOW |

**Implementation**: New hook `block-main-thread-reads.sh`
- Trigger: PreToolUse on Read, Glob, Grep
- Detection: Check transcript for agent marker
- Block if: No agent context found

### UC-2: Write Operations (Edit/Write/NotebookEdit/Bash file writes)

| Scenario | Branch | File Type | Decision |
|----------|--------|-----------|----------|
| Main thread writes | Any | Any | **BLOCK** - no agent |
| Quality agent writes | main | Ticket in queue/ (no sequence) | ALLOW |
| Quality agent writes | main | Ticket with sequence | **BLOCK** - must be in worktree |
| Quality agent writes | main | Non-ticket file | **BLOCK** - must be in worktree |
| Quality agent writes | feature branch/worktree | Any | ALLOW |

**Implementation**: Update `block-unreviewed-edits.sh` or create new hook
- Add branch detection (main vs feature)
- Add ticket sequence detection (queue/ = no sequence = allowed on main)
- Block non-ticket writes on main even with agent context

### UC-3: Ticket Lifecycle on Main

| Scenario | Allowed |
|----------|---------|
| Create ticket in queue/ (TICKET-session-id.md, no sequence) | YES |
| Activate ticket (adds sequence, moves to active/) | YES (via activate-ticket.sh) |
| Update ticket in active/ from main branch | **NO** - must be in worktree |
| Complete ticket (moves to completed/) | YES (via complete-ticket.sh) |

**Key Rule**: Ticket files WITH sequence numbers can only be modified in worktree.

### UC-4: Agent Context Detection

Current detection (keep):
```bash
grep -qE "working as the (${agent_pattern}) agent" "$transcript_path"
```

Agents that should be recognized:
- **Quality agents**: code-developer, code-reviewer, code-tester, plugin-engineer, plugin-reviewer, plugin-tester, prompt-engineer, prompt-reviewer, prompt-tester, tech-writer, tech-editor, tech-publisher
- **Investigation agents**: Explore (for reads)

## Acceptance Criteria

- [ ] New hook `block-main-thread-reads.sh` blocks Read/Glob/Grep without agent context
- [ ] hooks.json updated with Read|Glob|Grep matcher
- [ ] `block-unreviewed-edits.sh` updated to check branch for writes
- [ ] Ticket queue/ files (no sequence) allowed on main
- [ ] Ticket active/completed files (with sequence) blocked on main
- [ ] Non-ticket files blocked on main regardless of agent
- [ ] Explore agent recognized for read operations
- [ ] All existing quality agents still work
- [ ] Use case document created in docs/

# Context

## Why This Work Matters

Current gaps allow:
1. Main thread to read files directly (should use Explore subagent)
2. Writes on main branch if agent context exists (should require worktree)
3. No enforcement of the "main thread coordinates, subagents work" pattern

This caused process violations where implementation commits landed on main instead of in worktrees.

## References

- Investigation agent ID: f5c7eab1 (full current state audit)
- Current agent detection: `block-unreviewed-edits.sh` lines 87-117
- Ticket sequence pattern: `TICKET-{session-id}-{sequence}.md`

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
- How to detect "Explore" agent vs other agents?
- Should we add a new env var CLAUDE_INVESTIGATION_AGENTS?
- How to detect current branch from within hook?

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

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

## [2025-12-10 03:00] - Coordinator
- Ticket created with comprehensive use cases
- Four enforcement scenarios documented (UC-1 through UC-4)
- Acceptance criteria defined
