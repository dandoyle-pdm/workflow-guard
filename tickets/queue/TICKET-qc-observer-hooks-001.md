---
# Metadata
ticket_id: TICKET-qc-observer-hooks-001
session_id: qc-observer-hooks
sequence: 001
parent_ticket: null
title: Implement QC Observer hooks for quality pattern tracking
cycle_type: development
status: open
created: 2025-12-07 20:45
worktree_path: null
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
[To be filled by plugin-engineer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

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
