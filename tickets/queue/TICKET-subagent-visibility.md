---
# Metadata
ticket_id: TICKET-subagent-visibility
session_id: subagent-visibility
sequence: null
parent_ticket: null
title: Add PostToolUse hook for subagent activity visibility
cycle_type: development
status: open
created: 2025-12-11 12:00
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PostToolUse hook that logs subagent activity to provide visibility into when subagents are performing work versus the main thread. This improves audit trails and helps users understand work attribution.

**Deliverables:**
1. New hook script: `hooks/log-subagent-activity.sh`
2. Register hook in `hooks/hooks.json` under PostToolUse
3. Hook should log Task tool invocations to `~/.claude/logs/subagent-activity.log`

## Acceptance Criteria
- [ ] PostToolUse hook fires after Task tool completes
- [ ] Log file created at `~/.claude/logs/subagent-activity.log`
- [ ] Log entries include: timestamp, session_id, subagent_type, description
- [ ] Hook is non-blocking (exit 0 always)
- [ ] Hook registered in hooks.json under PostToolUse
- [ ] Hook doesn't block or slow down Task execution

# Context

## Why This Work Matters

Users cannot currently distinguish when subagents are doing work versus the main thread. This creates confusion about:
- Who performed file reads/writes
- Whether quality cycle agents are being used
- Audit trail for work attribution

By logging subagent activity, we provide transparency into the quality cycle and make it clear when specialized agents (code-developer, plugin-reviewer, tech-writer, etc.) are performing work.

## References
- Related tickets: None
- Related PRs: None
- Related issues: None
- Documentation:
  - Existing PostToolUse hook: `hooks/detect-protected-commits.sh` (use as template)
  - Hook configuration: `hooks/hooks.json`
  - Log directory: `~/.claude/logs/`

# Technical Approach

## Hook Script Implementation

**File:** `hooks/log-subagent-activity.sh`

**Input (via stdin JSON):**
```json
{
  "tool_name": "Task",
  "tool_input": {
    "description": "[code-developer] Implement fix",
    "subagent_type": "general-purpose",
    "prompt": "..."
  },
  "tool_response": "...",
  "session_id": "abc123"
}
```

**Output:**
- Log to `~/.claude/logs/subagent-activity.log`
- Format: `[timestamp] SESSION:{id} AGENT:{type} TASK:{description} STATUS:completed`

**Implementation Pattern:**
- Use `hooks/detect-protected-commits.sh` as reference
- JSON parsing with jq (fallback to sed if jq unavailable)
- Non-blocking (detection-only, always exit 0)
- Structured logging for parseability

## hooks.json Configuration

Add to `hooks/hooks.json`:

```json
{
  "PostToolUse": [
    {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/log-subagent-activity.sh",
          "timeout": 5
        }
      ]
    }
  ]
}
```

## Test Plan

1. Spawn any subagent (Explore, code-developer, tech-writer, etc.)
2. Verify log entry appears in `~/.claude/logs/subagent-activity.log`
3. Verify log format is correct and parseable
4. Verify hook doesn't block or slow down Task execution
5. Test with multiple sequential subagent invocations
6. Test with missing jq (fallback to sed parsing)

## Context from Investigation

The Explore agent found:
- PostToolUse hooks already exist for Bash tool
- Matcher accepts exact tool names like `"Task"`
- detect-protected-commits.sh is 200+ lines, uses jq for JSON parsing
- Non-blocking pattern: always exit 0, log violations separately

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

## [2025-12-11 12:00] - Creator: created
- Ticket created in queue/
- Requirements defined from handoff prompt
- Technical approach specified with PostToolUse hook pattern
- Test plan outlined
