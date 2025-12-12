# Handoff Prompt: Subagent Activity Visibility

Session Type: DEVELOPMENT

## Ticket Reference

**Ticket:** Create TICKET-subagent-visibility.md in workflow-guard/tickets/queue/
**Project:** workflow-guard
**Main Repo:** /home/ddoyle/.claude/plugins/workflow-guard

## Problem Statement

Users cannot distinguish when subagents are doing work vs the main thread. This creates confusion about:
- Who performed file reads/writes
- Whether quality cycle agents are being used
- Audit trail for work attribution

## Proposed Solution

Create a PostToolUse hook for the Task tool that logs subagent activity to a visible location.

## Technical Approach

### 1. New Hook Script: `hooks/log-subagent-activity.sh`

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

### 2. Register in hooks.json

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

### 3. Reference Implementation

Use `hooks/detect-protected-commits.sh` as template:
- JSON parsing with jq (fallback to sed)
- Non-blocking (detection-only)
- Structured logging

## Acceptance Criteria

- [ ] PostToolUse hook fires after Task tool completes
- [ ] Log file created at `~/.claude/logs/subagent-activity.log`
- [ ] Log entries include: timestamp, session_id, subagent_type, description
- [ ] Hook is non-blocking (exit 0 always)
- [ ] Hook registered in hooks.json under PostToolUse

## Quality Cycle

Recipe: R1 (code-developer → code-reviewer → code-tester)

## Instructions

1. Create ticket from template: `tickets/TEMPLATE.md`
2. Activate ticket: `./scripts/activate-ticket.sh tickets/queue/TICKET-subagent-visibility.md`
3. Implement hook script in worktree
4. Update hooks.json to register hook
5. Test by spawning a subagent and checking log
6. Complete quality cycle

## Test Plan

1. Spawn any subagent (Explore, code-developer, etc.)
2. Verify log entry appears in `~/.claude/logs/subagent-activity.log`
3. Verify format is correct and parseable
4. Verify hook doesn't block or slow down Task execution

## References

- Existing PostToolUse hook: `hooks/detect-protected-commits.sh` (template)
- hooks.json: `hooks/hooks.json`
- Log directory: `~/.claude/logs/`

## Context from Investigation

The Explore agent found:
- PostToolUse hooks already exist for Bash tool
- Matcher accepts exact tool names like `"Task"`
- detect-protected-commits.sh is 200+ lines, uses jq for JSON parsing
- Non-blocking pattern: always exit 0, log violations separately
