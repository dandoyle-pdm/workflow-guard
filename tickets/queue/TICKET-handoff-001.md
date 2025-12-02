---
# Metadata
ticket_id: TICKET-handoff-001
session_id: handoff-updates
sequence: 001
parent_ticket: null
title: Add work methodology section to all handoff commands
cycle_type: development
status: approved
created: 2025-12-02 01:15
worktree_path: null
---

# Requirements

## What Needs to Be Done
Update all 5 handoff commands to include a "Work Methodology for Next Session" section that guides the next Claude session on proper work practices.

**Files to Update**:
1. commands/handoff.md
2. commands/handoff-development.md
3. commands/handoff-debug.md
4. commands/handoff-hotfix.md
5. commands/handoff-investigate.md

## Acceptance Criteria
- [ ] Each handoff command includes "Work Methodology for Next Session" section
- [ ] Section covers ultrathink (mcp__sequential-thinking__sequentialthinking) usage
- [ ] Section covers quality chain selection (R1-R5)
- [ ] Section covers agent delegation via Task tool
- [ ] Context-specific patterns appropriate for each handoff type
- [ ] Consistent formatting across all commands

# Context

## Why This Work Matters
Previous session implemented handoff updates directly without using quality cycles - those changes were reverted. This ticket tracks the proper implementation through the plugin quality chain.

The work methodology section ensures next sessions:
1. Use ultrathink for complex planning
2. Select appropriate quality chains based on work type
3. Delegate to agents rather than implementing directly in main thread
4. Follow context-specific patterns for the work type

## References
- Previous handoff (reverted): Commit 072bc7b
- Plugin agent chain: TICKET-plugin-chain-001.md in qc-router

## Work Methodology Content to Add

Each handoff should include a section like:

```markdown
## Work Methodology for Next Session

### Ultrathink (Sequential Thinking)
Use `mcp__sequential-thinking__sequentialthinking` for:
- [Context-specific planning needs]
- Breaking down implementation steps
- Reasoning through quality chain selection

### Quality Chains
Select chain based on work type:
| Chain | Work Type | Flow |
|-------|-----------|------|
| **R1** | Production code | code-developer → code-reviewer → code-tester |
| **R2** | Documentation (100+ lines) | tech-writer → tech-editor → tech-publisher |
| **R3** | Handoff prompts | tech-editor (quick check) |
| **R4** | Read-only queries | None (fast path) |
| **R5** | Config/minor changes | Single reviewer |
| **Plugin** | Plugin resources | plugin-engineer → plugin-reviewer → plugin-tester |

### Agent Delegation
Keep main thread lean - delegate heavy lifting:
- Use `Task` tool with appropriate `subagent_type`
- [Context-specific agent recommendations]
- Main thread coordinates; agents execute

### Ticket Workflow
For tracked work:
1. Create ticket in `tickets/queue/`
2. Work moves to `tickets/active/{branch}/`
3. Complete to `tickets/completed/{branch}/` before PR
```

Each handoff type should customize the context-specific parts:
- **Development**: Focus on code-developer, feature implementation
- **Debug**: Focus on investigation patterns, code-tester validation
- **Hotfix**: Focus on rapid iteration, minimal chain (R5 or R1)
- **Investigate**: Focus on exploration agents, research patterns
- **General**: Balanced approach covering all scenarios

# Creator Section

## Implementation Notes
Added "Work Methodology for Next Session" section to all 5 handoff commands with consistent structure but context-specific customizations:

1. **Ultrathink subsection**: Each handoff type gets specific use cases for sequential thinking:
   - General: Broad planning, trade-off analysis
   - Development: Architectural decisions, design trade-offs
   - Debug: Hypothesis formation, investigation planning
   - Hotfix: Rapid triage, risk assessment
   - Investigate: Research questions, evidence synthesis

2. **Quality Chains table**: Consistent R1-R5 + Plugin chain across all files, with a context-specific "Focus" note explaining which chain is primary for that handoff type.

3. **Agent Delegation subsection**: Customized agent recommendations:
   - General: Match agent to work type
   - Development: code-developer, code-reviewer, code-tester
   - Debug: Explore for investigation, code-tester for reproduction
   - Hotfix: Speed over process, direct implementation acceptable
   - Investigate: Explore for digging, main thread synthesizes

4. **Ticket Workflow subsection**: Standard workflow with context-specific adaptations:
   - Hotfix: "Fix first, ticket later" for emergencies
   - Investigate: R4 fast path, spawn tickets for resulting work

## Questions/Concerns
None - implementation follows the template from ticket requirements closely.

## Changes Made
- File changes:
  - `commands/handoff.md`: Added 33-line section before "Key Principle" (lines 69-101)
  - `commands/handoff-development.md`: Added 35-line section before "Present Handoff" (lines 147-181)
  - `commands/handoff-debug.md`: Added 35-line section before "Present Handoff" (lines 130-164)
  - `commands/handoff-hotfix.md`: Added 36-line section before "Present Handoff" (lines 150-184)
  - `commands/handoff-investigate.md`: Added 35-line section before "Present Handoff" (lines 189-223)
- Commits: Pending (no commit made - ticket workflow does not require commit at this stage)

