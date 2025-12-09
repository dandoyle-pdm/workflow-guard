---
description: Kickstart session with quality chain coordination
---

Use ultrathink to coordinate quality transformers for this kickoff.

## Kickoff Prompt

$ARGUMENTS

## Handoff Detection

Check if input contains 2+ handoff markers:

- "Session Type:" or "## Session Type" or "Session Continuation:"
- "Next Steps:" or "## Next Steps"
- "TICKET-" references
- "Current Understanding:" or "## Current Understanding"

If detected (2+ markers present):

1. **Extract session type** from "Session Type:" or "Session Continuation:" line
2. **Map to quality chain**: DEBUGGING→R1(code-tester), DEVELOPMENT→R1(code-developer), EMERGENCY HOTFIX→R5(code-developer), INVESTIGATION→R4(fast-path, no agent)
3. **Extract ticket ref** from "Ticket Reference:" or scan for "TICKET-{id}-{seq}"
4. **Extract next steps** from "Next Steps:" section
5. **Pass full context** to delegated agent (include Current Understanding, Changes Made, etc.)
6. If ticket exists: continue in active/{branch}/, else create new ticket

## Process

1. **Analyze** - Handoff structure OR generic work type (code, docs, plugin, prompt, config)
2. **Select chain** - From session type OR match to quality recipe below
3. **Ticket** - Continue existing OR create in project's `tickets/queue/` if tracked work
4. **Push** - Commit and push ticket immediately
5. **Delegate** - Invoke agent via Task tool with full context (never implement in main thread)

## Quality Recipes

| Type              | Recipe | Chain                | Starting Agent  |
| ----------------- | ------ | -------------------- | --------------- |
| Code              | R1     | Creator→Critic→Judge | code-developer  |
| Docs (100+ lines) | R2     | Creator→Critic→Judge | tech-writer     |
| Handoff/prompts   | R3     | Quick check          | tech-editor     |
| Read-only         | R4     | None                 | -               |
| Config/minor      | R5     | Single reviewer      | code-reviewer   |
| Plugin            | Plugin | Creator→Critic→Judge | plugin-engineer |
| Prompt            | Prompt | Creator→Critic→Judge | prompt-engineer |

## Rules

- **50 lines** - All artifacts ≤50 substantive lines
- **Single responsibility** - One clear purpose per artifact
- **Never implement in main thread** - Delegate to agents
- **Push tickets immediately** - Establishes distributed lock
- **Commit after every todo** - No batching

## Ticket Template

Use project's `tickets/TEMPLATE.md` for structure. Key fields:

- `ticket_id`: TICKET-{session-id}-{sequence}
- `cycle_type`: development|documentation|architecture
- `status`: open → in_progress → critic_review → approved
