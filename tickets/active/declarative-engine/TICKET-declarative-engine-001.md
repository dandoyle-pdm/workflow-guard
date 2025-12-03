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
1. `engine/cmd/dispatcher/main.go` - Core rule evaluation engine (Go binary)
2. `engine/cmd/hookctl/main.go` - CLI tools for inspection/testing
3. `engine/internal/` - Internal packages (config, conditions, actions, rules)
4. `engine/conditions.yaml` - Reusable condition definitions (scaffold)
5. `engine/actions.yaml` - Reusable action definitions (scaffold)
6. `engine/rules.yaml` - Rule definitions (scaffold)
7. `engine/go.mod` - Go module definition
8. Update `hooks/hooks.json` - Single dispatcher entry point

**Why Go over Python:**
- Fast startup (~1ms vs ~100ms) - critical for hooks on every tool invocation
- Single static binary - no Python/PyYAML dependencies
- Excellent JSON/YAML and regex performance
- Drop-in deployment

## Acceptance Criteria
- [ ] dispatcher binary loads and evaluates rules from YAML configuration
- [ ] Conditions support: regex, glob, equals, exists, compound (all/any/not)
- [ ] Actions support: decision (allow/deny/ask), log, script, chain
- [ ] Single hooks.json entry routes ALL events to dispatcher
- [ ] Existing bash hooks callable via `script` action type
- [ ] `hookctl list` shows loaded rules
- [ ] `hookctl test event.json` validates rule matching
- [ ] Exit codes correct: 0=continue, 2=block with stderr message
- [ ] JSON output for permissionDecision when blocking/asking
- [ ] Fail-safe: invalid config continues normally (doesn't break Claude)
- [ ] Go binaries build without errors (`go build ./...`)

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
│   ├── cmd/
│   │   ├── dispatcher/main.go    # Hook dispatcher binary
│   │   └── hookctl/main.go       # CLI tool binary
│   ├── internal/
│   │   ├── config/               # YAML config loading
│   │   ├── conditions/           # Condition evaluation
│   │   ├── actions/              # Action execution
│   │   └── rules/                # Rule matching
│   ├── conditions.yaml           # Condition library
│   ├── actions.yaml              # Action library
│   ├── rules.yaml                # Rule definitions
│   └── go.mod                    # Go module
├── hooks/
│   ├── hooks.json                # Updated to use dispatcher
│   ├── block-main-commits.sh     # Existing (wrapped as script action)
│   └── ...
```

### hooks.json Update
```json
{
  "PreToolUse": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "engine/bin/dispatcher"
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
- Go build: [go build ./... succeeds]
- Go tests: [go test ./... passes]
- Rule loading: [hookctl list works]
- Event handling: [hookctl test with sample events]
- Existing hooks: [Verify block-main-commits still works via script action]
- Fail-safe: [Invalid YAML doesn't crash dispatcher]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-03 16:00] - Coordinator
- Updated ticket for Go implementation (was Python)
- Rationale: Fast startup (~1ms vs ~100ms), single binary, no dependencies
- Updated directory structure for Go project layout
- Updated acceptance criteria and validation steps

## [2025-12-03 14:30] - Coordinator
- Ticket created from hook engine analysis
- Defines foundation for declarative rule engine
- TICKET-edit-confirmation-001 depends on this completing first
