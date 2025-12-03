---
# Metadata
ticket_id: TICKET-declarative-engine-001
session_id: declarative-engine
sequence: 001
parent_ticket: null
title: Port declarative hook engine to workflow-guard
cycle_type: development
status: open
created: 2025-12-03 14:30
worktree_path: null
---

# Requirements

## What Needs to Be Done
Port the declarative hook engine from qc-router/research/claude-hooks-engine to workflow-guard as a standalone component. This replaces scattered bash scripts with a unified, declarative rule engine.

**Source Reference:** `/home/ddoyle/.claude/plugins/qc-router/research/claude-hooks-engine/`

**Target Location:** `/home/ddoyle/.claude/plugins/workflow-guard/engine/`

**Files to Create:**
1. `engine/dispatcher.py` - Core rule evaluation engine (adapt from source)
2. `engine/cli.py` - CLI tools for inspection/testing (adapt from source)
3. `engine/conditions.yaml` - Reusable condition definitions (scaffold)
4. `engine/actions.yaml` - Reusable action definitions (scaffold)
5. `engine/rules.yaml` - Rule definitions (scaffold)
6. Update `hooks/hooks.json` - Single dispatcher entry point

## Acceptance Criteria
- [ ] dispatcher.py loads and evaluates rules from YAML configuration
- [ ] Conditions support: regex, glob, equals, exists, compound (all/any/not)
- [ ] Actions support: decision (allow/deny/ask), log, script, chain
- [ ] Single hooks.json entry routes ALL events to dispatcher
- [ ] Existing bash hooks callable via `script` action type
- [ ] `python3 engine/cli.py list` shows loaded rules
- [ ] `python3 engine/cli.py test event.json` validates rule matching
- [ ] Exit codes correct: 0=continue, 2=block with stderr message
- [ ] JSON output for permissionDecision when blocking/asking
- [ ] Fail-safe: invalid config continues normally (doesn't break Claude)

# Context

## Why This Work Matters
The current approach of individual bash scripts has critical gaps:
1. `confirm-code-edits.sh` only catches Edit/Write tools
2. Bash heredoc (`cat > file << 'EOF'`) bypasses file tool hooks entirely
3. Each new protection requires a new bash script with duplicated logic

The declarative engine solves this by:
1. Single dispatcher handles ALL tool events
2. Rules compose conditions (regex, glob, compound logic)
3. DANGEROUS_PATTERNS from guardrails.md become reusable conditions
4. New protections are YAML declarations, not code

**Key Architecture Principle:** "Declarative over imperative, composable, fail-safe, inspectable, testable."

## References
- Source implementation: `/home/ddoyle/.claude/plugins/qc-router/research/claude-hooks-engine/`
- Architecture doc: `research/claude-hooks-engine/ARCHITECTURE.md`
- Guardrails research: `/home/ddoyle/.claude/plugins/qc-router/research/guardrails.md`
- Downstream ticket: TICKET-edit-confirmation-001 (depends on this)

## Technical Design

### Directory Structure
```
workflow-guard/
├── engine/
│   ├── dispatcher.py      # Core engine
│   ├── cli.py             # Inspection tools
│   ├── conditions.yaml    # Condition library
│   ├── actions.yaml       # Action library
│   └── rules.yaml         # Rule definitions
├── hooks/
│   ├── hooks.json         # Updated to use dispatcher
│   ├── block-main-commits.sh      # Existing (wrapped as script action)
│   └── ...
```

### hooks.json Update
```json
{
  "PreToolUse": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "python3 engine/dispatcher.py"
    }]
  }]
}
```

### Scaffold conditions.yaml
```yaml
conditions:
  is-bash-tool:
    type: equals
    field: tool_name
    value: Bash

  is-write-tool:
    type: regex
    field: tool_name
    pattern: "^(Edit|Write|MultiEdit)$"
```

### Scaffold actions.yaml
```yaml
actions:
  block:
    type: decision
    decision: deny
    message: "{{message}}"

  allow:
    type: decision
    decision: allow

  require-confirmation:
    type: decision
    decision: ask
    message: "{{message}}"

  run-block-main-commits:
    type: script
    script: hooks/block-main-commits.sh
```

# Creator Section

## Implementation Notes
[To be filled by code-developer]

## Questions/Concerns
[To be filled by code-developer]

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
- Python syntax: [python3 -m py_compile]
- Rule loading: [cli.py list]
- Event handling: [cli.py test with sample events]
- Existing hooks: [Verify block-main-commits still works via script action]
- Fail-safe: [Invalid YAML doesn't crash]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-03 14:30] - Coordinator
- Ticket created from hook engine analysis
- Defines foundation for declarative rule engine
- TICKET-edit-confirmation-001 depends on this completing first
