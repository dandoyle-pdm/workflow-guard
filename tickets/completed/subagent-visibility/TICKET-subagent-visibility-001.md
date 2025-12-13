---
# Metadata
ticket_id: TICKET-subagent-visibility-001
session_id: subagent-visibility
sequence: 001
parent_ticket: null
title: Add PostToolUse hook for subagent activity visibility
cycle_type: development
status: completed
claimed_by: ddoyle
claimed_at: 2025-12-11 22:34
created: 2025-12-11 12:00
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/subagent-visibility
---

# Requirements

## What Needs to Be Done

Create a PostToolUse hook that logs subagent activity to provide visibility into when subagents are performing work versus the main thread. This improves audit trails and helps users understand work attribution.

**Deliverables:**
1. New hook script: `hooks/log-subagent-activity.sh`
2. Register hook in `hooks/hooks.json` under PostToolUse
3. Hook should log Task tool invocations to `~/.claude/logs/subagent-activity.log`

## Acceptance Criteria
- [x] PostToolUse hook fires after Task tool completes
- [x] Log file created at `~/.claude/logs/subagent-activity.log`
- [x] Log entries include: timestamp, session_id, subagent_type, description
- [x] Hook is non-blocking (exit 0 always)
- [x] Hook registered in hooks.json under PostToolUse
- [x] Hook doesn't block or slow down Task execution

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
- Created `hooks/log-subagent-activity.sh` (69 lines) following `clear-agent-state.sh` pattern
- Uses jq with sed fallback for JSON parsing
- Non-blocking (always exit 0)
- Logs to `~/.claude/logs/subagent-activity.log`
- Format: `[timestamp] SESSION:{id} AGENT:{type} TASK:{description} STATUS:completed`

## Questions/Concerns
None - straightforward implementation following established patterns

## Changes Made
- File changes:
  - `hooks/log-subagent-activity.sh` - New PostToolUse hook script
  - `hooks/hooks.json` - Added hook registration to PostToolUse Task matcher
- Commits:
  - `2277067` - feat: add subagent activity logging hook

**Status Update**: 2025-12-12 00:20 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None found

### HIGH Issues
None found

### MEDIUM Issues
None found

## Approval Decision
APPROVED

## Rationale
- All acceptance criteria met
- Security best practices followed (printf, proper quoting, no command injection)
- Consistent with established codebase patterns (`clear-agent-state.sh`, `detect-protected-commits.sh`)
- Functional testing confirms correct behavior
- No issues found during review

**Status Update**: 2025-12-12 00:22 - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Test 1 (Hook Registration): PASS
- Test 2 (Log File Creation): PASS
- Test 3 (Log Format Validation): PASS
- Test 4 (Non-Blocking Behavior): PASS
- Test 5 (Multiple Sequential Invocations): PASS
- Test 6 (jq Fallback): PASS
- Shellcheck: PASS - No issues detected
- Script Permissions: PASS - Executable (755)

## Quality Gate Decision
APPROVE

## Next Steps
- Create PR for merge to main
- After merge, restart Claude Code to load new hook
- Verify logging works in live session

**Status Update**: 2025-12-12 00:24 - Changed status to `approved`

# Changelog

## [2025-12-11 12:00] - Creator: created
- Ticket created in queue/
- Requirements defined from handoff prompt
- Technical approach specified with PostToolUse hook pattern
- Test plan outlined

## [2025-12-11 22:34] - Creator: activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/subagent-visibility
- Branch: ticket/subagent-visibility

## [2025-12-12 00:20] - Creator: implemented
- Created `hooks/log-subagent-activity.sh`
- Registered hook in `hooks/hooks.json`
- Commit: 2277067

## [2025-12-12 00:22] - Critic: approved
- All security checks passed
- Code follows established patterns
- No issues found

## [2025-12-12 00:24] - Expediter: approved
- All 6 tests passed
- Ready for PR and merge

## [2025-12-13 09:22] - Creator: completed
- PR #24 merged
- Ticket moved to completed/
- Branch deleted
- Worktree removed
