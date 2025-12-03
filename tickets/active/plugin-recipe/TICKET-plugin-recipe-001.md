---
# Metadata
ticket_id: TICKET-plugin-recipe-001
session_id: plugin-recipe
sequence: 001
parent_ticket: null
title: Add Plugin recipe as primary quality cycle for workflow-guard
cycle_type: documentation
status: critic_review
created: 2025-12-03 16:30
worktree_path: null
---

# Requirements

## What Needs to Be Done
Update DEVELOPER.md to establish the **Plugin recipe** as the PRIMARY quality cycle for all workflow-guard work. Currently the documentation shows R1 (code-developer) but this is a Claude Code plugin - all work should use the plugin-engineer cycle.

**Files to Modify:**
1. `DEVELOPER.md` - Update quality cycle matrix to emphasize Plugin recipe

## Acceptance Criteria
- [ ] Plugin recipe listed as PRIMARY for workflow-guard (not just an option)
- [ ] Clear definition of what constitutes "plugin resources"
- [ ] plugin-engineer focus areas documented (logic, design, security, compatibility)
- [ ] Differentiation between R1 (generic code) vs Plugin (Claude Code plugins)
- [ ] Examples of when to use Plugin vs R1

# Context

## Why This Work Matters
The previous work on edit-confirmation rules incorrectly used the code-developer cycle instead of plugin-engineer. This led to:
1. Missing logic/design review from plugin perspective
2. No validation against Claude Code hook patterns
3. Documentation that doesn't reflect the correct workflow

**Plugin work requires different review focus:**
- Logic: Does the hook/rule do what it claims?
- Design: Is this the right approach for Claude Code's architecture?
- Security: Fail-safe behavior, injection prevention
- Compatibility: Works with Claude Code hook system

## Technical Design

### Proposed Quality Cycle Matrix Update

```markdown
### Primary Cycle for workflow-guard

**ALL workflow-guard work uses the Plugin recipe:**

| Recipe | Cycle | Focus Areas |
|--------|-------|-------------|
| **Plugin** | plugin-engineer → plugin-reviewer → plugin-tester | Logic, Design, Security, Compatibility |

### When to Use Plugin vs R1

| Artifact | Cycle | Reason |
|----------|-------|--------|
| hooks/*.sh | Plugin | Hook system integration |
| hooks/hooks.json | Plugin | Hook configuration |
| commands/*.md | Plugin | Slash command behavior |
| engine/*.go | Plugin | Dispatcher/CLI for hooks |
| engine/*.yaml | Plugin | Rule/condition definitions |
| DEVELOPER.md | Plugin | Plugin development guide |
| Generic utilities | R1 | No Claude Code integration |

### Plugin Recipe Focus Areas

**plugin-engineer (Creator):**
- Logic correctness - does it do what it claims?
- Design quality - right approach for Claude Code?
- Pattern adherence - follows established hook patterns?

**plugin-reviewer (Critic):**
- Security review - fail-safe, injection prevention
- Compatibility - works with Claude Code hook system
- Edge cases - handles malformed input gracefully

**plugin-tester (Expediter):**
- Integration test - works in real Claude Code environment
- Restart verification - changes take effect after restart
- Exit code semantics - 0/1/2 behave correctly
```

## References
- Previous work using wrong cycle: PR #3 (edit-confirmation-rules)
- Plugin recipe specification: qc-router/recipes/plugin.md

# Creator Section

## Implementation Notes

**Logic Review Findings:**
- CONFIRMED: ALL workflow-guard work should use Plugin recipe (not R1)
- Rationale: workflow-guard IS a Claude Code plugin - file extensions (.sh, .go) don't determine cycle, integration with Claude Code does
- Current DEVELOPER.md line 279 incorrectly suggested R1 for "any .go, .py, .sh" - this misses the point

**Design Review Findings:**
- CONFIRMED: plugin-engineer → plugin-reviewer → plugin-tester is correct cycle
- Focus areas align with real plugin needs:
  - plugin-engineer: Logic (does hook detect correctly?), Design (exit 2 vs 0?), Patterns (printf vs echo?)
  - plugin-reviewer: Security (injection?), Compatibility (malformed JSON?), Fail-safe (missing env vars?)
  - plugin-tester: Integration (actually blocks?), Restart (changes take effect?), Exit codes (semantics correct?)

**Pattern Review Findings:**
- CONFIRMED: Aligns with Claude Code plugin development patterns
- Hooks need fail-safe behavior (exit 0 if uncertain)
- Commands need correct frontmatter (description field required)
- Engine needs JSON input format compatibility
- All changes require Claude Code restart

## Questions/Concerns

