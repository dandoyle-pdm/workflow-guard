---
# Metadata
ticket_id: TICKET-statusline-agent-001
session_id: statusline-agent
sequence: 001
parent_ticket: null
title: Dynamic status line showing worktree, branch, and agent
cycle_type: development
status: claimed
claimed_by: ddoyle
claimed_at: 2025-12-11 17:47
created: 2025-12-11 14:30
worktree_path: null
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
- [ ] Status line displays current worktree name
- [ ] Status line displays current git branch
- [ ] Status line displays active agent when in quality cycle
- [ ] Agent state is written by hooks (PreToolUse/PostToolUse for Task tool)
- [ ] Agent state clears when subagent completes
- [ ] Works with existing workflow-guard plugin hooks
- [ ] Graceful fallback when any component is unavailable

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
[What was built, decisions made, approach taken]

## Questions/Concerns
- Should we show nested agents (e.g., code-developer spawns Explore)?
- Should agent history be logged for debugging?
- Color coding for different agent types?

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

## [2025-12-11 14:30] - Coordinator
- Ticket created from discussion about dynamic status line
- Technical design included based on conversation
