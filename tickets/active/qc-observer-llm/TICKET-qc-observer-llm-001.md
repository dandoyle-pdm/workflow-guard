---
# Metadata
ticket_id: TICKET-qc-observer-llm
session_id: qc-observer-llm
sequence: 001
parent_ticket: TICKET-qc-observer-hooks-001
title: QC Observer LLM Intelligence Layer
cycle_type: development
status: critic_review
created: 2025-12-11 22:28
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/qc-observer-llm
---

# Requirements

## What Needs to Be Done

Transform the current observe-violation.sh "weak sauce" log appender into an LLM-powered observer system that:

1. **Extracts insights** from violations (not just logging)
2. **Provides real-time overlay** commentary (Omnyx-style dual consciousness)
3. **Background extraction** at session boundaries (claude-mem style SDKAgent)
4. **Integrates Loop 1/2/3** architecture from qc-router

### Implementation Phases

**Phase 0: Enhanced Schema**
- Add `resource` field: plugin|hook|agent|command|skill
- Add `correlation` field for linking related observations
- Support filtering via OBSERVER_RESOURCES env var

**Phase 1: observe-iteration.sh**
- Capture qc-router Loop 1 data (within-cycle iteration)
- Store in `iterations.jsonl` (separate from violations)
- Track agent sessions and transformations

**Phase 2: qc-observer.md skill**
- Skill injected into prompt context
- Provides real-time overlay commentary
- Uses OBSERVER_KINDS for selective observation

**Phase 3: Bash read observation**
- Add patterns to conditions.yaml for cat/head/tail/grep
- OBSERVE (not block) Bash file reads
- Close the "bash cat" bypass gap

**Phase 4: Counter management**
- Sequence numbers for observations
- Correlation IDs linking related events
- Bounded abstractions: Ticket → Quality Transformer → Agent Session → Claude Session

**Phase 5-7: Background extraction** (future tickets)
- SessionStart injection hook
- Loop 2 cross-cycle tuning
- Periodic insight generation

## Acceptance Criteria

- [x] Schema has `resource` and `correlation` fields
- [x] `observe-iteration.sh` captures Loop 1 data
- [x] `iterations.jsonl` created at ~/.novacloud/observations/
- [x] `qc-observer.md` skill exists in commands/
- [x] Bash read patterns added to conditions.yaml (observe, not block)
- [x] Counter/sequence management implemented
- [x] Existing hooks updated to use enhanced schema

# Context

## Why This Work Matters

The current observer is just a log appender - no intelligence. The goal is LLM-based insight extraction following proven patterns:

1. **Omnyx Observer**: Dual consciousness overlay with real-time commentary
2. **claude-mem**: 6-layer pipeline with separate SDKAgent subprocess

The observer needs to:
- Understand WHAT happened (current logging does this)
- Extract WHY it matters (missing intelligence layer)
- Document patterns for system improvement
- Track effectiveness metrics (80-90% automatic success rate target)

## References
- OBSERVER-PERSONA-ANALYSIS.md: Omnyx overlay pattern documentation
- TICKET-qc-observer-hooks-001: Previous Phase 1 work (type field added)
- qc-router Loop 1/2/3: Three Loops architecture for quality cycles
- claude-mem: SDKAgent background extraction pattern

# Creator Section

## Implementation Notes

Implemented all four phases of the QC Observer LLM intelligence layer:

**Phase 0 - Enhanced Schema:**
- Updated observe-violation.sh header to document `resource` and `correlation` fields
- Modified block-unreviewed-edits.sh to include resource="hook" and correlation="" in violation JSON
- Resource field values: plugin, hook, agent, command, skill
- Correlation field links observations: ticket-id, session-id, agent-session-id

**Phase 1 - observe-iteration.sh:**
- Created hooks/observe-iteration.sh for Loop 1 data capture
- Stores in ~/.novacloud/observations/iterations.jsonl (separate from violations.jsonl)
- Captures agent dispatch events: started, completed, blocked
- Tracks cycle type, agent name, sequence number, and findings
- Fail-safe design prevents breaking agent dispatch on logging errors

**Phase 2 - qc-observer.md Skill:**
- Created commands/qc-observer.md as injectable skill
- Implements Omnyx dual consciousness overlay pattern
- Documents observer protocol: Watch, Comment, Identify, Document
- Environment variable filtering: OBSERVER_RESOURCES, OBSERVER_KINDS
- Transparent (visible to user) and non-interfering design

**Phase 3 - Bash File Read Patterns:**
- Added conditions to engine/conditions.yaml:
  - is-cat-command, is-head-command, is-tail-command
  - is-less-command, is-grep-command
  - is-bash-file-read (compound condition)
- Enables observation of file reads (not blocking)
- Closes "bash cat" bypass gap for observability

**Phase 4 - Counter Management:**
- Implemented get_next_sequence() in both observe-violation.sh and observe-iteration.sh
- File-based counter at ~/.novacloud/observations/.counter
- Atomic locking using mkdir (5 second timeout, 0.1s retry)
- Sequence injected into JSON using jq before storage
- Graceful degradation on failure (proceeds without sequence)
- Unified counter across all observation types

## Questions/Concerns

None - all acceptance criteria met.

## Changes Made

File changes:
- hooks/observe-violation.sh: Enhanced schema docs, counter management
- hooks/block-unreviewed-edits.sh: Added resource and correlation fields
- hooks/observe-iteration.sh: NEW - Loop 1 iteration capture with counter
- commands/qc-observer.md: NEW - Observer skill with dual consciousness protocol
- engine/conditions.yaml: Added bash-file-read patterns

Commits:
1. 7cdedb3 - feat(observer): Phase 0 - Enhanced schema with resource and correlation fields
2. b7f1d66 - feat(observer): Phase 1 - observe-iteration.sh for Loop 1 data capture
3. 2a48654 - feat(observer): Phase 2 - qc-observer.md skill with observer protocol
4. 7e5a4e1 - feat(observer): Phase 3 - Bash file read patterns for observation
5. 234f2d2 - feat(observer): Phase 4 - Counter management for observation sequencing

**Status Update**: 2025-12-11 23:15 - Changed status to `critic_review`

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

## [2025-12-11 22:28] - Creator
- Ticket created from handoff continuation
- Scope defined: Phases 0-4 for this ticket
