---
# Metadata
ticket_id: TICKET-statusline-agent-001
session_id: statusline-agent
sequence: 001
parent_ticket: null
title: Dynamic status line showing worktree, branch, and agent
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-11 17:47
created: 2025-12-11 14:30
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/statusline-agent
---

# Requirements

## What Needs to Be Done

Enhance Claude Code status line to display the "power tuple" of workflow context:
- **Worktree** - Which project/client workspace is active
- **Branch** - Current feature branch
- **Agent** - Which quality cycle agent is active (code-developer, tech-writer, etc.)

Example output:
```
[docs] feature/TICKET-001 | 🔧 code-developer
```

## Acceptance Criteria
- [x] Status line displays current worktree name
- [x] Status line displays current git branch
- [x] Status line displays active agent when in quality cycle
- [x] Agent state is written by hooks (PreToolUse/PostToolUse for Task tool)
- [x] Agent state clears when subagent completes
- [x] Works with existing workflow-guard plugin hooks
- [x] Graceful fallback when any component is unavailable

# Context

## Why This Work Matters

The workflow-guard plugin uses GitOps-based ticket activation with worktrees and quality cycles. Developers need visibility into:
1. Which worktree they're operating in (prevents wrong-context mistakes)
2. Which branch is active (confirms ticket context)
3. Which agent role is executing (code-developer vs code-reviewer vs code-tester)

This creates a dashboard-like experience showing "where am I and what role am I playing."

## References
- Related tickets: None
- Related PRs: None
- Related issues: None
- Documentation:
  - workflow-guard plugin hooks: `hooks/`
  - Claude Code status line configuration

## Technical Design

### Components

1. **State file**: `~/.claude/current-agent`
   - Written by hooks when Task tool invokes quality cycle agents
   - Cleared when subagent completes
   - Contains agent name (e.g., "code-developer")

2. **Hook modifications** (PreToolUse/PostToolUse for Task tool):
   ```bash
   # PreToolUse hook for Task tool
   # When subagent_type matches quality agent, write to state file

   # PostToolUse hook for Task tool
   # Clear state file when agent completes
   ```

3. **Status line script** (`~/.claude/statusline.sh`):
   ```bash
   #!/bin/bash
   WORKTREE=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
   BRANCH=$(git branch --show-current 2>/dev/null)
   AGENT=$(cat ~/.claude/current-agent 2>/dev/null)

   STATUS="[$WORKTREE] $BRANCH"
   [ -n "$AGENT" ] && STATUS="$STATUS | 🔧 $AGENT"
   echo "$STATUS"
   ```

### Agent Detection Logic

Match these subagent_type values from Task tool:
- `code-developer` → "code-developer"
- `code-reviewer` → "code-reviewer"
- `code-tester` → "code-tester"
- `tech-writer` → "tech-writer"
- `tech-editor` → "tech-editor"
- `tech-publisher` → "tech-publisher"
- `Explore` → "explorer"
- `Plan` → "planner"

# Creator Section

## Implementation Notes

Successfully implemented the dynamic status line feature with the following components:

### 1. Status Line Script (`~/.claude/statusline.sh`)
Enhanced the existing status line script to:
- Extract worktree name from git toplevel directory
- Display worktree in yellow brackets: `[worktree-name]`
- Read agent state from `~/.claude/current-agent`
- Display agent with appropriate icon and green color when active
- Format: `Model in [worktree] on branch | icon agent in directory`

### 2. Agent State Tracking Hooks

**PreToolUse Hook** (`hooks/track-agent-state.sh`):
- Intercepts Task tool invocations
- Extracts `subagent_type` parameter from JSON
- Checks if subagent is a quality cycle agent
- Writes agent name to `~/.claude/current-agent` if quality agent detected
- Quality agents: code-developer, code-reviewer, code-tester, plugin-engineer, plugin-reviewer, plugin-tester, prompt-engineer, prompt-reviewer, prompt-tester, tech-writer, tech-editor, tech-publisher, Explore, Plan

**PostToolUse Hook** (`hooks/clear-agent-state.sh`):
- Intercepts Task tool completion
- Removes `~/.claude/current-agent` file
- Ensures agent display clears when subagent finishes

### 3. Hook Registration
Updated `hooks/hooks.json` to register:
- PreToolUse matcher for "Task" → `track-agent-state.sh`
- PostToolUse matcher for "Task" → `clear-agent-state.sh`

### 4. Agent Icon Mapping
Implemented icon mapping for visual distinction:
- 🔧 Code agents (code-developer, code-reviewer, code-tester)
- 🔌 Plugin agents (plugin-engineer, plugin-reviewer, plugin-tester)
- 💬 Prompt agents (prompt-engineer, prompt-reviewer, prompt-tester)
- 📝 Documentation agents (tech-writer, tech-editor, tech-publisher)
- 🔍 Explore agent
- 📋 Plan agent
- ⚙️ Generic fallback for other agents

### Design Decisions

1. **State file location**: Used `~/.claude/current-agent` for simplicity and global accessibility
2. **Agent tracking**: Only track quality cycle agents, ignore general-purpose subagents
3. **Color scheme**: Yellow for worktree, magenta for branch, green for agent
4. **Error handling**: Graceful fallbacks for missing git repo, missing state file, etc.
5. **Hook integration**: Minimal changes to existing hooks.json, added targeted Task matchers

### Testing Results

All tests passed:
- Status line displays correctly with and without agent state
- Different agent types display with correct icons
- State file created on Task PreToolUse for quality agents
- State file cleared on Task PostToolUse
- Non-quality agents don't create state file
- Graceful handling of missing worktree/branch info

## Questions/Concerns
- ~~Should we show nested agents (e.g., code-developer spawns Explore)?~~ **Decision**: Only show top-level agent, nested agents would be confusing
- ~~Should agent history be logged for debugging?~~ **Decision**: Debug logging already handled by hooks-debug.log
- ~~Color coding for different agent types?~~ **Decision**: Implemented icon mapping instead, clearer visual distinction

## Changes Made

**File changes**:
- Modified: `~/.claude/statusline.sh` - Enhanced with worktree and agent display
- Created: `hooks/track-agent-state.sh` - PreToolUse hook for Task tool
- Created: `hooks/clear-agent-state.sh` - PostToolUse hook for Task tool
- Modified: `hooks/hooks.json` - Added Task tool matchers

**Commits**:
- `45bfa77` - feat: add agent state tracking hooks for Task tool

**Status Update**: 2025-12-11 18:15 - Implementation complete, ready for `critic_review`

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

## [2025-12-11 14:30] - Coordinator
- Ticket created from discussion about dynamic status line
- Technical design included based on conversation

## [2025-12-11 17:47] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/statusline-agent
- Branch: ticket/statusline-agent