**Concern Identified:**
- Current DEVELOPER.md buried plugin-engineer in Agent Selection table (line 374)
- Could cause confusion: developers might think R1 is default, Plugin is optional
- **Resolution**: Made Plugin recipe FIRST item with bold emphasis and "PRIMARY" designation

**No blocking concerns** - implementation is sound.

## Changes Made

**File changes:**
- `DEVELOPER.md` lines 271-385:
  - Rewrote "Contribution Workflow" section
  - Made Plugin recipe PRIMARY with bold emphasis
  - Added comprehensive "Plugin Resources" table with rationale
  - Documented plugin-engineer/reviewer/tester focus areas with examples
  - Moved other recipes to "when NOT plugin work" section
  - Updated Agent Selection table to emphasize Plugin for workflow-guard

**Acceptance Criteria Status:**
- [x] Plugin recipe listed as PRIMARY for workflow-guard (not just an option)
- [x] Clear definition of what constitutes "plugin resources" (table with examples)
- [x] plugin-engineer focus areas documented (logic, design, security, compatibility with examples)
- [x] Differentiation between R1 (generic code) vs Plugin (Claude Code plugins)
- [x] Examples of when to use Plugin vs R1 (comprehensive table)

**Commits:**
- `ba9556e` docs: establish Plugin recipe as primary for workflow-guard

**Status Update**: [2025-12-03 17:00] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None found. Documentation is technically accurate and secure.

### HIGH Issues
None found. Documentation correctly describes the Plugin recipe cycle and aligns with agent specifications.

### MEDIUM Issues

- [ ] `DEVELOPER.md:283-322` - Plugin Resources table could benefit from additional examples
  - **Analysis**: The table lists resource types (Hooks, Commands, Engine, Plugin Config, Developer Docs) with rationale, but could include more concrete examples of edge cases. For instance, what about test scripts? Integration test helpers? Documentation that's NOT about plugin patterns?
  - **Recommendation**: Consider adding a row for "Test scripts/fixtures" with guidance: "Use R1 if generic test infrastructure; use Plugin if testing hook behavior"

- [ ] `DEVELOPER.md:296-322` - Focus areas examples are hook-centric
  - **Analysis**: All the examples in the focus areas sections reference hooks (block-main-commits, exit codes, printf vs echo). While hooks are a primary plugin resource, the examples could include commands, skills, or agents for completeness.
  - **Recommendation**: Add one example per role that references a non-hook resource. E.g., for plugin-engineer: "Does handoff-debug command include all required frontmatter fields?"

## Approval Decision
APPROVED

## Rationale

This documentation accurately describes the Plugin recipe as PRIMARY for workflow-guard and correctly aligns with the qc-router agent specifications. Key strengths:

**Security Patterns Correct:**
- Fail-safe behavior documented (lines 306-307: "Does this handle malformed JSON gracefully?")
- Injection prevention emphasized (line 303: "Are we using `printf` instead of `echo` to prevent injection?")
- Safe defaults mentioned throughout

**Compatibility Verified:**
- Lines 289-293 correctly identify all Claude Code plugin integration points
- Hook exit codes referenced correctly (line 301, 318)
- JSON input format mentioned (line 309)
- Restart requirement documented (line 316)

**Agent Role Alignment:**
- plugin-engineer focus areas (296-303) match AGENT.md specification (logic, design, patterns)
- plugin-reviewer focus areas (305-312) match AGENT.md specification (security, compatibility, edge cases)
- plugin-tester focus areas (314-319) match AGENT.md specification (integration, restart verification, exit code semantics)

**Completeness:**
- All plugin resource types covered in table (lines 287-293)
- Clear differentiation from R1 recipe (lines 323-335)
- Examples show when to use Plugin vs other recipes

**No Contradictions:**
- Aligns with README.md hook descriptions
- Consistent with CLAUDE.md's quality cycle requirements
- Matches plugin-engineer/reviewer/tester AGENT.md specs

The MEDIUM issues are minor enhancements that would improve clarity but don't block approval. The core documentation is sound, secure, and actionable.

**Status Update**: [2025-12-03 17:15] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Documentation accuracy: [PASS/FAIL]
- Consistency with other docs: [PASS/FAIL]
- Actionable guidance: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-03 17:15] - plugin-reviewer
- Audit completed
- Decision: APPROVED
- No CRITICAL or HIGH issues found
- Two MEDIUM suggestions for future enhancement
- Documentation is secure, compatible, and complete

## [2025-12-03 16:30] - Coordinator
- Ticket created
- Identified that workflow-guard work was using wrong cycle (R1 instead of Plugin)
- Designed comprehensive Plugin recipe documentation
