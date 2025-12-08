---
# Metadata
ticket_id: TICKET-kickoff-cmd-001
session_id: kickoff-cmd
sequence: 001
parent_ticket: null
title: Create /kickoff slash command for session coordination
cycle_type: development
status: approved
claimed_by: ddoyle
claimed_at: 2025-12-07 23:02
created: 2025-12-07 20:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-cmd
---

# Requirements

## What Needs to Be Done

Create `commands/kickoff.md` (~45 lines) - a slash command that kickstarts sessions with quality chain coordination.

## Acceptance Criteria
- [x] Creates commands/kickoff.md
- [x] Command analyzes work type from $ARGUMENTS
- [x] Selects appropriate quality recipe (R1-R5)
- [x] Creates ticket if tracked work
- [x] Delegates to appropriate agent via Task tool
- [x] ≤50 lines, single-responsibility

# Context

## Why This Work Matters

Enables consistent session starts. Currently sessions require manual quality chain coordination. This command automates the pattern.

## Command Specification

```markdown
---
description: Kickstart session with quality chain coordination
---

Use ultrathink to coordinate quality chains for this kickoff.

## Kickoff Prompt
$ARGUMENTS

## Process
1. Analyze - What type of work?
2. Select chain - Match to quality recipe
3. Ticket - Create if tracked, push immediately
4. Delegate - Invoke agent via Task tool

## Recipes
| Type | Chain | Agent |
|------|-------|-------|
| Code | R1 | code-developer |
| Docs | R2 | tech-writer |
| Plugin | Plugin | plugin-engineer |

## Rules
- 50 lines, single-responsibility, all artifacts
- Never implement in main thread
- Push tickets immediately
```

