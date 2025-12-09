---
# Metadata
ticket_id: TICKET-commit-detection-gap-001
session_id: commit-detection-gap
sequence: 001
parent_ticket: null
title: Add protected branch commit detection and observer logging
cycle_type: development
status: in_progress
claimed_by: ddoyle
claimed_at: 2025-12-08 21:33
created: 2025-12-08 23:32
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/commit-detection-gap
---

# Requirements

## What Needs to Be Done
Address the gap where commits to protected branches bypass hook detection. Three complementary fixes:

**A. Add observer to block-main-commits.sh (minor)**
- Call `observe-violation.sh` when hook blocks a commit
- Ensures violations are logged for edge cases where hook fires

**B. Add PostToolUse detection hook (new feature)**
- Create hook that runs AFTER `git commit` completes
- Detects commits that landed on protected branches
- Logs violation observation after-the-fact
- Comprehensive detection for allowlisted command bypass

**C. Document limitation in README**
- Explain why allowlisted commands bypass PreToolUse hooks
- Document the workaround (PostToolUse detection)
- Provide guidance for users

## Acceptance Criteria
- [ ] `block-main-commits.sh` calls `observe-violation.sh` with `"type": "workflow-guard"`
- [ ] New PostToolUse hook `detect-protected-commits.sh` exists
- [ ] PostToolUse hook detects commits on main/master/production
- [ ] PostToolUse hook logs violation with appropriate schema
- [ ] `hooks.json` updated with PostToolUse hook configuration
- [ ] README.md documents the allowlist limitation
- [ ] README.md explains PostToolUse detection approach
- [ ] All hooks tested in real git environment

# Context

## Why This Work Matters
Currently, `git commit` is in Claude Code's allowlist, meaning PreToolUse hooks never evaluate it. This creates a gap where commits to protected branches go completely undetected by workflow-guard. The observer system was designed to track violations, but this gap means critical violations aren't being captured.

## References
- Related commits: 854b989 (type field), 7cf686f (engine wired up)
- Related files: `hooks/block-main-commits.sh`, `hooks/observe-violation.sh`
- Hook types: PreToolUse (current), PostToolUse (needed)

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
- PostToolUse receives different JSON schema than PreToolUse - need to verify fields available
- Should PostToolUse detection be a warning vs blocking? (detection only, can't prevent)

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

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
- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [PASS/FAIL]
- Security scans: [PASS/FAIL]
- Build: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-08 23:32] - Coordinator
- Ticket created from session handoff
- Identified three-part solution (A, B, C)

## [2025-12-08 21:33] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/commit-detection-gap
- Branch: ticket/commit-detection-gap
