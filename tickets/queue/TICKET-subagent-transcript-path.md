---
# Metadata
ticket_id: TICKET-subagent-transcript-path
session_id: subagent-transcript-path
sequence:
parent_ticket: null
title: Fix transcript_path detection for subagent contexts
cycle_type: development
status: open
created: 2025-12-11 00:15
worktree_path: null
---

# Requirements

## What Needs to Be Done

Fix `block-unreviewed-edits.sh` to correctly detect quality agent identity markers when running in subagent (Task tool) contexts.

**Root Cause:** Claude Code's PreToolUse hook interface passes `transcript_path: "/dev/null"` when hooks are invoked in subagent contexts, instead of the actual transcript path. This prevents the hook from detecting valid quality agent identity markers.

**Evidence:**
```
# Failed cases (subagent context):
[2025-12-10 08:55:43] WARNING: Transcript file not found: /dev/null
[2025-12-10 08:55:43] AUDIT: Blocked Write without quality agent

# Successful cases (main thread):
[2025-12-10 02:15:09] Quality agent detected: working as the plugin-engineer agent
[2025-12-10 02:15:09] ALLOWED: Quality agent context detected
```

## Acceptance Criteria

- [ ] Hook can detect quality agents when `transcript_path` is `/dev/null`
- [ ] Alternative transcript path discovery mechanism implemented
- [ ] Maintains security (no false positives)
- [ ] Debug logging shows transcript path resolution
- [ ] All 12 quality agents detected correctly in subagent context

# Context

## Why This Work Matters

**CRITICAL:** This bug completely defeats the quality cycle enforcement system. Quality agents (tech-writer, code-developer, etc.) are properly invoked with identity markers but cannot perform their work because:

1. Task tool spawns subagent with identity marker in prompt
2. Identity marker appears in transcript
3. Subagent invokes Edit/Write tool
4. PreToolUse hook fires with `transcript_path: "/dev/null"`
5. Hook cannot find identity marker (wrong file)
6. Hook blocks the operation
7. Quality agent fails despite correct invocation

**Impact:** All quality cycle work is blocked. Workarounds (heredoc, manual creation) violate the quality enforcement principle.

## Technical Analysis

### Current Detection Logic (lines 175-189)

```bash
local agent_pattern
agent_pattern=$(printf '%s' "${QUALITY_AGENTS}" | sed 's/,/|/g')

if grep -qE "working as the (${agent_pattern}) agent" "$transcript_path" 2>/dev/null; then
    # ALLOW
fi
```

### Proposed Fix Options

**Option A: Environment Variable Fallback**
```bash
# Try hook input first, then env var
local transcript="${transcript_path:-${CLAUDE_TRANSCRIPT_FILE:-}}"
if [[ "$transcript" == "/dev/null" || -z "$transcript" ]]; then
    transcript="${CLAUDE_TRANSCRIPT_FILE:-}"
fi
```

**Option B: Session Directory Discovery**
```bash
# Find transcript in Claude projects directory
local project_dir="${CLAUDE_PROJECT_DIR:-$HOME/.claude/projects}"
if [[ "$transcript_path" == "/dev/null" ]]; then
    transcript=$(find "$project_dir" -name "*.jsonl" -newer /tmp -print -quit 2>/dev/null)
fi
```

**Option C: Process Parent Transcript**
```bash
# Get transcript from parent Claude process
local parent_transcript=$(ps -p $PPID -o args= | grep -oP 'transcript=\K\S+')
```

### Recommended Approach

Option A (environment variable fallback) is safest:
- Relies on Claude Code's own env var if available
- Fails closed if no transcript found
- Minimal changes to hook logic

## References

- Related tickets: TICKET-quality-gate-001, TICKET-enforce-subagent-delegation-001
- Debug log: `/home/ddoyle/.claude/logs/hooks-debug.log`
- Hook file: `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-unreviewed-edits.sh`

# Creator Section

## Implementation Notes
[To be filled during implementation]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings
[To be filled by code-reviewer]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
[To be filled by code-tester]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-11 00:15] - Ticket Created
- Root cause identified: Claude Code passes /dev/null for subagent transcript_path
- Technical analysis completed
- Three fix options proposed
- Priority: CRITICAL (blocks all quality cycle work)
