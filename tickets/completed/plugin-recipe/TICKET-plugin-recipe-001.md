---
# Metadata
ticket_id: TICKET-plugin-recipe-001
session_id: plugin-recipe
sequence: 001
parent_ticket: null
title: Add Plugin recipe as primary quality cycle for workflow-guard
cycle_type: documentation
status: approved
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

### 1. Documentation Accuracy - PASS
- [x] Plugin recipe matches plugin-engineer/reviewer/tester cycle
- [x] Agent names are correct (plugin-engineer, plugin-reviewer, plugin-tester)
- [x] Focus areas align with actual agent capabilities
- [x] All plugin resources properly categorized (hooks, commands, engine, config, docs)
- [x] Examples are specific and actionable

### 2. Cross-Document Consistency - FAIL (minor)
**Issue Found**: CLAUDE.md still references old cycles:
- Line 59: "R1 (code-developer → code-reviewer → code-tester) for hook changes"
- Should be: "Plugin (plugin-engineer → plugin-reviewer → plugin-tester) for hook changes"
- Line 60: "R2 (tech-writer → tech-editor → tech-publisher) for commands 100+ lines"
- Should be: "Plugin (plugin-engineer → plugin-reviewer → plugin-tester) for commands"
- Line 61: "R5 (single reviewer) for minor config changes"
- Should clarify: Most config changes ARE plugin work (hooks.json, plugin.json)

**Impact**: Moderate - CLAUDE.md is the project instructions file that Claude reads first. Inconsistency could lead to using wrong cycle.

**Other Consistency Checks**:
- [x] README.md: No quality cycle references (appropriate for user docs)
- [x] DEVELOPER.md: Correctly updated with Plugin recipe as PRIMARY
- [x] Handoff commands: All reference Plugin recipe correctly

### 3. Actionable Guidance - PASS
- [x] Developer can determine which recipe to use (clear PRIMARY designation)
- [x] Examples help clarify when to use Plugin vs R1 (lines 283-293, 323-335)
- [x] Agent selection is clear (line 371-382)
- [x] Focus areas are specific with concrete examples (lines 296-319)

### 4. Completeness vs Acceptance Criteria - PASS
- [x] Plugin recipe listed as PRIMARY for workflow-guard (line 273, 277)
- [x] Clear definition of what constitutes "plugin resources" (table lines 283-293)
- [x] plugin-engineer focus areas documented with examples (lines 296-303)
- [x] Differentiation between R1 vs Plugin clearly explained (lines 323-335)
- [x] Examples of when to use Plugin vs R1 (comprehensive table lines 287-293)

## Quality Gate Decision
CREATE_REWORK_TICKET

## Rationale

The DEVELOPER.md changes are **excellent** - comprehensive, clear, and actionable. However, CLAUDE.md has a critical inconsistency that could lead to developers using the wrong cycle.

**Why This Matters:**
- CLAUDE.md is the project instructions file that Claude reads at session start
- Inconsistent guidance between CLAUDE.md and DEVELOPER.md creates confusion
- CLAUDE.md line 59 explicitly says "R1 for hook changes" which contradicts DEVELOPER.md's "Plugin recipe PRIMARY"

**Why Not Just Approve:**
- This is a CONSISTENCY issue, not a DOCUMENTATION issue
- The documentation itself (DEVELOPER.md) is perfect
- But the project instructions (CLAUDE.md) don't match
- Future developers might see CLAUDE.md first and use wrong cycle

**Recommendation:**
Create a small rework ticket to align CLAUDE.md with DEVELOPER.md's Plugin recipe guidance. This can be done quickly by plugin-engineer or even as a fast-path fix.

## Next Steps

1. Create TICKET-plugin-recipe-002.md to align CLAUDE.md with Plugin recipe
2. Update CLAUDE.md lines 59-61 to reference Plugin recipe instead of R1/R2/R5
3. Clarify that "quality cycles" in CLAUDE.md means Plugin recipe for workflow-guard
4. After CLAUDE.md is aligned, return to approve this ticket

**Suggested Rework Ticket Scope:**
```markdown
# TICKET-plugin-recipe-002

Update CLAUDE.md to align with DEVELOPER.md's Plugin recipe guidance.

**Changes Needed:**
- Line 59: Change "R1 (code-developer → code-reviewer → code-tester) for hook changes" to "Plugin (plugin-engineer → plugin-reviewer → plugin-tester) for all plugin resources"
- Lines 60-61: Update to reference Plugin recipe or clarify exceptions
- Ensure consistency with DEVELOPER.md lines 273-335
```

**Alternative - Approve Now with Caveat:**
If you want to approve this ticket and handle CLAUDE.md separately, that's also reasonable. The documentation work (DEVELOPER.md) is complete and correct. The inconsistency is in a different file.

**Status Update**: [2025-12-03 17:30] - Changed status to `rework_requested`

# Changelog

## [2025-12-03 17:30] - plugin-tester
- Validation completed
- Decision: CREATE_REWORK_TICKET
- Found inconsistency in CLAUDE.md (still references R1/R2/R5 instead of Plugin recipe)
- DEVELOPER.md changes are excellent and complete
- Recommended creating TICKET-plugin-recipe-002 to align CLAUDE.md

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
