# qc-router Documentation Update Prompt

**Purpose:** Take this prompt to the qc-router project to document its integration with workflow-guard.

---

## Context

The workflow-guard plugin (`~/.claude/plugins/workflow-guard/`) is a sister project that enforces git branch protection and quality cycle requirements. It has a new hook that depends on qc-router agent definitions.

## Integration Requirement

workflow-guard's `block-unreviewed-edits.sh` hook needs to detect when a quality agent from qc-router is active. It does this by reading the subagent's transcript and looking for agent identity markers.

## Agent Identity Pattern

**Critical:** Each agent's AGENT.md must contain a recognizable identity string that appears in the transcript when the agent is dispatched.

**Current pattern in AGENT.md files:**
```markdown
You are a pragmatic plugin developer working as the plugin-engineer agent in a quality cycle workflow.
```

**The key phrase is:** `working as the {agent-name} agent`

workflow-guard greps for:
```bash
grep -qE "plugin-engineer agent|plugin-reviewer agent|plugin-tester agent" "$transcript_path"
```

## Documentation to Add

### 1. Add to qc-router README.md

```markdown
## Integration with workflow-guard

The workflow-guard plugin (`~/.claude/plugins/workflow-guard/`) uses qc-router agent identities to enforce quality cycle requirements.

### How It Works

1. workflow-guard blocks file modifications (Edit/Write/NotebookEdit) unless a quality agent is detected
2. When you dispatch a quality agent via Task tool, the AGENT.md content appears in the subagent's transcript
3. workflow-guard reads the transcript and looks for agent identity markers
4. If a recognized quality agent is found, the modification is allowed

### Agent Identity Markers

Each AGENT.md must contain an identity string in this format:
```
working as the {agent-name} agent
```

Example from plugin-engineer:
```
You are a pragmatic plugin developer working as the plugin-engineer agent in a quality cycle workflow.
```

### Recognized Quality Agents

workflow-guard recognizes these agents by default:
- plugin-engineer
- plugin-reviewer
- plugin-tester

Additional agents can be configured via the `QUALITY_AGENTS` environment variable.

### Maintaining Compatibility

When creating or modifying agent AGENT.md files:
1. Keep the identity string pattern: "working as the {name} agent"
2. Place it early in the invocation template
3. Ensure it's part of the prompt that gets sent to the subagent
```

### 2. Add to Each Agent's AGENT.md (if not already present)

Verify each agent has the identity pattern in its invocation template:

**plugin-engineer/AGENT.md:**
```markdown
You are a pragmatic plugin developer working as the plugin-engineer agent...
```

**plugin-reviewer/AGENT.md:**
```markdown
You are a meticulous plugin reviewer working as the plugin-reviewer agent...
```

**plugin-tester/AGENT.md:**
```markdown
You are a thorough plugin tester working as the plugin-tester agent...
```

### 3. Add Integration Section to DEVELOPER.md (if exists)

```markdown
## Sister Project: workflow-guard

qc-router agents are used by workflow-guard to enforce quality cycle requirements.

### Dependency Direction
```
workflow-guard ──depends on──> qc-router
     │                              │
     │ reads transcripts           │ provides agent definitions
     │ for agent identity          │ with identity markers
     └──────────────────────────────┘
```

### Breaking Changes to Avoid

1. **Don't remove the identity pattern** from AGENT.md invocation templates
2. **Don't rename agents** without updating workflow-guard's recognized list
3. **Keep identity string early** in the prompt so it appears in transcript

### Adding New Quality Agents

When adding new quality agents to qc-router:
1. Include identity pattern in AGENT.md: "working as the {name} agent"
2. Update workflow-guard's `QUALITY_AGENTS` list or document for users
3. Test that workflow-guard recognizes the new agent
```

## Verification Steps

After updating qc-router documentation:

1. Verify each agent AGENT.md has identity pattern
2. Test workflow-guard detection:
   ```bash
   # Dispatch a quality agent
   # Attempt Edit/Write
   # Verify it's allowed (not blocked)
   ```
3. Test without quality agent:
   ```bash
   # From main thread (no agent)
   # Attempt Edit/Write
   # Verify it's blocked with guidance
   ```

---

## Summary

**Key Point:** qc-router agent definitions include identity markers that workflow-guard uses to detect quality context. This enables enforcement of the quality cycle (Creator → Critic → Judge) for all file modifications.

**Pattern to preserve:** `working as the {agent-name} agent`

**Files to update:**
- qc-router/README.md - Add integration section
- qc-router/DEVELOPER.md - Add sister project section
- Verify all agent AGENT.md files have identity pattern
