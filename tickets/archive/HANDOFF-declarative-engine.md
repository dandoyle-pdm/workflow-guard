# Handoff Prompt: Declarative Hook Engine Implementation

Use this prompt to start a new Claude Code session to implement the declarative hook engine.

---

## Session Kickstart Prompt

```
I need to implement a declarative hook engine for the workflow-guard plugin. There are two tickets in the queue that define the work:

1. **TICKET-declarative-engine-001** (Foundation)
   - Port the declarative hook engine from qc-router/research/claude-hooks-engine to workflow-guard
   - Create engine/dispatcher.py, cli.py, and scaffold YAML files
   - Update hooks.json to use single dispatcher entry point
   - Status: open, ready to work

2. **TICKET-edit-confirmation-001** (Rules)
   - Create conditions for DANGEROUS_PATTERNS (Bash redirect, heredoc, tee, sed -i, etc.)
   - Implement confirm-code-edits rule
   - Test all bypass scenarios
   - Status: blocked (depends on TICKET-declarative-engine-001)

## Critical Process Requirements

**YOU MUST USE THE QUALITY CYCLE:**
1. Pick up TICKET-declarative-engine-001 from `workflow-guard/tickets/queue/`
2. Dispatch to code-developer agent via Task tool - the AGENT does the work
3. DO NOT implement directly in main thread - that wastes context
4. Let the cycle complete: code-developer → code-reviewer → code-tester
5. Agents write files, update tickets, make commits
6. Main thread coordinates and reports results

**What NOT to do:**
- Do NOT write code yourself - dispatch to agents
- Do NOT use Bash heredoc to write files (ironic given the ticket content)
- Do NOT skip the quality cycle

## Context

The previous session identified a critical gap: our confirm-code-edits.sh hook only catches Edit/Write tools, but Bash commands like `cat > file << 'EOF'` bypass it entirely. The declarative engine solves this by:

1. Single dispatcher handles ALL tool events
2. Rules compose conditions with regex, glob, compound logic
3. DANGEROUS_PATTERNS become reusable conditions
4. New protections are YAML declarations, not code

## Key Resources

- Source implementation: `/home/ddoyle/.claude/plugins/qc-router/research/claude-hooks-engine/`
- Architecture doc: `research/claude-hooks-engine/ARCHITECTURE.md`
- Guardrails research: `/home/ddoyle/.claude/plugins/qc-router/research/guardrails.md`
- Tickets: `workflow-guard/tickets/queue/TICKET-declarative-engine-001.md`

## Work Order

1. Complete TICKET-declarative-engine-001 first (foundation)
2. Merge to main via PR
3. Then unblock and work TICKET-edit-confirmation-001 (rules)
4. Test all bypass scenarios explicitly

Start by reading the tickets and the source implementation, then dispatch to the quality cycle.
```

---

## Notes for Future Sessions

### Ticket Naming Convention
- `TICKET-{feature-name}-{sequence}`
- `{feature-name}` becomes the worktree branch
- `{sequence}` is for sub-tickets within a feature
- Different features need different names

### Missing: Product Quality Transformer
The qc-router plugin currently lacks a product-manager or product-analyst agent for:
- Designing requirements
- Building product backlog
- Mapping stories to tickets

This could be added as a future enhancement to the plugin-engineer cycle.

### Dependency Chain
```
TICKET-declarative-engine-001 (Foundation)
    ↓ must complete first
TICKET-edit-confirmation-001 (Rules)
```

Do NOT try to parallelize these - the rules ticket depends on the engine being complete.
