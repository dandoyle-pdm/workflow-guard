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

Seven PreToolUse hooks enforce workflow discipline and quality cycles:

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

#### block-mcp-git-commits

Blocks MCP git tools (`mcp__git__git_commit`, `mcp__git__git_add`) on protected branches.

**Behavior:**
- Detects MCP git commit/add operations
- Checks current branch against protected list
- Blocks with error message on protected branches
- Complements `block-main-commits` for comprehensive git protection
- MCP tools bypass the Bash tool, requiring dedicated hook matcher

**Why this hook exists:**

MCP git tools provide direct git operations that bypass the standard Bash tool entirely. Without this hook, branch protection could be circumvented by using MCP tools instead of Bash git commands.

#### confirm-code-edits

Requires user confirmation before modifying code files via Edit or Write tools.

**Behavior:**
- Detects Edit and Write operations on code files
- Prompts for confirmation before proceeding with edits
- Allows workflow metadata files without confirmation (tickets, handoffs)
- Allows test files without confirmation
- Provides audit trail of confirmed edits
- Configurable code file extensions via `CODE_FILE_EXTENSIONS` env var

**Default code extensions:**
`go`, `py`, `sh`, `js`, `ts`, `tsx`, `jsx`

**Exception files (always allowed):**
- Ticket files: Any file in `tickets/` directory
- Test files: Files matching patterns like `_test.go`, `*.test.js`, `*.spec.ts`

**Environment variables:**
- `CODE_FILE_EXTENSIONS` - Comma-separated list of extensions to protect (default: `go,py,sh,js,ts,tsx,jsx`)
- `SKIP_EDIT_CONFIRMATION` - Set to `true` to bypass confirmation (use with caution)

**Use case:**

Prevents unintended code modifications during investigation or read-only workflows. When Claude is exploring code to answer questions, this hook prevents accidental edits unless explicitly requested by the user.

#### block-unreviewed-edits

Enforces quality agent context for file modifications (Edit, Write, NotebookEdit).

**Behavior:**
- Blocks file modifications unless quality agent context detected
- Detects agent identity in transcript via pattern: `working as the {agent-name} agent`
- Allows workflow metadata: `tickets/**/*.md`, `**/HANDOFF*.md`
- Provides guidance on using qc-router to dispatch quality agents
- Audit logging for compliance tracking

**Exception files (always allowed):**
- Ticket files: Any markdown file in `tickets/` directory
- Handoff files: Any file matching `HANDOFF*.md`

**Quality agent detection:**
The hook reads the transcript JSONL file to detect if a quality agent from qc-router is active. When you dispatch a quality agent via the Task tool, the agent's identity marker appears in the transcript, allowing the hook to verify proper quality cycle context.

#### validate-ticket-naming

Enforces ticket naming conventions for files in the `tickets/` directory.

**Behavior:**
- Validates filename pattern: `TICKET-{session-id}-{sequence}.md`
- Validates directory uses session-id (not full ticket name)
- Exception: `tickets/queue/` only validates filename (no directory check)
- Blocks invalid names with detailed guidance
- Ensures consistency for automation workflows

**Naming Rules:**
- **session-id**: lowercase letters, numbers, hyphens (e.g., `quality-gate`, `activate-fix`)
- **sequence**: exactly 3 digits (e.g., `001`, `002`)

**Valid Examples:**
```
tickets/queue/TICKET-quality-gate-001.md           ✓
tickets/active/quality-gate/TICKET-quality-gate-001.md  ✓
tickets/completed/activate-fix/TICKET-activate-fix-001.md  ✓
```

**Invalid Examples:**
```
TICKET-Quality-Gate-001.md        ✗ (uppercase not allowed)
TICKET-quality_gate-001.md        ✗ (underscores not allowed)
tickets/active/TICKET-quality-gate-001/TICKET-quality-gate-001.md  ✗ (directory should be session-id)
```

**Why this matters:**

- Consistent naming enables automation (`activate-ticket.sh`, `complete-ticket.sh`)
- Session-id based directories allow multiple sequential tickets (001, 002, etc.)
- Lowercase-with-hyphens prevents case-sensitivity issues across platforms
- Automated workflows rely on these patterns to function correctly

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

### Quality Agents

Default quality agents (12 total across 4 quality cycles):
- Code: `code-developer`, `code-reviewer`, `code-tester`
- Plugin: `plugin-engineer`, `plugin-reviewer`, `plugin-tester`
- Prompt: `prompt-engineer`, `prompt-reviewer`, `prompt-tester`
- Documentation: `tech-writer`, `tech-editor`, `tech-publisher`

Override with environment variable (comma-separated):
```bash
export CLAUDE_QUALITY_AGENTS="code-developer,code-reviewer,code-tester,custom-agent"
```

### Code Edit Confirmation

The `confirm-code-edits` hook protects code files from unintended modifications.

**Configurable file extensions:**
```bash
export CODE_FILE_EXTENSIONS="go,py,sh,js,ts,tsx,jsx"  # default
```