## References
- Existing commands: commands/*.md (handoff-*.md, activate.md)
- Quality recipes: qc-router CLAUDE.md

# Creator Section

## Implementation Notes

The `/kickoff` command has been successfully implemented in `commands/kickoff.md` (44 lines).

**Design decisions:**
1. **Comprehensive recipe table** - Includes all quality recipes (R1-R5) plus Plugin and Prompt recipes for complete coverage
2. **Clear 5-step process** - Analyze → Select chain → Ticket → Push → Delegate
3. **Ultrathink instruction** - Command starts with "Use ultrathink to coordinate quality chains" to ensure proper reasoning
4. **$ARGUMENTS placeholder** - Captures user's kickoff request verbatim
5. **Explicit rules section** - Reinforces 50-line limit, single responsibility, and delegation requirements
6. **Ticket template guidance** - References project's `tickets/TEMPLATE.md` with key field examples

**Implementation approach:**
- Followed existing command format (handoff.md, activate.md style)
- Used markdown table for recipe mapping with Starting Agent column
- Included enforcement rules to prevent common anti-patterns
- Added ticket template section for workflow integration

**Line count:** 44 lines (6 under the 50-line limit)

## Changes Made
- File changes:
  - `commands/kickoff.md` - Created new slash command (44 lines)
- Commits:
  - `1a2df52` - "feat: add /kickoff command for session coordination"

**Status Update**: 2025-12-07 23:15 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None found.

### HIGH Issues
None found.

### MEDIUM Issues
- [x] `commands/kickoff.md:21-30` - Chain column shows generic "Creator→Critic→Judge" pattern instead of specific agent names. While this is acceptable for brevity, it could be clearer to show actual agent sequences (e.g., "code-developer→code-reviewer→code-tester" for R1). However, this is consistent with the abstraction level of the command and makes the table more readable.

- [x] `commands/kickoff.md:26` - R4 (read-only) correctly shows "-" for Starting Agent, but the column header "Starting Agent" implies all recipes have one. Consider renaming to "Starting Agent (if applicable)" or accepting this minor ambiguity.

- [x] `commands/kickoff.md:39-44` - Ticket template section could be more specific about which `cycle_type` values map to which recipes (development, documentation, architecture), but this is documented in the project's TEMPLATE.md.

## Approval Decision
APPROVED

## Rationale

The `/kickoff` command successfully meets all acceptance criteria and follows established patterns:

1. **Requirements Met:** All acceptance criteria satisfied - analyzes work type, selects recipe, creates tickets, delegates to agents, under 50 lines (44)

2. **Comprehensive Coverage:** All quality recipes (R1-R5, Plugin, Prompt) correctly mapped with appropriate agents

3. **Consistency:** Follows existing command format (frontmatter, sections, markdown style) matching handoff.md and activate.md patterns

4. **Clarity:** Clear 5-step process, well-organized table, explicit rules enforcement

5. **Best Practices:** Single responsibility, proper markdown, appropriate line count

The medium-priority issues identified are minor style considerations that don't impact functionality. The generic "Creator→Critic→Judge" pattern in the Chain column is actually beneficial for readability and maintains appropriate abstraction. The command is production-ready.

**Recommendation:** Approve for expediter validation.

**Status Update**: 2025-12-07 23:45 - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Command syntax valid: PASS
- ≤50 lines: PASS (44 lines)
- References correct: PASS

### Detailed Validation

**1. Format Validation:**
- Frontmatter present and valid: `description: Kickstart session with quality chain coordination`
- Markdown syntax: Valid
- $ARGUMENTS placeholder: Correctly placed in "Kickoff Prompt" section
- Line count: 44 lines (6 under limit)

**2. Reference Verification:**
- Quality recipes R1-R5: Match global CLAUDE.md definitions
  - R1 (Production code): code-developer → code-reviewer → code-tester ✓
  - R2 (Docs 100+ lines): tech-writer → tech-editor → tech-publisher ✓
  - R3 (Handoff prompts): tech-editor (quick check) ✓
  - R4 (Read-only queries): None (fast path) ✓
  - R5 (Config/minor changes): Single reviewer ✓
- Plugin recipe: Follows plugin-engineer → plugin-reviewer → plugin-tester ✓
- Prompt recipe: Uses prompt-engineer (standard pattern) ✓
- Ticket template reference: `tickets/TEMPLATE.md` exists and is accurate ✓
- Agent names: All valid (code-developer, tech-writer, plugin-engineer, prompt-engineer) ✓

**3. Integration Check:**
- File location: `commands/kickoff.md` ✓
- Follows command format: Matches handoff.md and activate.md patterns ✓
- Process steps clearly defined: 5-step workflow (Analyze → Select → Ticket → Push → Delegate) ✓
- No syntax errors: Clean markdown ✓

**4. Content Quality:**
- Single responsibility: Session coordination with quality chain selection ✓
- Comprehensive coverage: All 7 quality recipes documented ✓
- Clear rules section: 50-line limit, single responsibility, delegation requirements ✓
- Ultrathink instruction: Ensures proper reasoning before delegation ✓

## Quality Gate Decision
APPROVE

## Next Steps
The `/kickoff` command is production-ready:
1. Command will be available after Claude Code restart
2. File is properly located in `commands/kickoff.md`
3. All acceptance criteria met and validated
4. No critical, high, or blocking issues identified
5. Plugin-reviewer identified 3 minor style considerations (non-blocking)

This implementation provides comprehensive quality chain coordination for session kickoff, with proper recipe mapping, clear process flow, and enforcement of best practices.

**Status Update**: 2025-12-07 23:55 - Changed status to `approved`

# Changelog

## [2025-12-07 20:45] - Coordinator
- Ticket created for /kickoff command implementation

## [2025-12-07 23:02] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-cmd
- Branch: ticket/kickoff-cmd

## [2025-12-07 23:15] - plugin-engineer
- Implemented `commands/kickoff.md` (44 lines)
- All acceptance criteria met
- Status changed to `critic_review`

## [2025-12-07 23:45] - plugin-reviewer
- Audit completed - APPROVED
- No critical or high priority issues found
- 3 medium-priority style considerations documented (non-blocking)
- Command meets all requirements and follows existing patterns
- Comprehensive recipe coverage (R1-R5, Plugin, Prompt)
- Status changed to `expediter_review`

## [2025-12-07 23:55] - plugin-tester
- Validation completed - APPROVED
- All format checks PASS (frontmatter, markdown, $ARGUMENTS, 44 lines)
- All quality recipe references verified against global CLAUDE.md
- All agent names validated (code-developer, tech-writer, plugin-engineer, prompt-engineer)
- Integration checks PASS (file location, command format, process flow)
- Content quality verified (single responsibility, comprehensive coverage, clear rules)
- Status changed to `approved`

## [2025-12-07 23:19] - Completed
- Status changed to approved
- Ready for PR creation
