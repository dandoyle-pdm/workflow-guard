---
# Metadata
ticket_id: TICKET-task-description-enforcement
session_id: task-description-enforcement
sequence: {assigned at activation}
parent_ticket: TICKET-statusline-agent-001
title: Enforce Task description format with project:branch and agent context
cycle_type: development
status: open
created: 2025-12-11 18:45
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PreToolUse hook that enforces a standard format for Task tool descriptions, providing visibility into which project, branch, and agent is doing work.

Required format:
```
[project:branch] agent - description
```

Example:
```
[workflow-guard:ticket/statusline-agent] code-developer - Implement validation hooks
```

## Acceptance Criteria
- [ ] PreToolUse hook intercepts Task tool invocations
- [ ] Hook validates description matches pattern `[project:branch] agent - description`
- [ ] Hook blocks (exit 2) with clear error message if format invalid
- [ ] Error message shows expected format and example
- [ ] Valid descriptions pass through (exit 0)
- [ ] Hook registered in hooks.json

# Context

## Why This Work Matters

When multiple agents work across multiple worktrees in parallel, users need visibility into what's happening where. The Task tool already displays its description in terminal output - by enforcing a standard format, we get visibility "for free" without state files or status line modifications.

This replaces the state-based approach from TICKET-statusline-agent-001, which had a fundamental flaw: single global state file doesn't work with parallel worktrees/sessions.

## References
- Parent ticket: TICKET-statusline-agent-001 (PR #20 - to be cleaned up after merge)
- Discussion: Status line can only show one value; Task description is visible per-invocation

## Technical Design

### Hook Implementation

`hooks/validate-task-description.sh`:
```bash
#!/usr/bin/env bash
# Validate Task description follows [project:branch] agent - description format

set -euo pipefail

# Read JSON input
json_input=$(cat)

# Only process Task tool
tool_name=$(echo "$json_input" | jq -r '.tool_name // ""')
if [[ "$tool_name" != "Task" ]]; then
  exit 0
fi

# Extract description
description=$(echo "$json_input" | jq -r '.parameters.description // ""')

# Validate format: [project:branch] agent - description
PATTERN='^\[[^:]+:[^\]]+\] [^ ]+ - .+'
if [[ ! "$description" =~ $PATTERN ]]; then
  echo "ERROR: Task description must follow format: [project:branch] agent - description"
  echo ""
  echo "Got: $description"
  echo ""
  echo "Expected format:"
  echo "  [project:branch] agent - description"
  echo ""
  echo "Examples:"
  echo "  [workflow-guard:ticket/statusline] code-developer - Implement hooks"
  echo "  [orthofeet:feature/new-sku] tech-writer - Document API changes"
  echo "  [docs:main] Explore - Research codebase structure"
  exit 2  # Block the tool
fi

exit 0
```

### Hook Registration

Add to `hooks/hooks.json` PreToolUse section:
```json
{
  "matcher": "Task",
  "hooks": [
    {
      "type": "command",
      "command": "hooks/validate-task-description.sh",
      "timeout": 5
    }
  ]
}
```

### Cleanup After Merge

Once TICKET-statusline-agent-001 PR #20 is merged:
- Remove `hooks/track-agent-state.sh`
- Remove `hooks/clear-agent-state.sh`
- Remove Task matchers for those hooks from hooks.json
- The validation hook replaces them

# Creator Section

## Implementation Notes
[What was built, decisions made, approach taken]

## Questions/Concerns
- Should we validate that `agent` in description matches `subagent_type` parameter?
- Should project name be validated against actual git remote/directory?

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

## [2025-12-11 18:45] - Coordinator
- Ticket created as follow-up to TICKET-statusline-agent-001
- Enforcement approach replaces state-based tracking