**Bypass confirmation (use with caution):**
```bash
export SKIP_EDIT_CONFIRMATION=true
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

## Integration with qc-router

workflow-guard integrates with the [qc-router](~/.claude/plugins/qc-router/) sister plugin to enforce quality cycle requirements.

### Architecture

```
workflow-guard                        qc-router
├── hooks/                            ├── agents/
│   ├── block-main-commits.sh         │   ├── plugin-engineer/AGENT.md
│   ├── enforce-pr-workflow.sh        │   ├── plugin-reviewer/AGENT.md
│   ├── enforce-ticket-completion.sh  │   └── plugin-tester/AGENT.md
│   ├── block-mcp-git-commits.sh      │
│   ├── confirm-code-edits.sh         │
│   ├── validate-ticket-naming.sh     │
│   └── block-unreviewed-edits.sh     │
│       │                             │
│       │ reads transcript            │
│       │ detects agent identity      │
│       ▼                             │
│   ALLOW if quality agent found ─────┘
```

### Quality Agent Detection

When a quality agent is dispatched via Task tool, its AGENT.md identity appears in the subagent's transcript. workflow-guard hooks read this transcript to detect quality agent context.

**Identity pattern:** `working as the {agent-name} agent`

**Recognized agents:**
- `plugin-engineer` - Creator role, implements features
- `plugin-reviewer` - Critic role, audits code
- `plugin-tester` - Judge role, validates and approves

### Quality Transformer Requirement

The `block-unreviewed-edits.sh` hook enforces quality cycle for file modifications:

| Operation | Without Quality Agent | With Quality Agent |
|-----------|----------------------|-------------------|
| Edit file | BLOCKED | Allowed |
| Write file | BLOCKED | Allowed |
| NotebookEdit | BLOCKED | Allowed |
| Edit ticket | Allowed (exception) | Allowed |
| Edit handoff | Allowed (exception) | Allowed |

This ensures all code changes go through the quality cycle: Creator → Critic → Judge.

**How it works:**
1. Hook intercepts Edit/Write/NotebookEdit tool invocations
2. Checks if file is workflow metadata (tickets, handoffs) - if yes, ALLOW
3. Reads transcript JSONL file to detect quality agent identity marker
4. If quality agent detected (any of 12 recognized agents), ALLOW
5. Otherwise, BLOCK with guidance on using qc-router

## Declarative Hook Configuration

Hooks are configured declaratively in `hooks/hooks.json`. Claude Code loads this configuration at session start.

### hooks.json Structure

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/block-main-commits.sh",
          "timeout": 10
        },
        {
          "type": "command",
          "command": "hooks/enforce-pr-workflow.sh",
          "timeout": 10
        },
        {
          "type": "command",
          "command": "hooks/enforce-ticket-completion.sh",
          "timeout": 10
        }
      ]
    },
    {
      "matcher": "mcp__git__git_commit|mcp__git__git_add",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/block-mcp-git-commits.sh",
          "timeout": 10
        }
      ]
    },
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/confirm-code-edits.sh",
          "timeout": 10
        }
      ]
    },
    {
      "matcher": "Edit|Write|NotebookEdit",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/block-unreviewed-edits.sh",
          "timeout": 5
        }
      ]
    },
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/validate-ticket-naming.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

### Configuration Fields

| Field | Description |
|-------|-------------|
| `PreToolUse` | Event type - fires before tool execution |
| `matcher` | Regex pattern matching tool names |
| `type` | Hook type - `command` for shell scripts |
| `command` | Path to script (relative to plugin root) |
| `timeout` | Max execution time in seconds |

### Hook Input/Output Protocol

**Input:** JSON via stdin
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/directory",
  "session_id": "..."
}
```

**Output:** Exit code determines action
- `exit 0` - Allow operation
- `exit 2` - Block with message (stdout = guidance)

### Adding New Hooks

1. Create script in `hooks/` directory
2. Add entry to `hooks/hooks.json`
3. Restart Claude Code (hooks load at session start)

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

### Session-ID vs Ticket-ID Naming

The plugin distinguishes between **ticket-id** (full identifier) and **session-id** (extracted middle portion):

**ticket-id**: Full identifier like `TICKET-quality-gate-001`
**session-id**: Extracted middle portion like `quality-gate`

This distinction is important for automation:

| Resource | Uses | Example |
|----------|------|---------|
| Ticket filename | ticket-id | `TICKET-quality-gate-001.md` |
| Git branch | session-id | `ticket/quality-gate` |
| Worktree directory | session-id | `~/.novacloud/worktrees/workflow-guard/quality-gate` |
| Active/completed directories | session-id | `tickets/active/quality-gate/` |

**Why session-id for branches/worktrees?**

- Allows multiple sequential tickets to share the same branch (001, 002, 003)
- Shorter, cleaner branch names
- Consistent worktree location for a session regardless of ticket sequence

**Example workflow:**

```bash
# First ticket in session
tickets/queue/TICKET-quality-gate-001.md
  → tickets/active/quality-gate/TICKET-quality-gate-001.md
  → branch: ticket/quality-gate
  → worktree: ~/.novacloud/worktrees/workflow-guard/quality-gate

# Follow-up ticket in same session
tickets/queue/TICKET-quality-gate-002.md
  → tickets/active/quality-gate/TICKET-quality-gate-002.md
  → branch: ticket/quality-gate (same!)
  → worktree: ~/.novacloud/worktrees/workflow-guard/quality-gate (same!)
```

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
