# DEVELOPER.md

Technical documentation for workflow-guard Claude Code plugin maintainers.

## Architecture Overview

The workflow-guard plugin provides three core capabilities:

1. **Branch Protection** - Blocks direct commits to protected branches (main, master, production)
2. **PR Workflow Enforcement** - Blocks direct merges to protected branches, requires PR workflow
3. **Ticket Lifecycle Integration** - Verifies ticket completion before PR creation

Implementation uses Claude Code's hook system to intercept commands before execution.

```
workflow-guard/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   ├── hooks.json            # Hook configuration (PreToolUse matcher: Bash)
│   ├── block-main-commits.sh
│   ├── enforce-pr-workflow.sh
│   └── enforce-ticket-completion.sh
├── commands/                 # Slash commands (handoff prompts)
│   ├── handoff.md
│   ├── handoff-debug.md
│   ├── handoff-development.md
│   ├── handoff-hotfix.md
│   └── handoff-investigate.md
├── README.md                 # User documentation
└── DEVELOPER.md              # This file
```

## Hook System

### Hook Lifecycle

1. Claude receives user request to use Bash tool
2. Before tool execution, PreToolUse hooks fire
3. Each hook receives JSON with `tool_name`, `tool_input`, `cwd`, `session_id`
4. Hook exits with code: `0` (allow), `2` (block with stderr message)
5. If any hook exits `2`, tool execution is blocked

### JSON Input Format

Hooks receive this structure via stdin:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m \"message\"",
    "description": "Commit changes"
  },
  "cwd": "/home/user/project",
  "session_id": "abc123"
}
```

### Exit Code Semantics

- `exit 0` - Allow tool execution
- `exit 2` - Block with error message (printed to stderr)
- Any other exit - Treated as hook failure, tool proceeds

### Hook Development

All hooks follow these patterns:

**1. Security Hardening**
- Use `printf` instead of `echo` to prevent command injection
- Use `jq` with `sed` fallback for JSON parsing
- Validate all inputs before use
- No eval of user-controlled data

**2. Helper Functions**
```bash
is_protected_branch() {
    # Checks if branch name matches CLAUDE_PROTECTED_BRANCHES
    # Default: "main production master"
    # Override: export CLAUDE_PROTECTED_BRANCHES="main prod"
}

get_current_branch() {
    # Returns current branch via git branch --show-current
    # Handles non-git directories gracefully
}
```

**3. Debug Logging**
```bash
debug_log() {
    printf '[%s] [hook-name] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
        >> "${CLAUDE_HOME}/logs/hooks-debug.log" 2>/dev/null || true
}
```

All hooks log to `~/.claude/logs/hooks-debug.log` for troubleshooting.

### Hook-Specific Logic

**block-main-commits.sh**
- Pattern: Detects `git commit` commands via regex
- Check: Compares current branch against protected list
- Block: If on protected branch, exit 2 with worktree workflow guide

**enforce-pr-workflow.sh**
- Pattern: Detects `git merge` commands, parses merge target
- Check: If on protected branch AND merging feature branch
- Allow: Feature branch merging protected branch (sync workflow)
- Block: Protected branch merging feature (bypasses PR)

**enforce-ticket-completion.sh**
- Pattern: Detects `gh pr create` commands
- Check: Verifies `tickets/completed/{branch}/` contains ticket
- Block: If ticket still in `tickets/active/` or `tickets/queue/`
- Skip: Non-worktree environments, protected branches

## Command Development

Commands are markdown files with YAML frontmatter.

### Frontmatter Format

```yaml
---
description: Auto-generate session continuation handoff prompt
---
```

The `description` field is **required** - it appears in Claude's command list.

### File Naming

Commands map to slash commands via filename:
- `handoff.md` → `/workflow-guard:handoff`
- `handoff-debug.md` → `/workflow-guard:handoff-debug`

### Prompt Template Patterns

Commands are prompt templates that Claude expands inline. Best practices:

**1. Clear Purpose Statement**
```markdown
Analyze the current session and automatically generate a comprehensive handoff prompt...
```

**2. Structured Sections**
```markdown
## Session Analysis
## Auto-Detection
## Mental Model Transfer
## Generate Complete Handoff
```

**3. Actionable Instructions**
- Use imperatives: "Extract", "Analyze", "Generate"
- Provide specific tool usage: "`pwd`, `git status`, `docker ps`"
- Define success criteria: "Show complete prompt in markdown code block"

**4. Context for Next Session**
Include methodology references (Ultrathink, Quality Chains, Ticket Workflow) so next Claude understands the environment.

## Configuration

### Environment Variables

**CLAUDE_PROTECTED_BRANCHES**
```bash
export CLAUDE_PROTECTED_BRANCHES="main production"
```
Space-separated list of branches to protect. Default: `main production master`

**Debug Logging**
Enable verbose logging:
```bash
tail -f ~/.claude/logs/hooks-debug.log
```

## Testing Guide

### Manual Testing

**Requirement**: Plugin restart needed after hook changes.
```bash
# 1. Modify hook
vim hooks/block-main-commits.sh

