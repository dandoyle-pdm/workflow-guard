---
# Metadata
ticket_id: TICKET-hook-enforcement-gaps-001
session_id: hook-enforcement-gaps
sequence: 001
parent_ticket: null
title: Enforce agent context for all operations and branch rules for writes
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-10 01:50
created: 2025-12-10 03:00
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/hook-enforcement-gaps
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

- [x] New hook `block-main-thread-reads.sh` blocks Read/Glob/Grep without agent context
- [x] hooks.json updated with Read|Glob|Grep matcher
- [x] `block-unreviewed-edits.sh` updated to check branch for writes
- [x] Ticket queue/ files (no sequence) allowed on main
- [x] Ticket active/completed files (with sequence) blocked on main
- [x] Non-ticket files blocked on main regardless of agent
- [x] Explore agent recognized for read operations
- [x] All existing quality agents still work
- [ ] Use case document created in docs/ (deferred - test suite documents behavior)

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

Successfully implemented all four use cases with comprehensive testing:

**UC-1: block-main-thread-reads.sh**
- Created new hook for Read/Glob/Grep operations
- Detects agent context via transcript patterns: "working as the {agent} agent" OR "You are {agent}"
- Recognizes both quality agents AND Explore investigation agent
- Exit 2 blocks operation with clear guidance message
- Exit 0 allows operation when agent context detected

**UC-2 & UC-3: block-unreviewed-edits.sh updates**
- Added branch detection using git branch --show-current
- Added ticket pattern detection: queue vs sequenced tickets
- Branch rules:
  - Protected branch (main/master/production): Only queue tickets allowed
  - Feature branch: All writes allowed with agent context
- Helper functions: is_ticket_queue_file(), is_ticket_with_sequence(), get_current_branch(), is_protected_branch()
- Critical fix: Extract cwd from JSON input for accurate branch detection

**UC-4: hooks.json configuration**
- Added Read|Glob|Grep matcher entry
- Routes to block-main-thread-reads.sh with 5s timeout
- Consistent with other enforcement hooks

**Testing**
- Comprehensive test suite in test-hook-enforcement.sh
- Manual validation confirms all scenarios work correctly:
  - Read operations: Block without agent, allow with agent/Explore
  - Write operations: Branch-specific rules enforced
  - Ticket lifecycle: Queue vs sequenced tickets handled correctly
  - Agent detection: All quality agents + Explore recognized

## Questions/Concerns
✓ How to detect "Explore" agent vs other agents?
  → Added pattern "You are {agent}" in addition to "working as the {agent} agent"

✓ Should we add a new env var CLAUDE_INVESTIGATION_AGENTS?
  → No - included Explore in default agent list in block-main-thread-reads.sh

✓ How to detect current branch from within hook?
  → Use git branch --show-current with cwd from JSON input

## Changes Made
- File changes:
  - hooks/block-main-thread-reads.sh (new, 218 lines)
  - hooks/block-unreviewed-edits.sh (updated, +180 lines)
  - hooks/hooks.json (updated, +10 lines)
  - test-hook-enforcement.sh (new, 362 lines)

- Commits:
  - 7dd8719: feat: add hook to block main thread read operations (UC-1)
  - edecede: feat: add branch detection and ticket rules to write hook (UC-2 & UC-3)
  - 95022d1: feat: register read operations hook in hooks.json (UC-4)
  - dd10b38: fix: extract and use cwd from JSON for branch detection
  - 6b24b5a: test: add comprehensive hook enforcement test suite

**Status Update**: 2025-12-10 04:15 - Changed status to `critic_review`

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

## [2025-12-10 01:50] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/hook-enforcement-gaps
- Branch: ticket/hook-enforcement-gaps

## [2025-12-10 04:15] - plugin-engineer
- Implemented all four use cases (UC-1 through UC-4)
- Created block-main-thread-reads.sh for read operation enforcement
- Updated block-unreviewed-edits.sh with branch detection and ticket rules
- Updated hooks.json with Read|Glob|Grep matcher
- Created comprehensive test suite validating all scenarios
- Fixed branch detection by extracting cwd from JSON input
- All acceptance criteria met except docs (deferred - test suite documents behavior)
- Status changed to critic_review