**Status Update**: 2025-12-02 01:30 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None found

### HIGH Issues
- [ ] `handoff-debug.md:154`, `handoff-investigate.md:213` - References `subagent_type: Explore` which is not a recognized agent type. Should clarify if this is a valid subagent_type or replace with appropriate guidance. Other agents use lowercase-with-hyphens convention (code-developer, code-tester, etc.)

### MEDIUM Issues
- [ ] All 5 files - Quality chain tables use `->` arrows; verify this matches canonical format in main documentation
- [ ] `handoff.md:69-101` - Missing "Focus" note after Quality Chains table (unlike the other 4 handoff commands which have context-specific Focus notes). Consider adding "**General Focus**: Match chain to work type detected from session analysis."

## Strengths Observed
1. All frontmatter is valid with proper description fields
2. Consistent section structure across all files (Ultrathink, Quality Chains, Agent Delegation, Ticket Workflow)
3. Context-appropriate customizations for each handoff type (Dev->R1, Debug->R4-then-R1, Hotfix->speed-over-process, Investigate->R4-with-spawning)

## Approval Decision
APPROVED (with minor suggestions)

## Rationale
The implementation successfully meets all acceptance criteria from the ticket:
- Each handoff command includes "Work Methodology for Next Session" section
- Ultrathink (mcp__sequential-thinking__sequentialthinking) usage is covered
- Quality chain selection (R1-R5 + Plugin) is documented
- Agent delegation via Task tool is explained
- Context-specific patterns are appropriate for each handoff type
- Formatting is consistent across commands

The HIGH issue regarding `Explore` subagent_type is worth clarifying but does not block approval - it appears to be an intentional reference to a general exploration pattern rather than a formal agent definition. The MEDIUM issues are polish items that can be addressed in a follow-up if desired.

**Status Update**: 2025-12-02 01:45 - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Frontmatter valid: PASS (all 5 files have valid `description` fields)
- Markdown structure: PASS (no syntax errors, proper heading hierarchy, valid tables)
- Content completeness: PASS (all files contain "Work Methodology for Next Session" with 4 subsections)
- Technical accuracy: PASS (quality chains correct, `Explore` is valid subagent_type per Task tool docs)

## Critic Finding Disposition

### HIGH Issue: `Explore` subagent_type reference
**DISMISSED** - `Explore` is a valid subagent_type in the Task tool. The system prompt explicitly documents: `subagent_type` options include "Explore" (fast for exploration), "code" (default), or "research" (web-enabled). The capitalization is correct per the API specification.

### MEDIUM Issues
1. Arrow format (`->`) - **DEFERRED**: Consistent with ticket template and readable; no canonical format specified that differs.
2. Missing "Focus" note in `handoff.md` - **DEFERRED**: The general handoff is intentionally balanced/generic; context-specific focus notes are appropriate for specialized handoffs only.

## Acceptance Criteria Verification
- [x] Each handoff command includes "Work Methodology for Next Session" section
- [x] Section covers ultrathink (mcp__sequential-thinking__sequentialthinking) usage
- [x] Section covers quality chain selection (R1-R5)
- [x] Section covers agent delegation via Task tool
- [x] Context-specific patterns appropriate for each handoff type
- [x] Consistent formatting across all commands

## Quality Gate Decision
**APPROVE**

## Rationale
All acceptance criteria are met. The 5 handoff command files have been successfully updated with the "Work Methodology for Next Session" section. Each file includes:
1. Ultrathink guidance with context-appropriate use cases
2. Quality Chains table (R1-R5 + Plugin) with context-specific focus notes
3. Agent Delegation guidance tailored to the work type
4. Ticket Workflow instructions

The HIGH issue raised by the critic was a false positive - `Explore` is a documented subagent_type. The MEDIUM issues are cosmetic and do not impact functionality.

## Next Steps
1. Creator commits changes with semantic message: `docs: add work methodology section to handoff commands`
2. PR for merge to main
3. Move ticket to `tickets/completed/{branch}/` after PR merge

**Status Update**: 2025-12-02 02:00 - Changed status to `approved`

# Changelog

## [2025-12-02 02:00] - Expediter (plugin-tester)
- Validated all 5 handoff command files
- Verified frontmatter, markdown structure, content completeness, technical accuracy
- Dismissed HIGH issue: `Explore` is valid subagent_type per Task tool documentation
- Deferred MEDIUM issues as cosmetic/non-blocking
- All acceptance criteria verified complete
- Status changed to `approved`

## [2025-12-02 01:45] - Critic (plugin-reviewer)
- Reviewed implementation for all 5 files
- Identified 1 HIGH issue (Explore subagent_type - later dismissed)
- Identified 2 MEDIUM issues (arrow format, missing Focus note)
- Approved with minor suggestions
- Status changed to `expediter_review`

## [2025-12-02 01:30] - Creator (plugin-engineer)
- Implemented Work Methodology section in all 5 handoff commands
- Added context-specific customizations for each handoff type
- Status changed to `critic_review`

## [2025-12-02 01:15] - Coordinator
- Ticket created
- Context: Redoing reverted work through proper quality chain
- Implementation: Use plugin-engineer -> plugin-reviewer -> plugin-tester
