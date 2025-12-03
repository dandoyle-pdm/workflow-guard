---
# Metadata
ticket_id: TICKET-confirm-edits-001
session_id: confirm-edits
sequence: 001
parent_ticket: null
title: Add mandatory code edit confirmation hook
cycle_type: development
status: expediter_review
created: 2025-12-03 12:00
worktree_path: null
---

# Requirements

## What Needs to Be Done
Add a PreToolUse hook to workflow-guard that intercepts Edit and Write tool calls targeting code files and blocks them with a confirmation message, requiring the user to explicitly approve before Claude proceeds.

**Problem:** Claude makes code edits without being explicitly asked. This happens during testing sessions where the correct behavior is to REPORT failures, not FIX them. Verbal instructions are ignored - mechanical enforcement is needed.

**Files to Create/Modify:**
1. NEW: `hooks/confirm-code-edits.sh` - The confirmation hook script
2. MODIFY: `hooks/hooks.json` - Add matcher for Edit|Write tools

## Acceptance Criteria
- [x] Hook matches Edit and Write tools via hooks.json
- [x] Hook blocks code files: *.go, *.py, *.sh, *.js, *.ts, *.tsx, *.jsx
- [x] Hook outputs blocking message to stderr with file path
- [x] Hook exits 1 (block with message visible to Claude)
- [x] Exclusion: Files in tickets/ directory are allowed
- [x] Exclusion: Test files (*_test.go, test_*.py, *.test.js, *.spec.ts, etc.) are allowed
- [x] Exclusion: SKIP_EDIT_CONFIRMATION=true env var bypasses hook
- [x] Extension list configurable via CODE_FILE_EXTENSIONS env var
- [x] Follows security patterns from block-mcp-git-commits.sh
- [x] Logs to ~/.claude/logs/hooks-debug.log

# Context

## Why This Work Matters
During testing/debugging sessions, Claude should observe and report issues, not automatically fix them. Verbal instructions like "don't make changes" are ignored because Claude's helpful instincts override them. A mechanical hook enforcement ensures Claude MUST ask the user before modifying code files.

The hook creates a workflow where:
1. Claude tries to edit a code file
2. Hook blocks with: "Did the user explicitly ask for this edit?"
3. Claude must ask user for confirmation
4. User says yes → Claude retries → hook allows (user confirmed)
5. User says no → Claude reports findings instead

## References
- Existing hook pattern: `hooks/block-mcp-git-commits.sh` (220 lines, security-hardened)
- Hook input format: JSON with tool_name, tool_input.file_path, session_id, cwd
- Exit codes: 0=allow, 1=block with message, 2=block silently

## Technical Design

### hooks.json Entry
```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "hooks/confirm-code-edits.sh",
      "timeout": 10
    }
  ]
}
```
Place BEFORE the "*" diagnostic-logger matcher.

### Hook Logic Flow
```
1. Check SKIP_EDIT_CONFIRMATION=true → exit 0
2. Parse JSON input (jq primary, sed fallback)
3. Extract file_path from tool_input
4. Check if path contains "/tickets/" → exit 0
5. Check if filename matches test patterns → exit 0
6. Check if extension is in code file list → if not, exit 0
7. Output confirmation message to stderr → exit 1
```

### Message Format
```
================================================================================
  CODE EDIT CONFIRMATION REQUIRED
================================================================================

File: /path/to/file.go
Tool: Edit

Did the user explicitly ask for this edit?

If YES: Ask the user to confirm, then retry this operation.
If NO:  Report your findings instead of making changes.

================================================================================
```

### Environment Variables
- `SKIP_EDIT_CONFIRMATION=true` - Bypass hook entirely (for legitimate dev sessions)
- `CODE_FILE_EXTENSIONS="go,py,sh,js,ts,tsx,jsx"` - Customizable extension list

