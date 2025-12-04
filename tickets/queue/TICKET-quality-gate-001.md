---
# Metadata
ticket_id: TICKET-quality-gate-001
session_id: quality-gate
sequence: 001
parent_ticket: null
title: Implement quality transformer gate hook for file modifications
cycle_type: development
status: open
created: 2025-12-03 22:10
worktree_path: null
---

# Requirements

## What Needs to Be Done

Implement a PreToolUse hook that enforces quality transformer (agent) usage for file modifications. The hook blocks Edit/Write/NotebookEdit operations unless:
1. The operation is on a ticket or handoff file (workflow metadata)
2. A quality agent (from qc-router) is detected in the transcript

This ensures all code changes go through the quality cycle (plugin-engineer → plugin-reviewer → plugin-tester).

## Acceptance Criteria

### Hook Implementation
- [ ] Create `hooks/block-unreviewed-edits.sh`
- [ ] Triggers on: Edit, Write, NotebookEdit tools
- [ ] Reads `transcript_path` from hook JSON input
- [ ] Detects quality agent identity via transcript grep
- [ ] Blocks with guidance if no quality agent detected
- [ ] Allows ticket files (`tickets/**/*.md`) and handoff files (`**/HANDOFF*.md`)
- [ ] Exit codes: 0=allow, 2=block with message

### Declarative Configuration
- [ ] Update `hooks/hooks.json` with new hook entry
- [ ] Use matcher pattern: `Edit|Write|NotebookEdit`
- [ ] Set appropriate timeout (5s recommended)

### Documentation
- [ ] README.md: Add "Integration with qc-router" section
- [ ] README.md: Add "Quality Transformer Requirement" section
- [ ] README.md: Document declarative hook loading in hooks.json
- [ ] Document transcript identity detection pattern
- [ ] List recognized quality agents (configurable)

### Testing
- [ ] Test: Main thread Edit blocked with guidance
- [ ] Test: Quality agent Edit allowed
- [ ] Test: Ticket file Edit allowed (exception)
- [ ] Test: Handoff file Edit allowed (exception)

# Context

## Why This Work Matters

Currently, workflow-guard blocks commits to protected branches but doesn't prevent direct file edits. This allows bypassing the quality cycle by editing files directly without going through quality agents.

The quality gate hook closes this gap by requiring a quality transformer (agent) context for any file modification. This integrates with the qc-router plugin which defines quality agents.

## Integration Architecture

```
workflow-guard (this plugin)          qc-router (sister plugin)
├── hooks/                            ├── agents/
│   └── block-unreviewed-edits.sh     │   ├── plugin-engineer/AGENT.md
│       │                             │   ├── plugin-reviewer/AGENT.md
│       │ reads transcript            │   └── plugin-tester/AGENT.md
│       │ greps for agent identity    │
│       ▼                             │
│   "plugin-engineer agent" ──────────┤ Identity marker in AGENT.md
│       │                             │
│       └── ALLOW if found            └── Dispatched via Task tool
```

## Transcript Identity Pattern

When a quality agent is dispatched via Task tool, the AGENT.md content (including identity marker) appears in the subagent's transcript.

**Pattern to detect:**
```
"working as the plugin-engineer agent"
"working as the plugin-reviewer agent"
"working as the plugin-tester agent"
```

**Grep pattern:**
```bash
grep -qE "plugin-engineer agent|plugin-reviewer agent|plugin-tester agent" "$transcript_path"
```

## Declarative Hook Loading

The `hooks/hooks.json` file declaratively configures which hooks load and when they trigger:

```json
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write|NotebookEdit",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/block-unreviewed-edits.sh",
          "timeout": 5
        }
      ]
    }
  ]
}
```

**Key concepts:**
- Loaded at Claude Code session start
- `matcher`: Regex pattern for tool names
- `command`: Relative path from plugin root
- `timeout`: Max execution time in seconds
- Multiple hooks can be chained for same matcher

## References
- Sister project: `~/.claude/plugins/qc-router/`
- Agent definitions: `~/.claude/plugins/qc-router/agents/`
- Existing hooks: `hooks/block-main-commits.sh` (reference implementation)

# Technical Specification

## Hook Input (JSON via stdin)

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file",
    "old_string": "...",
    "new_string": "..."
  },
  "transcript_path": "/home/user/.claude/projects/.../agent-xxx.jsonl",
  "cwd": "/current/working/directory",
  "session_id": "..."
}
```

## Hook Logic

```bash
1. Parse JSON input (jq or sed fallback)
2. Extract file_path and transcript_path
3. Check if file_path matches exception patterns:
   - tickets/**/*.md → ALLOW
   - **/HANDOFF*.md → ALLOW
4. Check if transcript contains quality agent identity:
   - grep for agent markers
   - If found → ALLOW
5. Otherwise → BLOCK with guidance message
```

## Block Message Format

```
Quality transformer required for file modifications.

This file modification requires a quality agent context.
Use qc-router to dispatch the appropriate agent:

  For implementation: plugin-engineer
  For code review: plugin-reviewer
  For testing: plugin-tester

Example dispatch:
  Task(subagent_type="general-purpose", prompt="You are the plugin-engineer agent...")

See: ~/.claude/plugins/qc-router/agents/
```

## Environment Variables

- `QUALITY_AGENTS`: Comma-separated list of recognized agents (default: plugin-engineer,plugin-reviewer,plugin-tester)

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
[To be filled by plugin-engineer]

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
- Hook syntax valid: [PASS/FAIL]
- Main thread blocked: [PASS/FAIL]
- Quality agent allowed: [PASS/FAIL]
- Ticket exception works: [PASS/FAIL]
- Documentation complete: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-03 22:10] - Ticket Created
- Defined requirements for quality transformer gate hook
- Documented integration architecture with qc-router
- Specified transcript identity detection pattern
- Included declarative hook loading documentation requirements