# 2. Restart Claude Code
# (Close and reopen, or use restart command)

# 3. Test
cd /tmp/test-repo
git checkout main
# In Claude: "Commit these changes"
# Expected: Block with error message
```

### Test Matrix

| Scenario | Expected Behavior |
|----------|-------------------|
| `git commit` on main | Blocked, show worktree workflow |
| `git commit` on feature | Allowed |
| `git merge feature` on main | Blocked, show PR workflow |
| `git merge main` on feature | Allowed (sync workflow) |
| `gh pr create` with ticket in active/ | Blocked, show completion script |
| `gh pr create` with ticket in completed/ | Allowed |

### Hook Testing Without Claude

Test hooks directly:
```bash
cd ~/.claude/plugins/workflow-guard/hooks

echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"test\""},"cwd":"/path/to/repo"}' \
  | ./block-main-commits.sh

# Check exit code
echo $?  # 0=allow, 2=block
```

## Troubleshooting

### Hook Not Firing

**Symptoms**: Direct commits succeed on main
**Causes**:
1. Plugin not loaded - check `~/.claude/plugins/` directory
2. Hook disabled in config
3. Matcher incorrect (must be "Bash")

**Fix**:
```bash
# Verify plugin loaded
ls -la ~/.claude/plugins/workflow-guard

# Check hooks.json matcher
cat hooks/hooks.json | grep matcher
```

### Hook Always Blocking

**Symptoms**: Even feature branch commits blocked
**Causes**:
1. `get_current_branch()` returning wrong branch
2. `CLAUDE_PROTECTED_BRANCHES` too broad

**Debug**:
```bash
tail -f ~/.claude/logs/hooks-debug.log
# Watch for "Current branch: X" lines
```

### JSON Parsing Failure

**Symptoms**: Hooks exit silently, tool proceeds
**Causes**:
1. Malformed JSON input
2. Missing jq, sed fallback failing

**Fix**:
```bash
# Test both parsers
command -v jq && echo "jq available" || echo "jq missing"

# Check debug log for parse errors
grep "ERROR: Failed to parse" ~/.claude/logs/hooks-debug.log
```

## Contribution Workflow

This plugin follows quality chains:

**Plugin Recipe**: `plugin-engineer` → `plugin-reviewer` → `plugin-tester`

1. Create ticket in project's `tickets/queue/`
2. Use Task tool with `subagent_type: "plugin-engineer"`
3. Agent implements changes, commits
4. Plugin-reviewer validates
5. Plugin-tester verifies hook behavior

See `qc-router/recipes/plugin.md` for full specification.

## Dependencies

**Required**:
- Bash 4.0+
- git (CLI)
- gh (GitHub CLI) - for ticket enforcement hook

**Optional**:
- jq - JSON parsing (sed fallback available)

## Security Considerations

**Command Injection Prevention**
- Never use `echo` with user input (use `printf`)
- Never use `eval` with parsed JSON fields
- Always quote variables: `"${var}"`

**Path Validation**
```bash
# Safe
git -C "${cwd}" status

# Unsafe
cd "${cwd}" && git status  # User controls cwd
```

**Input Sanitization**
All JSON fields are validated before use. Empty fields cause early exit (allow operation).

## License

MIT - See LICENSE file
