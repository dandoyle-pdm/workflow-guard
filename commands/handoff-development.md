---
description: Auto-generate development session handoff prompt
---

Analyze this development session and automatically generate a handoff prompt that captures my current understanding of the feature, design decisions, implementation progress, and mental model.

## What I Know About This Session

From the conversation, I understand we're building something. Let me automatically extract:

### The Feature/Work
- What are we building or changing (from conversation context)
- Why it's needed (from requirements discussion or user request)
- Scope and boundaries (from design decisions)

### Design Decisions Made
- Architectural choices I've made (from my reasoning in conversation)
- Why I chose these approaches (from design rationale)
- Trade-offs considered (from discussion of alternatives)
- Patterns being followed (from code analysis and implementation)

### Implementation Progress
- What's complete (from Edit/Write tool usage + my statements)
- What's in progress (from current tool usage + conversation state)
- What's not started yet (from planned next steps)
- How components fit together (from my understanding of architecture)

### Code Understanding
- How the existing codebase works (from Read tool usage analysis)
- Where this feature integrates (from file modifications)
- Patterns I'm following (from code analysis)
- Conventions I'm maintaining (from existing code study)

## Auto-Generate System State

Gather without asking:
```bash
pwd                           # Working directory
git status --short            # Modified/new files
git log -5 --oneline          # Recent commits
git branch --show-current     # What branch
docker ps --filter "name=novacloud"  # Running containers
```

## Extract From Tool Usage

Automatically analyze my tool usage in this session:
- **Read calls**: What existing code did I study and what did I learn
- **Write calls**: What new files did I create and why
- **Edit calls**: What existing files did I modify and what changed
- **Bash calls**: What commands did I run (tests, builds, deployments)

## Capture My Development Mental Model

From my reasoning throughout the conversation, extract:

1. **Feature understanding**: Not just "what to build" but "why it works this way"
2. **Architecture insight**: How components interact, where code belongs
3. **Design rationale**: Why I structured it this way vs alternatives
4. **Integration points**: How this connects to existing systems
5. **Assumptions about requirements**: What I'm assuming vs what's explicit
6. **Code patterns**: What patterns I'm following and why

## Generate Development Handoff

Using the FEATURE_IMPLEMENTATION template (adapted to DEVELOPMENT) from SESSION_CONTINUATION_FORMAT.md:

```markdown
# Session Continuation: DEVELOPMENT

## Executive Summary
[Auto-generated: What we're building + how far along + current focus]

## Working Directory
[From pwd]

## Current State
- Branch: [From git branch]
- Committed: [From git status - what's committed vs uncommitted]
- Tests: [From test runs - passing/failing/not written]
- Deployable: [From build/deploy attempts - yes/no/partial]

## What We're Building
[From conversation - feature description, requirements, goals]

## Design Decisions Made
1. **[Decision 1]**: [What I chose and why - from my reasoning]
2. **[Decision 2]**: [Architecture choice and rationale]
3. **[Decision 3]**: [Pattern or approach and trade-offs]

## Implementation Progress

### Completed
- **[Module/Component]**: [What's done - from tool usage and my statements]
  - File: [file:line] - [what was added/changed]
  - Why: [reasoning from conversation]

### In Progress
- **[Module/Component]**: [Current state - from active tool usage]
  - File: [file:line] - [what's partially done]
  - Next: [what remains for this component]

### Not Started
- **[Module/Component]**: [Planned work - from discussion]
  - Why not started: [blocked on something? queued? design needed?]

## Code Architecture Understanding
[How the pieces fit together - from my analysis of codebase]
- Where this feature lives in the codebase
- How it integrates with existing systems
- Data flow and component interactions
- Patterns being followed

## Changes Made This Session
[From Edit/Write tool usage - file:line format with explanations]

## Current Understanding (Mental Model)
[Deep insight into how the feature works and why it's designed this way - critical for next Claude to think like me]

## Testing Status
- **Unit Tests**: [written/not written, passing/failing]
- **Integration Tests**: [status]
- **Manual Testing**: [what I've tested, results]

## Next Steps
[Logical continuation - what to implement next based on current progress]

## Success Criteria
✓ [Requirement met]
✓ [Tests pass]
✓ [Integration verified]
✓ [Documentation complete]

## Open Questions
[Design decisions pending, unclear requirements, need clarification]
```

## Key Insights to Preserve

Highlight the most important insights I've gained that next Claude MUST understand:
- Why certain design decisions were made (context that isn't in code)
- How existing code works (insights from studying codebase)
- Where gotchas or complexity lie
- What patterns must be maintained for consistency
- Important context from user discussions or requirements

## Work Methodology for Next Session

### Ultrathink (Sequential Thinking)
Use `mcp__sequential-thinking__sequentialthinking` for:
- Architectural decisions with multiple valid approaches
- Breaking down feature implementation into components
- Reasoning through design trade-offs
- Planning test strategy for new functionality

### Quality Chains
Select chain based on work type:
| Chain | Work Type | Flow |
|-------|-----------|------|
| **R1** | Production code | code-developer -> code-reviewer -> code-tester |
| **R2** | Documentation (100+ lines) | tech-writer -> tech-editor -> tech-publisher |
| **R3** | Handoff prompts | tech-editor (quick check) |
| **R4** | Read-only queries | None (fast path) |
| **R5** | Config/minor changes | Single reviewer |
| **Plugin** | Plugin resources | plugin-engineer -> plugin-reviewer -> plugin-tester |

**Development Focus**: R1 is your primary chain. Use code-developer for implementation, code-reviewer for design validation, code-tester for verification.

### Agent Delegation
Keep main thread lean - delegate heavy lifting:
- Use `Task` tool with `subagent_type: code-developer` for feature implementation
- Use `subagent_type: code-reviewer` for architecture validation
- Use `subagent_type: code-tester` for test creation and verification
- Main thread coordinates; agents execute

### Ticket Workflow
For tracked work:
1. Create ticket in `tickets/queue/`
2. Work moves to `tickets/active/{branch}/`
3. Complete to `tickets/completed/{branch}/` before PR

## Present Handoff

Show the complete handoff in a code block, explain what I detected about the session, and ask if the user wants to save it to `handoff-development-YYYYMMDD-HHMM.md` or use as-is.
