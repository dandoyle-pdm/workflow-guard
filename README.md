# Workflow Guard

A Claude Code plugin that provides git branch protection, PR workflow enforcement, and session handoff commands for maintaining consistent development workflows.

## Features

- **Branch Protection**: Prevents accidental commits to protected branches (main, master, production)
- **PR Workflow Enforcement**: Blocks direct merges to protected branches, routing to proper PR workflow
- **Ticket Completion Verification**: Ensures tickets are marked complete before PR creation
- **Session Handoff Commands**: Generate comprehensive handoff prompts for seamless session continuation

## Installation

```bash
# Add local marketplace
/plugin marketplace add ~/.claude/plugins

# Install plugin
/plugin install workflow-guard@local-plugins
```

## What's Included

### Commands

The plugin provides five handoff commands that auto-generate session continuation prompts:

| Command | Description |
|---------|-------------|
| `/handoff` | Auto-detect session type and generate appropriate handoff prompt |
| `/handoff-debug` | Generate handoff for debugging sessions with root cause analysis and fix status |
| `/handoff-development` | Generate handoff for feature development with design decisions and progress tracking |
| `/handoff-hotfix` | Generate emergency hotfix handoff with impact assessment and quick fix status |
| `/handoff-investigate` | Generate investigation handoff with research findings and evidence collected |

Each handoff command automatically:
- Gathers system state (git status, containers, working directory)
- Extracts tool usage patterns from the session
- Captures mental model and insights
- Generates structured prompt for next Claude session

### Hooks

Three PreToolUse hooks intercept Bash commands to enforce workflow discipline:

#### block-main-commits

Blocks `git commit` commands when on protected branches (main, master, production).

**Behavior:**
- Detects any `git commit` variant (with flags, paths, etc.)
- Checks current branch against protected list
- Blocks with helpful error message showing correct worktree workflow
- Logs blocked attempts for audit

#### enforce-pr-workflow

Blocks direct `git merge` of feature branches into protected branches.

**Behavior:**
- Detects merge commands targeting protected branches
- Allows merging protected branches INTO feature branches (for updates)
- Blocks merging feature branches INTO protected branches
- Provides exact commands for correct PR-based workflow

**Example blocked:**
```bash
# On main branch
git merge feature/my-feature  # BLOCKED - use PR instead
```

**Example allowed:**
```bash
# On feature branch
git merge origin/main  # ALLOWED - updating feature branch
```

#### enforce-ticket-completion

Ensures ticket is in `tickets/completed/` before PR creation.

**Behavior:**
- Detects `gh pr create` commands
- Only applies when in a git worktree (not main repo)
- Verifies ticket exists in `tickets/completed/<branch>/`
- Blocks if ticket is still in `tickets/active/`
- Allows non-ticket work to proceed (no ticket found = warning only)

## Configuration

### Protected Branches

Default protected branches: `main`, `master`, `production`

Override with environment variable:
```bash
export CLAUDE_PROTECTED_BRANCHES="main production staging develop"
```

### Debug Logging

All hooks log to `~/.claude/logs/hooks-debug.log` for troubleshooting:
```bash
tail -f ~/.claude/logs/hooks-debug.log
```

## Workflow Overview

```
1. Create worktree from main
   git worktree add ~/workspace/worktrees/project/feature-branch -b feature-branch

2. Work in worktree (commits allowed)
   cd ~/workspace/worktrees/project/feature-branch
   # make changes
   git commit -m "..."

3. Complete ticket before PR
   ~/.claude/scripts/complete-ticket.sh

4. Create PR (ticket completion verified)
   gh pr create --base main
```

## License

MIT
