# Workflow Guard Plugin

Workflow Guard plugin for Claude Code - provides git branch protection, PR workflow enforcement, ticket completion gates, and session handoff commands.

## Overview

This plugin provides:

- **5 Handoff Commands**: Auto-generate session continuation prompts
- **Branch Protection Hooks**: Block direct commits to protected branches
- **PR Workflow Enforcement**: Route users to proper PR-based workflows
- **Ticket Completion Gates**: Ensure tickets are completed before PR creation

## Installation

1. Copy this plugin directory to `~/.claude/plugins/workflow-guard/`
2. Enable the plugin in Claude Code settings
3. Manually copy hook scripts (see Manual Steps below)

## Components

### Commands

Located in `./commands/`:

| Command | Purpose |
|---------|---------|
| `/handoff` | Auto-detect session type and generate handoff prompt |
| `/handoff-debug` | Generate debugging session handoff |
| `/handoff-development` | Generate development session handoff |
| `/handoff-hotfix` | Generate emergency hotfix handoff |
| `/handoff-investigate` | Generate investigation/research handoff |

### Hooks

Located in `./hooks/`:

- `hooks.json` - Hook configuration
- `block-main-commits.sh` - Blocks git commit on protected branches (main, master, production)
- `enforce-pr-workflow.sh` - Blocks direct merges to protected branches
- `enforce-ticket-completion.sh` - Blocks PR creation if ticket not in completed/

## Hook Behaviors

### block-main-commits.sh

Intercepts `git commit` commands and blocks when:
- Current branch is protected (main, master, production)
- Configurable via `CLAUDE_PROTECTED_BRANCHES` environment variable

Provides guidance to use worktree workflow instead.

### enforce-pr-workflow.sh

Intercepts `git merge` commands and blocks when:
- On a protected branch
- Attempting to merge a feature branch directly

Allows merging main INTO feature branches (the correct pattern).

### enforce-ticket-completion.sh

Intercepts `gh pr create` commands and blocks when:
- In a worktree (not main repo)
- Ticket for the branch is still in `tickets/active/`

Requires ticket to be in `tickets/completed/` before PR creation.

## Handoff Commands

Each handoff command:

1. Analyzes the current session
2. Extracts context from tool usage (Read, Edit, Bash, etc.)
3. Captures mental model and understanding
4. Generates a structured handoff prompt

### Handoff Types

- **DEBUG**: Bug investigation, root cause analysis, fix status
- **DEVELOPMENT**: Feature implementation, design decisions, progress tracking
- **HOTFIX**: Emergency response, quick fix status, service monitoring
- **INVESTIGATE**: Research questions, findings, evidence collection

## Manual Steps Required

Due to hook protection, shell scripts must be copied manually:

```bash
# Copy workflow-guard hook scripts
cp ~/.claude/hooks/block-main-commits.sh ~/.claude/plugins/workflow-guard/hooks/
cp ~/.claude/hooks/enforce-pr-workflow.sh ~/.claude/plugins/workflow-guard/hooks/
cp ~/.claude/hooks/enforce-ticket-completion.sh ~/.claude/plugins/workflow-guard/hooks/

# Make scripts executable
chmod +x ~/.claude/plugins/workflow-guard/hooks/*.sh
```

## Configuration

The `hooks.json` file configures:

- **PreToolUse (Bash)**: Runs all three workflow guard hooks

Hooks use `${CLAUDE_PLUGIN_ROOT}` to reference script paths relative to the plugin root.

### Environment Variables

- `CLAUDE_PROTECTED_BRANCHES`: Space-separated list of protected branch names (default: "main production master")

## Author

Dan Doyle

## Version

1.0.0
