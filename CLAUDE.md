# CLAUDE.md

## Project Identity

You are working in the **Workflow Guard** plugin - a Claude Code plugin that provides git branch protection, PR workflow enforcement, and session handoff commands for maintaining consistent development workflows.

**This is a Claude Code plugin.** Changes to hooks or commands require a Claude Code restart to take effect. The plugin is installed in `~/.claude/plugins/workflow-guard/`.

## Essential Context

**Directory Structure:**
```
~/.claude/plugins/workflow-guard/
├── .claude-plugin/plugin.json    # Plugin metadata
├── hooks/
│   ├── hooks.json                # Hook configuration
│   ├── block-main-commits.sh     # Prevents commits to protected branches
│   ├── enforce-pr-workflow.sh    # Blocks direct merges to protected branches
│   └── enforce-ticket-completion.sh  # Verifies ticket completion before PR
├── commands/
│   ├── handoff.md                # Auto-detect session type
│   ├── handoff-debug.md          # Debugging session handoffs
│   ├── handoff-development.md    # Feature development handoffs
│   ├── handoff-hotfix.md         # Emergency hotfix handoffs
│   └── handoff-investigate.md    # Investigation handoffs
├── tickets/                      # Standard ticket workflow
│   ├── queue/, active/, completed/
│   └── TEMPLATE.md
└── README.md                     # Full documentation
```

## Commands Reference

| Command | Description | Use Case |
|---------|-------------|----------|
| `/workflow-guard:handoff` | Auto-detect session type | When continuing work across sessions |
| `/workflow-guard:handoff-debug` | Generate debugging handoff | Root cause analysis and fix status |
| `/workflow-guard:handoff-development` | Generate feature handoff | Design decisions and progress tracking |
| `/workflow-guard:handoff-hotfix` | Generate emergency handoff | Impact assessment and quick fix status |
| `/workflow-guard:handoff-investigate` | Generate investigation handoff | Research findings and evidence collected |

All handoff commands auto-generate structured prompts with system state, tool usage patterns, and mental model.

## Hooks Reference

| Hook | Blocks | Purpose |
|------|--------|---------|
| `block-main-commits` | `git commit` on protected branches | Prevents accidental commits to main/master/production |
| `enforce-pr-workflow` | `git merge feature → protected` | Routes feature integration through PR workflow |
| `enforce-ticket-completion` | `gh pr create` without completed ticket | Ensures ticket in completed/ before PR |

**Protected Branches:** main, master, production (configurable via `CLAUDE_PROTECTED_BRANCHES` env var)

**Debug Logs:** `~/.claude/logs/hooks-debug.log`

## Development Rules

1. **Quality Cycles Required:**
   - R1 (code-developer → code-reviewer → code-tester) for hook changes
   - R2 (tech-writer → tech-editor → tech-publisher) for commands 100+ lines
   - R5 (single reviewer) for minor config changes

2. **Testing Requirements:**
   - All hook changes must be tested in a real git repo
   - Test both blocked and allowed scenarios
   - Verify debug logging captures attempts

3. **Restart Required:**
   - Any changes to hooks/ or commands/ require Claude Code restart
   - Plugin location is registered; contents are loaded fresh each session

4. **Documentation Coherency:**
   - Keep README.md, hooks, and commands synchronized
   - Document all configuration options
   - Update examples when behavior changes

## What NOT to Do

- Do NOT edit hooks without testing in real git environment
- Do NOT skip restart after changes (hooks won't update)
- Do NOT add silent fallbacks (fail fast on missing requirements)
- Do NOT duplicate handoff logic across commands (DRY principle)
- Do NOT bypass quality cycles for production changes

## Quick Reference

| Need | Location |
|------|----------|
| Full documentation | README.md |
| Hook implementations | hooks/*.sh |
| Handoff templates | commands/handoff*.md |
| Debug logs | ~/.claude/logs/hooks-debug.log |
| Configuration | plugin.json, hooks/hooks.json |
| Ticket workflow | tickets/ (queue → active → completed) |

**Installation Check:**
```bash
/plugin list  # Should show workflow-guard@local-plugins
```

**Debugging Hook Issues:**
```bash
tail -f ~/.claude/logs/hooks-debug.log
```
