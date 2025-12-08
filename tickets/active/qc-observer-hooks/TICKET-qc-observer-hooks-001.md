---
# Metadata
ticket_id: TICKET-qc-observer-hooks-001
session_id: qc-observer-hooks
sequence: 001
parent_ticket: null
title: Implement QC Observer hooks for quality pattern tracking
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-08 07:01
created: 2025-12-07 20:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/qc-observer-hooks
---

# Requirements

## What Needs to Be Done

Implement 4 hooks for the QC Observer system in workflow-guard:

| Hook | Trigger | Purpose |
|------|---------|---------|
| qc-observe-hook.js | PreToolUse | Block code edits without quality agent |
| qc-capture-hook.js | PostToolUse | Capture tool execution, log violations |
| qc-context-hook.js | SessionStart | Inject violation summary into context |
| qc-summary-hook.js | SessionEnd | Generate summary, improvement prompts |

## Acceptance Criteria
- [ ] qc-observe-hook.js blocks Edit/Write without quality agent
- [ ] qc-capture-hook.js logs violations to ~/.novacloud/observations/
- [ ] qc-context-hook.js injects violation summary on session start
- [ ] qc-summary-hook.js generates improvement prompts at threshold (3x)
- [ ] Enable/disable via ~/.novacloud/observer-rules.json
- [ ] All hooks short-circuit when disabled (exit 0)

# Context

## Why This Work Matters

QC Observer tracks quality patterns across sessions. Identifies violations, aggregates patterns, and generates improvement prompts when threshold reached.

## Architecture (from qc-router docs)

**Enable/Disable Model:**
```javascript
const rules = loadRules(); // ~/.novacloud/observer-rules.json
if (!rules.enabled) process.exit(0);
```

**Session ID Detection (Agent Identity):**
```javascript
const sessionId = input.session_id;
const agentMatch = sessionId.match(/^(code-developer|code-reviewer|...)-/);
const isInQualityAgent = !!agentMatch;
```

**Storage:**
- Violations: ~/.novacloud/observations/violations.jsonl
- Rules: ~/.novacloud/observer-rules.json
- Patterns: ~/.novacloud/observations/patterns.json

**Violation Types:**
- quality_bypass: Code modification without quality agent
- artifact_standard: File exceeds 50-line limit
- git_workflow: Commit without ticket
- ticket_lifecycle: Ticket state violations
- agent_behavior: Agent protocol violations

## References
- Use case docs: ~/.claude/plugins/qc-router/docs/QC-OBSERVER-USE-CASES.md
- Parent tickets: TICKET-qc-observer-001, TICKET-qc-observer-rework-001 (approved)
- Existing hooks: hooks/*.sh (pattern reference)

# Creator Section

## Implementation Notes

### Key Findings

1. **Blocking Already Exists**: `block-unreviewed-edits.sh` already implements PreToolUse blocking for Edit/Write/NotebookEdit without quality agent context. This makes `qc-observe-hook` redundant.

2. **50-Line Standard Violation**: Initial designs were 150-300 lines each - violates artifact standard. Need to decompose differently.

3. **Language Mismatch**: Ticket specified JavaScript but all existing hooks are Bash. Should maintain consistency.

### Recommended Scope Reduction

Instead of 4 large hooks, implement incrementally:

**Phase 1** (this ticket):
- Add violation logging to existing `block-unreviewed-edits.sh`
- Create `~/.novacloud/observations/` storage infrastructure
- One focused capture function, ≤50 lines

**Phase 2** (new ticket):
- SessionStart context injection
- Pattern aggregation

**Phase 3** (new ticket):
- SessionEnd summary generation
- Improvement prompt generation

### What Already Works

| Original Hook | Status | Existing Implementation |
|---------------|--------|------------------------|
| qc-observe-hook | ✅ EXISTS | block-unreviewed-edits.sh |
| qc-capture-hook | 🆕 NEEDED | Add to blocking hook |
| qc-context-hook | 🆕 NEEDED | Phase 2 |
| qc-summary-hook | 🆕 NEEDED | Phase 3 |

## Questions/Concerns

1. Should we add logging to existing `block-unreviewed-edits.sh` or create separate capture hook?
2. Is phased approach acceptable given 50-line constraint?
3. Bash vs JavaScript - recommend Bash for consistency

## Scope Decisions (2025-12-08)

**Q1: Logging Approach → ADD TO EXISTING HOOK**
- Violation detection IS the logging trigger - can't separate without duplication
- Hook already has context (file_path, tool_name, transcript analysis)
- Adding ~20 lines to existing 264-line file is pragmatic
- No performance overhead from duplicate JSON parsing

**Q2: Phased Approach → APPROVED**
- Phase 1 (this ticket): Violation logging + storage infrastructure
- Phase 2 (new ticket): SessionStart context injection
- Phase 3 (new ticket): SessionEnd summary generation
- Each phase delivers independent value

**Q3: Language → BASH**
- Consistency with existing 7 Bash hooks
- Proven patterns for JSON parsing, logging, exit codes
- No Node.js dependency needed

## Final Scope (Phase 1)

**Deliverables:**
1. `hooks/observe-violation.sh` - Utility to log violations to JSONL (~40 lines)
2. Modification to `block-unreviewed-edits.sh` - Add call to observe-violation (~5 lines)
3. Storage infrastructure: `~/.novacloud/observations/violations.jsonl`

**Out of Scope (future tickets):**
- SessionStart context injection (TICKET-qc-observer-context)
- SessionEnd summary generation (TICKET-qc-observer-summary)
- Pattern aggregation engine
- Improvement prompt generation

## Changes Made
- File changes: None yet (design review completed)
- Commits: None

**Status Update**: 2025-12-07 21:15 - Creator requests scope clarification before implementation
**Status Update**: 2025-12-08 - Scope decisions made, ready for implementation

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] `file:line` - Issue description

### HIGH Issues
- [ ] `file:line` - Issue description

### MEDIUM Issues
- [ ] `file:line` - Suggestion

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Hooks syntax valid: [PASS/FAIL]
- Security review: [PASS/FAIL]
- Enable/disable works: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[Details]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-07 20:45] - Coordinator
- Ticket created for QC Observer hooks implementation
- Based on approved use case docs from qc-router

## [2025-12-08 07:01] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/qc-observer-hooks
- Branch: ticket/qc-observer-hooks
