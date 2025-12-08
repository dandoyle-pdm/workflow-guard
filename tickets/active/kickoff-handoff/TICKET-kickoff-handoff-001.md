---
# Metadata
ticket_id: TICKET-kickoff-handoff-001
session_id: kickoff-handoff
sequence: 001
parent_ticket: TICKET-kickoff-cmd-001
title: Make /kickoff handoff-aware for seamless session continuity
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-07 23:30
created: 2025-12-08 01:28
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff
---

# Requirements

## What Needs to Be Done

Enhance `commands/kickoff.md` to recognize and parse handoff prompt structure, enabling seamless session continuity.

**Current state:** Kickoff takes `$ARGUMENTS` as generic input
**Desired state:** Kickoff detects handoff structure and extracts actionable context

## Acceptance Criteria
- [x] Detects handoff prompt structure (has "Session Type:", "Next Steps:", etc.)
- [x] Extracts session type → maps to quality chain
- [x] Extracts ticket reference → continues existing or creates new
- [x] Extracts next steps → immediate actions for agent
- [x] Passes full context to delegated agent
- [x] Falls back to generic analysis if not a handoff
- [x] Stays under 50 lines (37 substantive lines)

# Context

## Why This Work Matters

We control both artifacts:
- **Handoff output** (commands/handoff*.md) - what gets generated
- **Kickoff input** (commands/kickoff.md) - what gets consumed

Making them speak to each other enables true session continuity:
1. `/handoff` generates structured prompt with mental model
2. New session: `/kickoff <paste handoff>` resumes intelligently

## Handoff Structure to Detect

```markdown
## Session Type: {DEBUG|DEVELOPMENT|HOTFIX|INVESTIGATE}
## Next Steps
- Step 1
- Step 2
## Ticket Reference: TICKET-xxx-001 (if exists)
## Current Understanding
...context...
```

## Session Type → Quality Chain Mapping

| Session Type | Quality Chain | Starting Agent |
|--------------|---------------|----------------|
| DEBUG | R1 | code-tester |
| DEVELOPMENT | R1 | code-developer |
| HOTFIX | R5 | code-developer |
| INVESTIGATE | R4 | - (fast path) |

# Creator Section

## Implementation Notes

Added "Handoff Detection" section to kickoff.md with:
- **Detection markers**: Checks for "Session Type:", "Next Steps:", "TICKET-" references, "Current Understanding:"
- **Session type mapping**: DEBUG→R1(code-tester), DEVELOPMENT→R1(code-developer), HOTFIX→R5(code-developer), INVESTIGATE→R4(explore)
- **Context extraction**: Ticket ref, next steps, full context for agent delegation
- **Fallback behavior**: If no handoff detected, use generic work type analysis

The enhancement is compact (added ~12 substantive lines) and maintains single responsibility. Updated Process section to reflect handoff-aware analysis.

## Changes Made
- File changes: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff/commands/kickoff.md
  - Added "Handoff Detection" section (lines 11-25)
  - Updated "Process" section to include handoff path (lines 27-33)
- Total substantive lines: ~37 (well under 50 line limit)
- Commits: 48c3b4e - feat: add handoff detection to /kickoff command

# Critic Section

## Audit Findings

### Correctness Issues

1. **Session Type Mismatch (CRITICAL)**
   - kickoff.md maps: DEBUG, DEVELOPMENT, HOTFIX, INVESTIGATE
   - handoff commands output: DEBUGGING, DEVELOPMENT, EMERGENCY HOTFIX, INVESTIGATION
   - **Issue:** "DEBUG" won't match "DEBUGGING", "HOTFIX" won't match "EMERGENCY HOTFIX"
   - **Impact:** Handoff detection will fail for debug and hotfix sessions
   - **Fix Required:** Align session type strings between handoff output and kickoff parsing

2. **Invalid Agent Reference**
   - Line 21 maps INVESTIGATE→R4(explore)
   - Quality Recipes table (line 42) shows R4 as "None" with no agent
   - **Issue:** "explore" is not a defined agent
   - **Impact:** Unclear what agent to invoke for INVESTIGATE sessions
   - **Fix Required:** Correct R4 mapping or define "explore" agent

3. **Detection Logic Ambiguity**
   - Lines 13-17 list detection markers but don't specify threshold
   - **Issue:** Does detection require ALL markers or just ONE?
   - **Impact:** Unclear when handoff path is triggered vs generic path
   - **Fix Required:** Specify detection criteria (e.g., "If 2+ markers present")

### Completeness - PARTIAL

- All four session types are covered in mapping
- Extraction steps are comprehensive (type, ticket, next steps, context)
- Fallback to generic analysis is mentioned but not detailed

### Clarity Issues

1. **Dual-Path Not Explicit**
   - Handoff path is documented (lines 19-25)
   - Generic path is only referenced in line 29 "OR generic work type"
   - **Issue:** No explicit "else" branch explaining generic analysis
   - **Fix Recommended:** Add explicit fallback logic documentation

2. **Vague Context Passing**
   - Line 24: "Pass full context to delegated agent"
   - **Issue:** What constitutes "full context"?
   - **Fix Recommended:** Specify which sections to pass (Current Understanding, Changes Made, etc.)

### Line Limit - COMPLIANT

- Counted 29 substantive lines (excludes empty, headers, table formatting)
- Well under 50 line limit
- **Status:** PASS

### Consistency - GOOD

- Maintains 5-step process structure from original kickoff.md
- Preserves "Use ultrathink" instruction
- Follows command pattern: Description → Input → Logic → Process → Recipes → Rules
- Quality Recipes table unchanged (maintains compatibility)
- **Status:** PASS

## Approval Decision

**NEEDS_CHANGES**

### Required Fixes

1. **Session Type Alignment:** Change mapping to match handoff output exactly
   - DEBUG → DEBUGGING
   - HOTFIX → EMERGENCY HOTFIX (or strip "EMERGENCY" from handoff output)

2. **R4 Agent Clarification:** Either:
   - Remove "(explore)" and keep as "None" (read-only, no agent)
   - OR define what "explore" means

3. **Detection Threshold:** Specify how many markers constitute a handoff

### Recommended Improvements

1. Document generic fallback path explicitly
2. Specify what "full context" means in agent delegation

# Expediter Section

## Validation Results
[To be filled during validation]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

# Changelog

## [2025-12-08 01:28] - Ticket Created
- Enhancement to existing /kickoff command
- Parent: TICKET-kickoff-cmd-001

## [2025-12-08 01:35] - Implementation Complete
- Added handoff detection to kickoff.md
- Status updated to critic_review
- Commit: 48c3b4e

## [2025-12-07 23:30] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/kickoff-handoff
- Branch: ticket/kickoff-handoff

## [2025-12-08 01:45] - Rework: Fixed Handoff Detection Issues
- **Session Type Mismatch:** Changed DEBUG→DEBUGGING, HOTFIX→EMERGENCY HOTFIX to match handoff output
- **Invalid Agent Reference:** Clarified INVESTIGATION→R4(fast-path, no agent) instead of "(explore)"
- **Detection Threshold:** Specified explicit threshold "2+ markers present"
- Status: ready for re-review
