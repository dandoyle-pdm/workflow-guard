---
# Metadata
ticket_id: TICKET-activate-fix-001
session_id: activate-fix
sequence: 001
parent_ticket: null
title: Fix activate-ticket.sh to use session-id for branch/worktree naming
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-07 11:50
created: 2025-12-07 11:45
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/activate-fix
---

# Requirements

## What Needs to Be Done

### Part 1: Fix activate-ticket.sh

Fix `scripts/activate-ticket.sh` to use session-id (not full ticket name) for:
1. Branch naming: `ticket/{session-id}` not `ticket/TICKET-{session-id}-{sequence}`
2. Worktree directory: `worktrees/{project}/{session-id}/`
3. Active ticket directory: `tickets/active/{session-id}/`

Currently line 222 does:
```bash
local branch_name="ticket/${ticket_id}"  # Wrong: ticket/TICKET-quality-gate-001
```

Should extract session-id and use:
```bash
local branch_name="ticket/${session_id}"  # Correct: ticket/quality-gate
```

### Part 2: Add Validation Hook

Create `hooks/validate-ticket-naming.sh` to enforce naming conventions:
1. Trigger on: Write tool when path contains `tickets/`
2. Validate ticket filename: `^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$`
3. Validate directory uses session-id not full ticket name
4. Block with helpful error if validation fails

### Part 3: Fix complete-ticket.sh Worktree Detection Bug

The `is_worktree()` function uses `--git-common-dir` which returns parent .git, not worktree .git.
Should use `--git-dir` instead to correctly detect worktree context.

## Acceptance Criteria

### Script Fixes
- [ ] Extract session-id from ticket metadata (preferred) or filename
- [ ] Branch created as `ticket/{session-id}`
- [ ] Worktree directory uses session-id
- [ ] Active directory uses session-id: `tickets/active/{session-id}/`
- [ ] Multiple tickets with same session-id can coexist (001, 002, etc.)
- [ ] Fix complete-ticket.sh `is_worktree()` to use `--git-dir`

### Validation Hook
- [ ] Create `hooks/validate-ticket-naming.sh`
- [ ] Register in `hooks/hooks.json` for Write tool on tickets/ paths
- [ ] Validate filename pattern enforces lowercase, hyphens, 3-digit sequence
- [ ] Validate directory naming uses session-id
- [ ] Block invalid names with clear error message

### Testing
- [ ] Test activate-ticket.sh creates correct branch/worktree names
- [ ] Test validation hook blocks bad ticket names
- [ ] Test validation hook allows good ticket names
- [ ] Test complete-ticket.sh works in worktree

# Context

## Why This Work Matters

The current implementation couples branch/directory names to full ticket IDs, causing:
1. Redundant naming: `TICKET-quality-gate-001` repeated in paths
2. Inconsistency with completed tickets which use session-id directories
3. Inability to have multiple sequential tickets on same branch

Completed tickets already use correct pattern:
- `tickets/completed/declarative-engine/TICKET-declarative-engine-001.md`
- `tickets/completed/quality-gate/TICKET-quality-gate-001.md`

## References
- Bug discovered during: TICKET-quality-gate-001 activation
- Related scripts: activate-ticket.sh, complete-ticket.sh
- Pattern reference: tickets/completed/*/

# Creator Section

## Implementation Notes

### Part 1: activate-ticket.sh Session-ID Extraction
- Modified `main()` function to extract session-id from ticket metadata
- Primary method: Read `session_id:` field from ticket YAML frontmatter
- Fallback method: Parse from filename using pattern `TICKET-{session-id}-{sequence}`
- Branch name now uses: `ticket/{session-id}` instead of `ticket/{full-ticket-id}`
- Worktree directory now uses: `{project}/{session-id}` instead of `{project}/{full-ticket-id}`
- Active directory now uses: `tickets/active/{session-id}/` instead of `tickets/active/{full-ticket-id}/`
- Added logging for session_id to help with debugging

### Part 2: validate-ticket-naming.sh Hook
- Created PreToolUse hook that triggers on Write tool for files in `tickets/` directory
- Validates filename pattern: `^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$`
- Enforces lowercase-with-hyphens for session-id (no uppercase, no underscores)
- Enforces exactly 3-digit sequence number
- Validates directory naming matches session-id extracted from filename
- Blocks invalid names with comprehensive error messages showing examples
- Security hardened following patterns from existing hooks
- Registered in hooks/hooks.json with Write tool matcher

### Part 3: complete-ticket.sh Worktree Detection Fix
- Changed `is_worktree()` from using `--git-common-dir` to `--git-dir`
- `--git-common-dir` returns the parent .git directory, not the worktree .git
- `--git-dir` correctly identifies worktree-specific git directory
- Fix prevents false negatives when running script from worktree

## Questions/Concerns

None. All three parts implemented as specified.

## Changes Made

### File Changes
- `scripts/activate-ticket.sh` - Added session-id extraction logic
- `scripts/complete-ticket.sh` - Fixed is_worktree() detection
- `hooks/validate-ticket-naming.sh` - New validation hook (261 lines)
- `hooks/hooks.json` - Registered new hook

### Commits
- 9620a90: fix: extract session-id from ticket for branch/worktree naming
- 3496fb2: feat: add validate-ticket-naming.sh PreToolUse hook
- a8fa0a6: feat: register validate-ticket-naming hook in hooks.json
- 80a89a4: fix: correct is_worktree() detection in complete-ticket.sh

**Status Update**: 2025-12-07 12:15 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] `file:line` - Issue description and fix required

### HIGH Issues
- [ ] `file:line` - Issue description and fix required

### MEDIUM Issues
- [ ] `file:line` - Suggestion for improvement

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Script syntax valid: [PASS/FAIL]
- Branch naming correct: [PASS/FAIL]
- Worktree naming correct: [PASS/FAIL]
- Directory naming correct: [PASS/FAIL]
- Existing tickets unaffected: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-07 11:45] - Ticket Created
- Defined requirements for fixing branch/worktree naming
- Session-id should be used instead of full ticket ID