### Test File Patterns to Exclude
- Go: `*_test.go`
- Python: `test_*.py`, `*_test.py`
- JavaScript/TypeScript: `*.test.js`, `*.test.ts`, `*.spec.js`, `*.spec.ts`, `*.test.jsx`, `*.test.tsx`, `*.spec.jsx`, `*.spec.tsx`

### Security Requirements
- Use `set -euo pipefail`
- Use `printf` instead of `echo` (command injection prevention)
- Quote all variables
- Proper jq error handling with sed fallback
- No eval or command substitution with user input

# Creator Section

## Implementation Notes
Implemented confirm-code-edits.sh (220 lines) following security patterns from block-mcp-git-commits.sh:

**Security Compliance:**
- `set -euo pipefail` for strict error handling
- `printf` instead of `echo` for command injection prevention
- jq primary parsing with sed fallback for portability
- All variables properly quoted
- Debug logging to `~/.claude/logs/hooks-debug.log`

**Logic Flow:**
1. SKIP_EDIT_CONFIRMATION=true check first (fast path)
2. JSON parsing with jq/sed fallback
3. Exclusion checks: tickets/ path, test file patterns
4. Extension check against CODE_FILE_EXTENSIONS
5. Block with confirmation message to stderr, exit 1

**Test Patterns Supported:**
- Go: `*_test.go`
- Python: `test_*.py`, `*_test.py`
- JS/TS: `*.test.{js,ts,jsx,tsx}`, `*.spec.{js,ts,jsx,tsx}`

## Questions/Concerns
1. Shellcheck reports SC2034 (unused SCRIPT_DIR) and SC2155 (combined declare/assign) - kept for consistency with block-mcp-git-commits.sh pattern
2. Test patterns use regex matching which may be slower than glob, but provides more flexibility

## Changes Made
- File changes:
  - NEW: `hooks/confirm-code-edits.sh` (220 lines)
  - MODIFIED: `hooks/hooks.json` (added Edit|Write matcher)
- Commits: Pending (after quality cycle completion)

**Validation Results:**
- bash -n: PASS
- shellcheck: 2 minor warnings (non-blocking)
- JSON validation: PASS
- Functional tests: All 5 scenarios pass

**Status Update**: 2025-12-03 12:15 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
None identified.

### HIGH Issues
None identified.

### MEDIUM Issues
- [ ] `confirm-code-edits.sh:108` - Minor optimization: Using external `echo` with `xargs` for whitespace trimming is less efficient than parameter expansion. Can be deferred to future refactoring.
- [ ] `confirm-code-edits.sh:234` - Exit code 1 differs from block-mcp-git-commits.sh (exit 2), but this is documented and intentional for message visibility.

## Strengths Observed
1. **Security:** No command injection vulnerabilities, proper quoting, safe JSON parsing, audit logging
2. **Error Handling:** Defensive `set -euo pipefail`, graceful jq/sed fallback, safe defaults (fail-open)
3. **Edge Cases:** Empty paths, missing extensions, nested tickets/, test patterns all handled
4. **Code Quality:** Modular design, consistent with codebase patterns, comprehensive debug logging
5. **hooks.json:** Correct matcher syntax, appropriate timeout, proper placement

## Approval Decision
APPROVED

## Rationale
Implementation demonstrates excellent security practices, robust error handling, and thorough edge case coverage. Follows established patterns while adapting appropriately for its use case. The fail-open design is correct for PreToolUse hooks to prevent false positives. Minor MEDIUM issues are non-blocking optimizations that can be addressed in future refactoring.

**Status Update**: 2025-12-03 12:20 - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Hook syntax: [bash -n validation]
- Security review: [shellcheck]
- Functional test - blocked: [Edit code file without skip]
- Functional test - allowed: [tickets/ path]
- Functional test - allowed: [test file]
- Functional test - allowed: [SKIP env var]
- Functional test - allowed: [non-code file]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-03 12:00] - Coordinator
- Ticket created from handoff prompt
- Technical design completed via sequential thinking analysis
- Ready for code-developer implementation
