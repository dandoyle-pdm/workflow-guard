---
# Metadata
ticket_id: TICKET-quality-cycle-completion-enforcement
session_id: quality-cycle-completion-enforcement
sequence: null
parent_ticket: null
title: Enforce quality cycle completion before ticket completion
cycle_type: development
status: open
created: 2025-12-13 10:30
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PreToolUse hook that intercepts `complete-ticket.sh` commands and validates that the Creator/Critic/Expediter sections are filled before allowing ticket completion.

The hook should:
1. Detect `complete-ticket.sh` commands in Bash tool invocations
2. Find the active ticket for the current worktree/branch
3. Validate that for development/documentation cycle types:
   - Creator Section has implementation content (not template placeholder)
   - Critic Section has review findings and approval decision
   - Expediter Section has validation results and quality gate decision
4. Block completion with helpful error message if sections are missing
5. Allow completion if all sections are properly filled

## Acceptance Criteria
- [ ] Hook created at `hooks/enforce-quality-cycle-completion.sh`
- [ ] Hook registered in `hooks.json` under PreToolUse Bash matcher
- [ ] Hook blocks completion when Creator Section is empty/template
- [ ] Hook blocks completion when Critic Section lacks approval decision
- [ ] Hook blocks completion when Expediter Section lacks quality gate decision
- [ ] Hook allows completion when all sections are properly filled
- [ ] Hook skips validation for non-development/documentation cycle types
- [ ] Error message clearly indicates which sections are missing
- [ ] Error message provides remediation steps (which agents to invoke)

# Context

## Why This Work Matters

The golang-hooks ticket (qc-router) was marked "completed" without going through code-reviewer or code-tester. The Creator/Critic/Expediter sections were left as template placeholders. This breaks the quality cycle enforcement.

Root cause: The `complete-ticket.sh` script and existing hooks validate ticket location and format, but do NOT validate that quality cycle sections are filled. There's no gate preventing a ticket from being completed without proper review.

This hook closes that enforcement gap by validating section content before allowing completion.

## References
- Existing pattern: `hooks/enforce-ticket-completion.sh` (validates ticket location before PR)
- Ticket template: `tickets/TEMPLATE.md` (defines section structure)
- Complete script: `scripts/complete-ticket.sh` (what to intercept)
- hooks.json: PreToolUse Bash matcher (where to register)

# Creator Section

## Implementation Notes
_To be filled during implementation_

## Questions/Concerns
_To be filled during implementation_

## Changes Made
- File changes:
- Commits:

**Status Update**: _Pending_

# Critic Section

## Audit Findings

### CRITICAL Issues
_To be filled during review_

### HIGH Issues
_To be filled during review_

### MEDIUM Issues
_To be filled during review_

## Approval Decision
_To be filled during review_

## Rationale
_To be filled during review_

**Status Update**: _Pending_

# Expediter Section

## Validation Results
_To be filled during validation_

## Quality Gate Decision
_To be filled during validation_

## Next Steps
_To be filled during validation_

**Status Update**: _Pending_

# Changelog

## [2025-12-13 10:30] - Creator: created
- Ticket created in queue/
- Requirements defined based on root cause analysis of golang-hooks quality cycle bypass
