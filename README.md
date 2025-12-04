# Workflow Guard

A Claude Code plugin that provides git branch protection, PR workflow enforcement, and session handoff commands for maintaining consistent development workflows.

## Features

- **Branch Protection**: Prevents accidental commits to protected branches (main, master, production)
- **PR Workflow Enforcement**: Blocks direct merges to protected branches, routing to proper PR workflow
- **Ticket Completion Verification**: Ensures tickets are marked complete before PR creation
- **Session Handoff Commands**: Generate comprehensive handoff prompts for seamless session continuation

## Installation

```bash
# Add local marketplace (first time only)
/plugin marketplace add ~/.claude/plugins

# Install plugin
/plugin install workflow-guard@local-plugins
```

**Restart Claude Code after installation to load the plugin.**

### Updating the Plugin

Content changes (hooks, commands) only require a **restart** - no reinstall needed. The plugin installation registers the plugin location; contents are loaded fresh each session.

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

### Worktree Location

Default worktree base: `~/.novacloud/worktrees`

Override with environment variable:
```bash
export WORKTREE_BASE="~/my-worktrees"
```

Worktrees are created at `$WORKTREE_BASE/{project}/{ticket-id}`.

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

### Diagnostic Hook Data Logging

For hook development and debugging, you can enable comprehensive hook data logging to understand what data is available in different contexts.

**Enable diagnostic logging:**
```bash
export CLAUDE_HOOK_DIAGNOSTICS=true
```

**Log location:**
```
~/.claude/logs/hook-diagnostics.jsonl
```

The diagnostic logger captures the complete JSON payload sent to PreToolUse hooks for all tools (Bash, Edit, Write, MCP tools). This helps developers understand:
- What fields are available for each tool type
- How tool_input differs between tool types
- Additional context provided by Claude Code (session_id, cwd, etc.)

**View logs:**
```bash
# View all logged hook data
cat ~/.claude/logs/hook-diagnostics.jsonl

# Pretty-print recent entries
tail -5 ~/.claude/logs/hook-diagnostics.jsonl | jq '.'

# Filter by tool type
jq 'select(.data.tool_name == "Bash")' ~/.claude/logs/hook-diagnostics.jsonl

# Extract just tool names to see what's being captured
jq -r '.data.tool_name' ~/.claude/logs/hook-diagnostics.jsonl | sort | uniq -c
```

**Expected data structure:**

The hook receives a JSON object with these common fields:
```json
{
  "tool_name": "Bash|Edit|Write|mcp__*",
  "tool_input": { /* tool-specific parameters */ },
  "session_id": "unique-session-id",
  "cwd": "/current/working/directory"
}
```

For MCP tools, additional fields may include:
```json
{
  "mcp_server": "server-name"
}
```

**Example tool_input by type:**

*Bash tool:*
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status",
    "description": "Check repository status"
  }
}
```

*Edit tool:*
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file",
    "old_string": "original text",
    "new_string": "modified text"
  }
}
```

*MCP git tool:*
```json
{
  "tool_name": "mcp__git__git_commit",
  "tool_input": {
    "repo_path": "/path/to/repo",
    "message": "commit message"
  },
  "mcp_server": "git"
}
```

**Important notes:**
- Diagnostic logging is **disabled by default** for performance
- The diagnostic hook **never blocks operations** (always exits 0)
- Logs use JSON Lines format (one JSON object per line) for easy parsing
- Clear logs periodically as they can grow large with extensive tool use

## Ticket Activation

The plugin provides GitOps-style locking for ticket activation to prevent duplicate work.

### How It Works

1. **Claim Phase**: Ticket moves from `queue/` to `active/` on main branch
2. **Push to Main**: Atomic lock - if push fails, another developer claimed it first
3. **Worktree Phase**: Feature branch and worktree created for isolated development

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/activate-ticket.sh` | Activate a ticket with GitOps locking |
| `scripts/complete-ticket.sh` | Mark ticket complete and prepare for PR |
| `scripts/cleanup-merged-ticket.sh` | Remove worktree and branches after PR merge |

### Script Usage

#### activate-ticket.sh
```bash
# Activate a ticket from the queue
scripts/activate-ticket.sh tickets/queue/TICKET-xxx-001.md [project-name]
```

Creates a worktree at `$WORKTREE_BASE/{project}/{ticket-id}` and moves the ticket to `tickets/active/`.

#### complete-ticket.sh
```bash
# In worktree - auto-detect ticket
cd $WORKTREE_BASE/project/TICKET-xxx-001
scripts/complete-ticket.sh

# Explicit ticket path
scripts/complete-ticket.sh tickets/active/TICKET-xxx-001/TICKET-xxx-001.md

# Skip push (local only)
scripts/complete-ticket.sh --no-push
```

Moves ticket from `tickets/active/` to `tickets/completed/`, updates status to approved, and commits the change.

#### cleanup-merged-ticket.sh
```bash
# After PR is merged, cleanup worktree and branches
scripts/cleanup-merged-ticket.sh ticket/TICKET-xxx-001
```

**Security:** Requires PR to be in MERGED state. Protected branches (main, master, production) are blocked.

### Why Main Commits Are Allowed for Tickets

The `block-main-commits.sh` hook has a surgical exception for ticket lifecycle files:
- Moving tickets between `queue/`, `active/`, `completed/`, `archive/` is allowed
- This is workflow metadata, not code
- Code changes still require feature branch + PR

### Ticket Directories

| Directory | Purpose |
|-----------|---------|
| `tickets/queue/` | Tickets waiting to be claimed |
| `tickets/active/{branch}/` | Tickets being actively worked |
| `tickets/completed/{branch}/` | Tickets ready for PR |
| `tickets/archive/` | Obsolete/superseded tickets |

## Workflow Overview

```
1. Activate ticket (creates worktree automatically)
   scripts/activate-ticket.sh tickets/queue/TICKET-xxx-001.md

2. Work in worktree (commits allowed)
   cd $WORKTREE_BASE/project/TICKET-xxx-001
   # make changes
   git commit -m "..."

3. Complete ticket (moves to completed/)
   scripts/complete-ticket.sh

4. Create PR (ticket completion verified by hook)
   gh pr create --base main

5. After PR merge, cleanup
   scripts/cleanup-merged-ticket.sh ticket/TICKET-xxx-001
```

## License

MIT
