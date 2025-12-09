---
# Metadata
ticket_id: TICKET-commit-detection-gap-001
session_id: commit-detection-gap
sequence: 001
parent_ticket: null
title: Add protected branch commit detection and observer logging
cycle_type: development
status: critic_review
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
- [x] `block-main-commits.sh` calls `observe-violation.sh` with `"type": "workflow-guard"`
- [x] New PostToolUse hook `detect-protected-commits.sh` exists
- [x] PostToolUse hook detects commits on main/master/production
- [x] PostToolUse hook logs violation with appropriate schema
- [x] `hooks.json` updated with PostToolUse hook configuration
- [x] README.md documents the allowlist limitation
- [x] README.md explains PostToolUse detection approach
- [x] All hooks tested in real git environment

# Context

## Why This Work Matters
Currently, `git commit` is in Claude Code's allowlist, meaning PreToolUse hooks never evaluate it. This creates a gap where commits to protected branches go completely undetected by workflow-guard. The observer system was designed to track violations, but this gap means critical violations aren't being captured.

## References
- Related commits: 854b989 (type field), 7cf686f (engine wired up)
- Related files: `hooks/block-main-commits.sh`, `hooks/observe-violation.sh`
- Hook types: PreToolUse (current), PostToolUse (needed)

# Creator Section

## Implementation Notes

Implemented all three parts successfully:

**Part A: Observer Integration in block-main-commits.sh**
- Added observer call after line 250 (blocking logic)
- Uses jq to safely construct JSON with type=workflow-guard
- Logs violation with CRITICAL severity
- Includes context: branch, protected_branches list
- Fail-safe: observer errors don't break blocking behavior

**Part B: PostToolUse Hook - detect-protected-commits.sh**
- Created new 299-line hook script
- Runs on PostToolUse event (after git commit completes)
- Detects current branch and checks against protected list
- Includes ticket lifecycle exception (same as PreToolUse hook)
- Logs violations with type=workflow-guard, severity=HIGH
- Shows warning message to user (non-blocking)
- Detection-only approach (commit already happened)

**Part C: Documentation**
- Updated hook count description in README.md
- Added Important Limitation section to block-main-commits
- Created comprehensive detect-protected-commits section
- Documented allowlist implications with example workflow
- Explained two-layer defense strategy

**Testing:**
- Bash syntax validation: PASS
- JSON syntax validation: PASS
- Feature branch detection: PASS (allows commits)
- Protected branch detection: PASS (shows error message)
- Observer integration: PASS (violation logged with correct schema)

## Questions/Concerns - RESOLVED
- ✓ PostToolUse receives same JSON schema as PreToolUse (verified)
- ✓ PostToolUse is detection-only (cannot block, commit already completed)

## Changes Made
- File changes:
  - hooks/block-main-commits.sh (27 lines added)
  - hooks/detect-protected-commits.sh (299 lines, new file)
  - hooks/hooks.json (12 lines added - PostToolUse section)
  - README.md (45 lines added, 3 modified)
  - tickets/active/commit-detection-gap/TICKET-commit-detection-gap-001.md (this file)

- Commits:
  - c0fc9cd: feat: add observer logging to block-main-commits hook
  - 9856565: feat: add PostToolUse hook to detect protected branch commits
  - 40c7ad7: feat: register PostToolUse hook for commit detection
  - 3510eaf: docs: document allowlist limitation and PostToolUse detection

**Status Update**: 2025-12-08 21:45 - Changed status to `critic_review`

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

## [2025-12-08 21:45] - plugin-engineer
- Implemented all three parts (A, B, C) successfully
- Added observer logging to block-main-commits.sh (Part A)
- Created detect-protected-commits.sh PostToolUse hook (Part B)
- Updated hooks.json with PostToolUse section
- Documented allowlist limitation in README.md (Part C)
- All acceptance criteria met and tested
- Status changed to critic_review

## [2025-12-08 23:32] - Coordinator
- Ticket created from session handoff
- Identified three-part solution (A, B, C)

## [2025-12-08 21:33] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/commit-detection-gap
- Branch: ticket/commit-detection-gap
