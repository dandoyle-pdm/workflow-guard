---
# Metadata
ticket_id: TICKET-main-thread-read-blocking
session_id: main-thread-read-blocking
sequence: null
parent_ticket: null
title: Fix main-thread-read-blocking hook to display block messages
cycle_type: development
status: open
created: 2025-12-11 22:44
worktree_path: null
---

# Requirements

## What Needs to Be Done
The `block-main-thread-reads.sh` hook is currently registered and executing for Read/Glob/Grep tool calls, but block messages are not being displayed to users. Investigation has confirmed:

1. Hook IS registered in `hooks.json` for Read|Glob|Grep tools
2. Hook IS executing - logs show "AUDIT: Blocked Read without agent context"
3. Hook IS exiting with code 2 (block)
4. But Claude Code isn't displaying the block message to users

**Root Cause**: The `block-main-thread-reads.sh` script is missing the fallback transcript discovery logic that exists in `block-unreviewed-edits.sh` (lines 366-400). When `transcript_path="/dev/null"` or is invalid, the `block-unreviewed-edits.sh` hook successfully finds the real transcript file, but `block-main-thread-reads.sh` does not have this capability.

**Fix Required**: Add the fallback transcript discovery logic from `block-unreviewed-edits.sh` (lines 366-400) to `block-main-thread-reads.sh` so it can properly locate the transcript file and write block messages that Claude Code will display.

## Acceptance Criteria
- [ ] `block-main-thread-reads.sh` includes fallback transcript discovery logic
- [ ] Main thread Read operations are blocked with visible message to user
- [ ] Main thread Glob operations are blocked with visible message to user
- [ ] Main thread Grep operations are blocked with visible message to user
- [ ] Block messages clearly instruct users to use Task tool with Explore subagent
- [ ] Hook continues to log audit trails for blocked operations
- [ ] No false positives (subagent Read/Glob/Grep operations are not blocked)

# Context

## Why This Work Matters
The main-thread-read-blocking enforcement is a critical quality mechanism to ensure:
- Investigation work happens in isolated subagent contexts
- Main thread remains clean for coordination only
- Proper separation of concerns between coordinator and worker agents

Without visible block messages, users don't receive feedback about why their operations aren't executing, leading to confusion and potential workarounds.

## References
- Related files:
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-main-thread-reads.sh` (needs fix)
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-unreviewed-edits.sh` (lines 366-400 contain reference implementation)
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks.json` (hook registration)
- Investigation findings: Hook registered and executing but messages not displayed
- Root cause: Missing fallback transcript discovery when transcript_path is invalid

# Creator Section

## Implementation Notes
[To be filled by Creator]

## Questions/Concerns
[To be filled by Creator]

## Changes Made
[To be filled by Creator]

# Critic Section

## Audit Findings
[To be filled by Critic]

## Approval Decision
[To be filled by Critic]

## Rationale
[To be filled by Critic]

# Expediter Section

## Validation Results
[To be filled by Expediter]

## Quality Gate Decision
[To be filled by Expediter]

## Next Steps
[To be filled by Expediter]

# Changelog

## [2025-12-11 22:44] - Creator: created
- Ticket created in queue/
- Requirements defined based on investigation findings
- Root cause identified: missing fallback transcript discovery logic
- Fix scoped: port lines 366-400 from block-unreviewed-edits.sh
