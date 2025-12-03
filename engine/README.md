# Workflow Guard Declarative Hook Engine

A fast, declarative rule engine for Claude Code hooks written in Go.

## Overview

The declarative hook engine provides a single, unified dispatcher that evaluates YAML-defined rules against Claude Code tool events. This replaces scattered bash scripts with a composable, inspectable, and testable architecture.

**Key Benefits:**
- **Fast startup**: ~1ms vs ~100ms for Python/bash
- **Single binary**: No runtime dependencies
- **Declarative**: Rules are YAML, not code
- **Composable**: Reusable conditions and actions
- **Fail-safe**: Errors don't break Claude Code
- **Inspectable**: CLI tools for debugging and testing

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code                        │
└─────────────────┬───────────────────────────────────┘
                  │ Hook Event (JSON via stdin)
                  ▼
┌─────────────────────────────────────────────────────┐
│              Dispatcher Binary                       │
│  ┌───────────────────────────────────────────────┐  │
│  │ 1. Load YAML Config (conditions, actions,     │  │
│  │    rules from multiple paths)                 │  │
│  │ 2. Parse Hook Event                           │  │
│  │ 3. Match Rules by Trigger (event + tool)      │  │
│  │ 4. Evaluate Conditions (regex, glob, etc)     │  │
│  │ 5. Execute Actions (decision, log, chain)     │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────┬───────────────────────────────────┘
                  │ Response
                  ▼
┌─────────────────────────────────────────────────────┐
│  Exit 0: Continue normally                           │
│  Exit 2 + JSON: Block/Ask with message              │
│    {"permissionDecision": "deny", "message": "..."}  │
└─────────────────────────────────────────────────────┘
```

## Quick Start

### Building

```bash
cd engine
make build
```

This creates:
- `bin/dispatcher` - Hook dispatcher binary
- `bin/hookctl` - CLI tool for management and testing

### Installation

```bash
make install
```

Installs binaries to `~/.local/bin/`

### Configuration

Place YAML files in one of these locations (later wins):
1. `~/.claude-hooks/` - Global config (git-synced)
2. `~/.claude/` - User-level
3. `$CLAUDE_PROJECT_DIR/.claude/` - Project-level

Required files:
- `conditions.yaml` - Reusable condition definitions
- `actions.yaml` - Reusable action definitions
- `rules.yaml` - Rule definitions

See the scaffold files in this directory for examples.

### Testing

```bash
# List all loaded rules
./bin/hookctl list

# Test against a sample event
./bin/hookctl test test-event.json

# Show config sources
./bin/hookctl config show

# Validate configuration
./bin/hookctl config validate
```

## Configuration Reference

### Conditions

Conditions determine when a rule matches. Types:

#### Field-Based Conditions

**regex**: Match field against regex pattern
```yaml
is-output-redirect:
  type: regex
  field: tool_input.command
  pattern: '>\s*[^>|&]'
  flags: [ignorecase]  # optional
```

**glob**: Match field against glob pattern
```yaml
is-env-file:
  type: glob
  field: tool_input.file_path
  pattern: "**/.env*"
```

**equals**: Compare field to value
```yaml
is-bash-tool:
  type: equals
  field: tool_name
  value: Bash
  operator: equals  # equals, startswith, endswith, contains
```

**exists**: Check if field exists
```yaml
has-file-path:
  type: exists
  field: tool_input.file_path
```

#### Compound Conditions

**all**: All conditions must match (AND)
```yaml
bash-file-write:
  type: compound
  all:
    - ref: is-bash-tool
    - ref: is-output-redirect
```

**any**: Any condition matches (OR)
```yaml
is-write-tool:
  type: compound
  any:
    - type: equals
      field: tool_name
      value: Edit
    - type: equals
      field: tool_name
      value: Write
```

**not**: Negates condition
```yaml
not-test-file:
  type: compound
  not:
    type: glob
    field: tool_input.file_path
    pattern: "**/test/**"
```

#### Condition References

```yaml
conditions:
  is-destructive-rm:
    type: regex
    field: tool_input.command
    pattern: 'rm\s+.*-[rf]'

rules:
  - id: block-rm
    conditions:
      ref: is-destructive-rm  # Reference by name
```

### Actions

Actions determine what happens when a rule matches.

#### Decision Actions

**deny**: Block the operation
```yaml
block:
  type: decision
  decision: deny
  message: "{{message}}"
```

**allow**: Allow without prompting
```yaml
allow:
  type: decision
  decision: allow
```

**ask**: Prompt user for confirmation
```yaml
require-confirmation:
  type: decision
  decision: ask
  message: "Are you sure?"
```

#### Log Actions

```yaml
log-to-file:
  type: log
  params:
    log_file: "~/.claude/logs/hooks.jsonl"
