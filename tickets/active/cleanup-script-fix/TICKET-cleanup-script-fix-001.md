---
# Metadata
ticket_id: TICKET-cleanup-script-fix-001
session_id: cleanup-script-fix
sequence: 001
parent_ticket: null
title: Fix variable capture bug in cleanup-merged-ticket.sh
cycle_type: development
status: expediter_review
claimed_by: ddoyle
claimed_at: 2025-12-07 21:49
created: 2025-12-07 23:39
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/cleanup-script-fix
---

# Requirements

## What Needs to Be Done
Fix the bug in `scripts/cleanup-merged-ticket.sh` where `find_worktree_path()` output includes log messages, causing the security path validation to fail.

**Bug Location:** `cleanup_worktree()` function, lines 145-149

**Current Code:**
```bash
if ! worktree_path=$(find_worktree_path "$branch"); then
    log_info "Skipping worktree removal - no worktree found"
    return 0
fi
```

**Problem:** `find_worktree_path()` uses `log_info` which writes to stdout via `tee`. The captured variable contains:
```
[2025-12-08 04:30:00] INFO: Looking for worktree for branch: ticket/docs-update
[2025-12-08 04:30:00] INFO: Found worktree: /home/user/.novacloud/worktrees/workflow-guard/docs-update
/home/user/.novacloud/worktrees/workflow-guard/docs-update
```

This causes the security check at line 157 to fail:
```bash
if [[ ! "$normalized_worktree" =~ ^${normalized_base}/ ]]; then
    log_error "Security check failed: worktree path is outside WORKTREE_BASE"
```

## Acceptance Criteria
- [ ] `find_worktree_path()` returns ONLY the path, not log messages
- [ ] Log messages still appear in the log file for debugging
- [ ] Security path validation works correctly
- [ ] Script successfully cleans up worktrees when run from outside the worktree
- [ ] Existing behavior preserved (verify PR merged, delete branches, etc.)

# Context

## Why This Work Matters
The cleanup script is a key part of the ticket lifecycle workflow. When it fails, users must perform manual cleanup, which is error-prone and time-consuming. This bug was discovered during the docs-update cleanup when running the script from inside the worktree being cleaned up.

## References
- Related tickets: TICKET-docs-update-001 (where bug was discovered)
- Related PRs: PR #9 (required manual cleanup due to this bug)
- Documentation: README.md - Ticket Lifecycle section

# Creator Section

## Implementation Notes
**Fix Applied:** Option 1 - Redirect log_info to stderr in find_worktree_path()

Modified the `find_worktree_path()` function to redirect all `log_info` calls to stderr using `>&2`. This ensures that:
1. Only the actual path is written to stdout (and captured in the variable)
2. Log messages still appear on the terminal for user visibility
3. Log messages still get written to the log file (via the `tee` in `log_info`)

**Changes Made:**
- Line 112: Added `>&2` to "Looking for worktree" log message
- Line 133: Added `>&2` to "No worktree found" log message
- Line 137: Added `>&2` to "Found worktree" log message

This is the cleanest solution as it maintains all existing logging behavior while ensuring that value-returning functions don't pollute their return values with log output.

## Questions/Concerns
- Should all `log_info` calls in value-returning functions use stderr?
  - **Decision:** Yes, this is a best practice. Functions that return values via stdout should send all diagnostic output to stderr.
- Consider adding integration test for cleanup script
  - **Deferred:** Out of scope for this bug fix. Can be addressed in future ticket.

## Changes Made
- **File changes:**
  - `scripts/cleanup-merged-ticket.sh` - Modified `find_worktree_path()` function (lines 112, 133, 137)
    - Added `>&2` redirection to all three `log_info` calls
    - Ensures only the path is returned via stdout, while log messages go to stderr
- **Commits:**
  - fix: redirect log_info to stderr in find_worktree_path()

**Status Update**: 2025-12-07 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None identified.

### HIGH Issues
None identified.

### MEDIUM Issues
None identified.

### Code Quality Notes

**Positive Findings:**
1. **Fix is correct and complete** - All three `log_info` calls in `find_worktree_path()` are properly redirected to stderr using `>&2`
2. **No similar issues found** - Audited all value-returning functions in the script:
   - `get_main_repo_root()` - Returns values from git commands only, no logging
   - `find_worktree_path()` - Fixed by this PR
   - Other functions (`verify_pr_merged`, `cleanup_*`) don't return values via stdout
3. **Proper redirection syntax** - The `>&2` suffix is the correct POSIX shell approach for redirecting a single command's output to stderr
4. **Log behavior preserved** - The `log_info` function still writes to both terminal and log file via `tee -a "$LOG_FILE"`, only the output stream changes from stdout to stderr for these specific calls
5. **Security maintained** - The fix enables the security check at line 157 to work correctly by ensuring `$worktree_path` contains only the actual path
6. **No regressions** - Shellcheck passes (one pre-existing warning about unused SCRIPT_DIR, unrelated to this change)

**Technical Correctness:**
- The `log_info` function uses `tee` without stderr redirection by default (line 21)
- Adding `>&2` after the function call redirects the entire function's output to stderr
- This is cleaner than modifying the `log_info` function itself, as it allows context-specific behavior
- The `echo "$worktree_path"` at line 138 correctly outputs only to stdout for variable capture

**Best Practices:**
This fix follows shell scripting best practices:
- Functions that return values via stdout should send all diagnostic output to stderr
- The `>&2` redirection is explicit and clear in intent
- No breaking changes to function signatures or calling patterns

## Approval Decision
**APPROVED**

## Rationale

The fix is correct, complete, and follows best practices for shell scripting. The bug was properly identified and the solution addresses the root cause without introducing side effects or regressions.

**Key validation points:**
1. All `log_info` calls in `find_worktree_path()` are redirected to stderr (lines 112, 133, 137)
2. The function's actual return value (`echo "$worktree_path"`) remains on stdout for proper capture
3. No other value-returning functions have similar issues
4. The fix enables the security path validation to work correctly
5. Logging behavior is preserved (messages still visible on terminal and in log file)
6. Shellcheck passes with no new warnings

The implementation matches the requirements and acceptance criteria documented in the ticket. The fix is minimal, focused, and solves the exact problem without over-engineering.

**Status Update**: 2025-12-07 - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: [To be filled]
- Linting: shellcheck [To be filled]
- Build: N/A (shell script)
- Manual testing: [To be filled]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[To be filled]

**Status Update**: [To be filled] - Changed status to `approved` or created rework ticket

# Changelog

## [2025-12-07 23:39] - Ticket Created
- Bug identified during TICKET-docs-update-001 cleanup
- Root cause analysis completed
- Fix options documented

## [2025-12-07 21:49] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/cleanup-script-fix
- Branch: ticket/cleanup-script-fix

## [2025-12-07 23:45] - Implementation Complete
- Modified `find_worktree_path()` to redirect log_info calls to stderr
- All three log_info calls now use `>&2` redirection
- Function now returns ONLY the path via stdout
- Log messages still visible on terminal and written to log file
- Security path validation will now work correctly
- Status changed to `critic_review`

## [2025-12-07 23:52] - Critic Review Complete
- Audited all changes and verified fix correctness
- Confirmed all `log_info` calls in `find_worktree_path()` are properly redirected
- Verified no similar issues exist in other value-returning functions
- Shellcheck validation passed (one pre-existing unrelated warning)
- No critical, high, or medium issues identified
- Fix follows shell scripting best practices
- Security validation logic now works correctly
- **Decision: APPROVED**
- Status changed to `expediter_review`
