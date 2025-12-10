---
# Metadata
ticket_id: TICKET-executor-exit-code-fix
session_id: executor-exit-code-fix
sequence: null
parent_ticket: null
title: Fix executor.go to use correct Claude Code hook exit code semantics
cycle_type: development
status: open
created: 2025-12-10 01:59
worktree_path: null
---

# Requirements

## What Needs to Be Done

The declarative engine's executor.go uses incorrect exit code semantics that silently defeat ALL structured hook decisions (allow/deny/ask).

**Current WRONG behavior:**
```go
case "allow": resp.ExitCode = 0  // Correct for simple allow
case "ask":   resp.ExitCode = 1  // WRONG - exit 1 = non-blocking, execution continues
case "deny":  resp.ExitCode = 2  // WRONG - exit 2 ignores JSON, only uses stderr
```

**Official Claude Code Spec (from https://code.claude.com/docs/en/hooks.md):**
- Exit 0 + JSON stdout → Structured decisions parsed (`permissionDecision: allow|deny|ask`)
- Exit 2 + stderr → Hard block, **JSON is IGNORED**
- Exit 1 (or other) → Non-blocking error, **execution continues**

**Required Fix:**
ALL structured decisions must use exit 0 + JSON with official format:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "message here"
  }
}
```

## Acceptance Criteria
- [ ] executor.go outputs exit 0 for ALL structured decisions (allow/deny/ask)
- [ ] JSON output follows official `hookSpecificOutput` format
- [ ] `permissionDecision` field uses correct values: "allow", "deny", "ask"
- [ ] `permissionDecisionReason` contains the message
- [ ] dispatcher binary rebuilt with `make build`
- [ ] hookctl binary rebuilt with `make build`
- [ ] Test: `echo '{"tool_name":"Bash","tool_input":{"command":"cat > test.sh"}}' | ./dispatcher` returns exit 0 + deny JSON
- [ ] Test: Bash heredoc write is actually blocked (not just logged)
- [ ] README.md/DEVELOPER.md updated to document correct exit code semantics

# Context

## Why This Work Matters

This bug silently defeats the ENTIRE Bash file-write blocking system:
- Rules evaluate correctly
- Conditions match correctly
- Decisions are computed correctly
- **But wrong exit codes cause Claude Code to ignore everything**

All the work in TICKET-declarative-engine-001 and TICKET-edit-confirmation-001 is rendered useless by this single bug.

## Root Cause

Commit `7cf686f` introduced the bug with message: "Fixes exit code for 'ask' decisions (0 → 1) per Claude Code spec"

This was based on an incorrect assumption about Claude Code's spec. The actual spec was never verified - it was assumed.

## References
- Official spec: https://code.claude.com/docs/en/hooks.md
- Bug location: `engine/internal/actions/executor.go` lines 62-83
- Related: TICKET-declarative-engine-001, TICKET-edit-confirmation-001

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
- Should we also fix the bash hooks (confirm-code-edits.sh, block-unreviewed-edits.sh) that use exit 1/2?
- Or will the dispatcher handle everything going forward?

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

## [2025-12-10 01:59] - Coordinator
- Ticket created after investigation revealed exit code bug
- Bug found via subagent investigation comparing executor.go against official Claude Code spec
- Root cause: assumption about spec without verification (commit 7cf686f)