```

#### Chain Actions

Run multiple actions in sequence. First terminal action wins.

```yaml
block-and-log:
  type: chain
  actions:
    - ref: log-blocked
    - ref: block
```

#### Conditional Actions

```yaml
block-unless-test:
  type: conditional
  condition:
    type: glob
    field: tool_input.file_path
    pattern: "**/test/**"
  then:
    ref: allow
  else:
    ref: block
```

#### Action References

```yaml
actions:
  block:
    type: decision
    decision: deny
    message: "{{message}}"

rules:
  - id: my-rule
    actions:
      - ref: block
        params:
          message: "Custom message here"
```

### Rules

Rules combine triggers, conditions, and actions.

```yaml
rules:
  - id: block-bash-redirects
    name: Block Bash File Redirects
    description: Prevents file writes via shell redirection
    enabled: true
    priority: 100  # Higher priority evaluated first
    tags: [security, bash]

    trigger:
      event: PreToolUse  # PreToolUse, PostToolUse, Stop, etc.
      matcher: Bash      # Regex for tool_name

    conditions:
      ref: is-output-redirect

    actions:
      - ref: block-and-log
        params:
          message: |
            File modification blocked.
            Use Edit tool instead.
```

### Template Rendering

Actions support `{{variable}}` templates. Context includes:
- `{{tool_name}}` - Tool being used
- `{{session_id}}` - Session ID
- `{{command}}` - From `tool_input.command`
- `{{file_path}}` - From `tool_input.file_path`
- Any other `tool_input` fields
- Any `params` values

Multi-pass rendering supports nested templates.

## CLI Commands

### hookctl list
List all active rules with priority, tags, and trigger info.

```bash
./bin/hookctl list
```

### hookctl test
Test rule matching against a sample event.

```bash
./bin/hookctl test event.json
```

Event JSON format:
```json
{
  "hook_type": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "echo hello > test.txt"
  },
  "session_id": "test-123"
}
```

### hookctl config show
Show configuration sources and merged stats.

```bash
./bin/hookctl config show
```

### hookctl config validate
Validate configuration files.

```bash
./bin/hookctl config validate
```

## Integration with Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "/path/to/workflow-guard/engine/bin/dispatcher"
      }]
    }]
  }
}
```

**Note**: After adding hooks or updating configuration, restart Claude Code for changes to take effect.

## Exit Codes

- `0` - Continue normally (no blocking action)
- `2` - Block operation (with JSON output)

## Fail-Safe Design

The engine is designed to fail-safe:
- Configuration errors → exit 0 (continue normally)
- Parse errors → exit 0 (continue normally)
- Panic recovery → exit 0 (continue normally)

This ensures that hook engine issues never break Claude Code's operation.

## Performance

- Startup time: ~1ms
- Config loading: Cached in-process
- Rule evaluation: Efficient regex/glob matching
- Memory footprint: ~10MB resident

## Development

### Project Structure

```
engine/
├── cmd/
│   ├── dispatcher/    # Hook dispatcher entry point
│   └── hookctl/       # CLI tool
├── internal/
│   ├── config/        # YAML loading and merging
│   ├── conditions/    # Condition evaluation
│   ├── actions/       # Action execution
│   └── rules/         # Rule matching engine
├── conditions.yaml    # Scaffold conditions
├── actions.yaml       # Scaffold actions
├── rules.yaml         # Scaffold rules
└── Makefile          # Build automation
```

### Building

```bash
make build    # Build binaries
make clean    # Remove binaries
make test     # Run tests
make install  # Install to ~/.local/bin
```

### Testing

Create test events and use `hookctl test`:

```bash
# Create test event
cat > test.json <<EOF
{
  "hook_type": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {"command": "rm -rf /"},
  "session_id": "test"
}
EOF

# Test against rules
./bin/hookctl test test.json
```

Or pipe directly to dispatcher:

```bash
cat test.json | ./bin/dispatcher
echo "Exit code: $?"
```

## Examples

See the scaffold YAML files for complete examples:
- `conditions.yaml` - 13 reusable conditions
- `actions.yaml` - 10 reusable actions
- `rules.yaml` - 6 security rules

## Troubleshooting

**Rules not loading:**
- Check config paths with `hookctl config show`
- Validate YAML with `hookctl config validate`
- Ensure YAML files are in correct locations

**Rules not matching:**
- Test with `hookctl test event.json`
- Check trigger event type and tool matcher
- Verify condition logic with debug events

**Template variables not rendering:**
- Ensure variables exist in `tool_input`
- Check for typos in variable names
- Templates support dot notation: `tool_input.command`

## License

Part of workflow-guard Claude Code plugin.
