---
# Metadata
ticket_id: TICKET-qc-observer-llm
session_id: qc-observer-llm
sequence: {assigned at activation}
parent_ticket: TICKET-qc-observer-hooks-001
title: QC Observer LLM Intelligence Layer
cycle_type: development
status: open
created: 2025-12-11 22:28
worktree_path: null
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

- [ ] Schema has `resource` and `correlation` fields
- [ ] `observe-iteration.sh` captures Loop 1 data
- [ ] `iterations.jsonl` created at ~/.novacloud/observations/
- [ ] `qc-observer.md` skill exists in commands/
- [ ] Bash read patterns added to conditions.yaml (observe, not block)
- [ ] Counter/sequence management implemented
- [ ] Existing hooks updated to use enhanced schema

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
[To be filled during implementation]

## Questions/Concerns
[To be filled during implementation]

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

## [2025-12-11 22:28] - Creator
- Ticket created from handoff continuation
- Scope defined: Phases 0-4 for this ticket
