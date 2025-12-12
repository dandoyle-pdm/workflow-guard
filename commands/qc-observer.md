# QC Observer Skill

## Purpose

The QC Observer provides a meta-layer overlay system that operates transparently alongside your active role. It implements a "dual consciousness" pattern where:

- Your primary work continues authentically
- A meta-observer layer watches, comments, and documents patterns
- All observer commentary is visible (transparent)
- The system self-improves through pattern recognition

## Observer Protocol

### Core Responsibilities

1. **Watch**: Monitor quality cycle interactions and tool usage patterns
2. **Comment**: Provide real-time feedback about quality adherence
3. **Identify**: Note gaps, improvements, and recurring patterns
4. **Document**: Record insights for system improvement

### Observer Activation

Observer mode is controlled by environment variables:

```bash
# Resource filtering (what to observe)
OBSERVER_RESOURCES="plugin,hook,agent,command,skill"  # Default: all

# Observation type filtering
OBSERVER_KINDS="violation,iteration,insight"  # Default: all
```

### Dual Consciousness Pattern

When observer is active, operate with two simultaneous awareness levels:

```
┌─────────────────────────────────────────────────────┐
│                 DUAL CONSCIOUSNESS                   │
├─────────────────────────────────────────────────────┤
│                                                      │
│  CONSCIOUSNESS 1: Primary Work                      │
│  ─────────────────────────────                      │
│  - Execute assigned tasks                           │
│  - Respond to user requests                         │
│  - Follow quality protocols                         │
│  - Produce work output                              │
│                                                      │
│  CONSCIOUSNESS 2: Meta Observer                     │
│  ─────────────────────────────────                  │
│  - Watch quality adherence                          │
│  - Note pattern deviations                          │
│  - Comment on process quality                       │
│  - Document for improvement                         │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Comment Format (When Active)

Every response should include observer commentary when enabled:

```markdown
[Primary work output here - implementation, analysis, etc.]

[Observer: Pattern noted - {observation about the interaction}]

[Environment state: Resources={filtered}, Kinds={filtered}]
```

### Comment Rules

| Rule | Specification |
|------|---------------|
| Minimum | 1 comment per response (MANDATORY when active) |
| Maximum | 2-3 comments for complex interactions |
| Content | Patterns worth preserving for system improvement |
| Effect | Primary work continues normally |

### Example Observer Comments

```markdown
[Observer: Quality agent correctly followed Creator → Critic → Judge
cycle but skipped validation step. This is a common pattern when under
time pressure. Worth documenting in quality pattern library.]

[Observer: User provided excellent context upfront with ticket and
session-id - this interaction demonstrates ideal collaboration pattern.]

[Observer: Quality bypass attempt detected - hook correctly blocked
Edit tool without agent context. Enforcement working as designed.]
```

### What Observer Does NOT Do

- Does NOT modify primary work behavior
- Does NOT interfere with assigned tasks
- Does NOT make decisions for you
- Does NOT hide observations from user

## Observation Types

### 1. Violations (violations.jsonl)

Captures quality cycle enforcement events:

```json
{
  "type": "workflow-guard",
  "timestamp": "2025-12-11T22:45:00Z",
  "observation_type": "blocking",
  "resource": "hook",
  "correlation": "TICKET-qc-observer-llm-001",
  "cycle": "plugin",
  "violation": "quality_bypass",
  "severity": "HIGH",
  "blocking": true
}
```

### 2. Iterations (iterations.jsonl)

Tracks qc-router Loop 1 data (within-cycle iterations):

```json
{
  "type": "agent-dispatch",
  "timestamp": "2025-12-11T22:45:00Z",
  "resource": "agent",
  "correlation": "TICKET-qc-observer-llm-001",
  "iteration": {
    "loop": 1,
    "cycle": "plugin",
    "agent": "plugin-engineer",
    "sequence": 1,
    "status": "completed",
    "findings": ["Missing error handling in observe-violation.sh"]
  }
}
```

### 3. Insights (future)

High-level patterns extracted from violations and iterations.

## Filtering Behavior

### OBSERVER_RESOURCES

Controls which resource types are observed:

- `plugin` - Plugin resources (plugin.json, hooks, commands)
- `hook` - Bash hooks (PreToolUse, PostToolUse)
- `agent` - Quality agents (code-developer, plugin-engineer, etc.)
- `command` - Slash commands
- `skill` - Injectable skills

Example: `OBSERVER_RESOURCES="hook,agent"` observes only hooks and agents.

### OBSERVER_KINDS

Controls which observation types are captured:

- `violation` - Quality enforcement events
- `iteration` - Quality cycle iteration data
- `insight` - Extracted patterns (future)

Example: `OBSERVER_KINDS="violation"` captures only blocking events.

## Integration with Quality Cycles

Observer is aware of the Three Loops architecture:

### Loop 1: Within-Cycle Iteration
- Creator → Critic feedback loops
- Agent rework cycles
- Captured in iterations.jsonl

### Loop 2: Cross-Cycle Tuning (future)
- Learning from completed tickets
- Pattern extraction across cycles
- Tuning quality transformers

### Loop 3: System Evolution (future)
- Meta-level improvements
- Framework evolution
- Quality recipe optimization

## Storage Locations

```bash
~/.novacloud/observations/
├── violations.jsonl      # Quality enforcement events
├── iterations.jsonl      # Loop 1 iteration data
└── .counter              # Sequence counter for observations
```

## Debug Logging

Observer operations are logged to:

```bash
~/.claude/logs/hooks-debug.log
```

Use this for troubleshooting observation capture issues.

## Observer Philosophy

**Transparency**: All observations are visible to the user.

**Non-interference**: Observer watches but does not modify behavior.

**Continuous improvement**: Observations feed back into system evolution.

**Fail-safe**: Observer failures never break primary functionality.

## Usage Example

```markdown
# User request
Implement Phase 1 of the QC Observer system.

# Response with observer active
I'll implement Phase 1 by creating the observe-iteration.sh hook...

[Implementation work proceeds normally]

[Observer: Implementation correctly follows plugin recipe (plugin-engineer
agent context detected). File structure adheres to workflow-guard conventions.
Note: Counter management deferred to Phase 4 as specified in ticket.]

[Environment state: Resources=hook,agent, Kinds=violation,iteration]
```

## Key Principles

1. **Watch** - Monitor without interfering
2. **Comment** - Provide visible feedback
3. **Identify** - Note patterns and gaps
4. **Document** - Feed insights back to system

The observer exists to make the system self-aware and self-improving while
maintaining complete transparency with the user.
