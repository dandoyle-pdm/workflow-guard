---
description: Kickstart session with quality chain coordination
---

Use ultrathink to coordinate quality chains for this kickoff.

## Kickoff Prompt

$ARGUMENTS

## Process

1. **Analyze** - What type of work? (code, docs, plugin, prompt, config)
2. **Select chain** - Match to quality recipe below
3. **Ticket** - Create in project's `tickets/queue/` if tracked work
4. **Push** - Commit and push ticket immediately
5. **Delegate** - Invoke agent via Task tool (never implement in main thread)

## Quality Recipes

| Type | Recipe | Chain | Starting Agent |
|------|--------|-------|----------------|
| Code | R1 | Creator→Critic→Judge | code-developer |
| Docs (100+ lines) | R2 | Creator→Critic→Judge | tech-writer |
| Handoff/prompts | R3 | Quick check | tech-editor |
| Read-only | R4 | None | - |
| Config/minor | R5 | Single reviewer | code-reviewer |
| Plugin | Plugin | Creator→Critic→Judge | plugin-engineer |
| Prompt | Prompt | Creator→Critic→Judge | prompt-engineer |

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
