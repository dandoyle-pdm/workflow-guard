---
# Metadata
ticket_id: TICKET-quality-gate-001
session_id: quality-gate
sequence: 001
parent_ticket: null
title: Implement quality transformer gate hook for file modifications
cycle_type: development
status: critic_review
claimed_by: ddoyle
claimed_at: 2025-12-03 22:19
created: 2025-12-03 22:10
worktree_path: /home/ddoyle/.novacloud/worktrees/workflow-guard/TICKET-quality-gate-001
---

# Requirements

## What Needs to Be Done

Implement a PreToolUse hook that enforces quality transformer (agent) usage for file modifications. The hook blocks Edit/Write/NotebookEdit operations unless:
1. The operation is on a ticket or handoff file (workflow metadata)
2. A quality agent (from qc-router) is detected in the transcript

This ensures all changes go through the appropriate quality cycle:
- **Code**: code-developer → code-reviewer → code-tester
- **Plugin**: plugin-engineer → plugin-reviewer → plugin-tester
- **Prompt**: prompt-engineer → prompt-reviewer → prompt-tester
- **Documentation**: tech-writer → tech-editor → tech-publisher

## Acceptance Criteria

### Hook Implementation
- [ ] Create `hooks/block-unreviewed-edits.sh`
- [ ] Triggers on: Edit, Write, NotebookEdit tools
- [ ] Reads `transcript_path` from hook JSON input
- [ ] Detects quality agent identity via transcript grep
- [ ] Blocks with guidance if no quality agent detected
- [ ] Allows ticket files (`tickets/**/*.md`) and handoff files (`**/HANDOFF*.md`)
- [ ] Exit codes: 0=allow, 2=block with message

### Declarative Configuration
- [ ] Update `hooks/hooks.json` with new hook entry
- [ ] Use matcher pattern: `Edit|Write|NotebookEdit`
- [ ] Set appropriate timeout (5s recommended)

### Documentation
- [ ] README.md: Add "Integration with qc-router" section
- [ ] README.md: Add "Quality Transformer Requirement" section
- [ ] README.md: Document declarative hook loading in hooks.json
- [ ] Document transcript identity detection pattern
- [ ] List recognized quality agents (configurable)

### Testing
- [ ] Test: Main thread Edit blocked with guidance
- [ ] Test: Quality agent Edit allowed
- [ ] Test: Ticket file Edit allowed (exception)
- [ ] Test: Handoff file Edit allowed (exception)

# Context

## Why This Work Matters

Currently, workflow-guard blocks commits to protected branches but doesn't prevent direct file edits. This allows bypassing the quality cycle by editing files directly without going through quality agents.

The quality gate hook closes this gap by requiring a quality transformer (agent) context for any file modification. This integrates with the qc-router plugin which defines quality agents.

## Integration Architecture

```
workflow-guard (this plugin)          qc-router (sister plugin)
├── hooks/                            ├── agents/
│   └── block-unreviewed-edits.sh     │   ├── code-developer/
│       │                             │   ├── plugin-engineer/
│       │ reads transcript            │   ├── prompt-engineer/
│       │ greps for agent identity    │   ├── tech-writer/
│       ▼                             │   └── ... (12 agents)
│   "{agent-name} agent" ─────────────┤ Identity marker in AGENT.md
│       │                             │
│       └── ALLOW if found            └── Dispatched via Task tool
```

## Transcript Identity Pattern

When a quality agent is dispatched via Task tool, the AGENT.md content (including identity marker) appears in the subagent's transcript.

**Pattern to detect:** `working as the {agent-name} agent`

**All 12 recognized quality agents:**
| Cycle | Agents |
|-------|--------|
| Code | code-developer, code-reviewer, code-tester |
| Plugin | plugin-engineer, plugin-reviewer, plugin-tester |
| Prompt | prompt-engineer, prompt-reviewer, prompt-tester |
| Documentation | tech-writer, tech-editor, tech-publisher |

**Grep pattern:**
```bash
QUALITY_AGENTS="code-developer|code-reviewer|code-tester"
QUALITY_AGENTS+="|plugin-engineer|plugin-reviewer|plugin-tester"
QUALITY_AGENTS+="|prompt-engineer|prompt-reviewer|prompt-tester"
QUALITY_AGENTS+="|tech-writer|tech-editor|tech-publisher"

grep -qE "${QUALITY_AGENTS}" "$transcript_path"
```

## Declarative Hook Loading

The `hooks/hooks.json` file declaratively configures which hooks load and when they trigger:

```json
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write|NotebookEdit",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/block-unreviewed-edits.sh",
          "timeout": 5
        }
      ]
    }
  ]
}
```

**Key concepts:**
- Loaded at Claude Code session start
- `matcher`: Regex pattern for tool names
- `command`: Relative path from plugin root
- `timeout`: Max execution time in seconds
- Multiple hooks can be chained for same matcher

## References
- Sister project: `~/.claude/plugins/qc-router/`
- Agent definitions: `~/.claude/plugins/qc-router/agents/`
- Existing hooks: `hooks/block-main-commits.sh` (reference implementation)

# Technical Specification

## Hook Input (JSON via stdin)

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file",
    "old_string": "...",
    "new_string": "..."
  },
  "transcript_path": "/home/user/.claude/projects/.../agent-xxx.jsonl",
  "cwd": "/current/working/directory",
  "session_id": "..."
}
```

## Hook Logic

```bash
1. Parse JSON input (jq or sed fallback)
2. Extract file_path and transcript_path
3. Check if file_path matches exception patterns:
   - tickets/**/*.md → ALLOW
   - **/HANDOFF*.md → ALLOW
4. Check if transcript contains quality agent identity:
   - grep for agent markers
   - If found → ALLOW
5. Otherwise → BLOCK with guidance message
```

## Block Message Format

```
Quality transformer required for file modifications.

This file modification requires a quality agent context.
Use qc-router to dispatch the appropriate agent:

  For implementation: plugin-engineer
  For code review: plugin-reviewer
  For testing: plugin-tester

Example dispatch:
  Task(subagent_type="general-purpose", prompt="You are the plugin-engineer agent...")

See: ~/.claude/plugins/qc-router/agents/
```

## Environment Variables

- `QUALITY_AGENTS`: Comma-separated list of recognized agents. Default includes all 12 qc-router agents:
  `code-developer,code-reviewer,code-tester,plugin-engineer,plugin-reviewer,plugin-tester,prompt-engineer,prompt-reviewer,prompt-tester,tech-writer,tech-editor,tech-publisher`

# Creator Section

## Implementation Notes

Implemented quality gate enforcement hook following patterns from block-main-commits.sh.

**Key design decisions:**

1. **Transcript identity detection**: Used grep pattern matching on transcript JSONL file to detect quality agent identity markers. Pattern: `working as the {agent-name} agent` catches all 12 quality transformers from qc-router.

2. **Dual path parsing**: Implemented both jq (preferred) and sed fallback (portable) for JSON parsing, following security hardening patterns from reference implementation.

3. **File path extraction**: Handles both `file_path` (Edit/Write) and `notebook_path` (NotebookEdit) from tool_input to support all three target tools.

4. **Workflow metadata exceptions**: Two exception patterns:
   - `tickets/**/*.md` - Any markdown in tickets directory (queue, active, completed, archive)
   - `**/HANDOFF*.md` - Any handoff file regardless of location

5. **Configuration via environment**: `CLAUDE_QUALITY_AGENTS` allows extending recognized agents beyond default 12, following same pattern as `CLAUDE_PROTECTED_BRANCHES`.

6. **Audit logging**: All ALLOW/BLOCK decisions logged to ~/.claude/logs/hooks-debug.log with relevant context (file path, tool name, detected agent).

7. **Helpful error messages**: Block message provides clear guidance on using qc-router, lists agent categories, and explains why quality cycles matter.

## Questions/Concerns

None. Implementation is straightforward and follows established patterns from existing hooks.

## Changes Made

**Files created:**
- `hooks/block-unreviewed-edits.sh` - Quality agent enforcement hook (240 lines)

**Files modified:**
- `hooks/hooks.json` - Added hook entry for Edit|Write|NotebookEdit matcher
- `README.md` - Comprehensive documentation updates:
  - Updated hooks count (Three → Four)
  - Added block-unreviewed-edits hook description
  - Added CLAUDE_QUALITY_AGENTS configuration section
  - Updated Quality Transformer Requirement (Planned → Implemented)
  - Enhanced declarative hook configuration examples

**Commits:**
- d73fea3 - feat(hooks): add quality agent enforcement for file edits
- 2f4dc22 - docs: integrate quality gate hook into configuration and documentation

**Status Update**: 2025-12-03 22:35 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [x] `hooks/block-unreviewed-edits.sh:81,85` - **Regex injection via QUALITY_AGENTS environment variable**

  **Issue**: The `CLAUDE_QUALITY_AGENTS` environment variable is converted to a grep regex pattern without sanitization:
  ```bash
  agent_pattern=$(printf '%s' "${QUALITY_AGENTS}" | sed 's/,/|/g')
  if grep -qE "working as the (${agent_pattern}) agent" "$transcript_path"
  ```

  **Attack Vector**:
  ```bash
  export CLAUDE_QUALITY_AGENTS=".*"  # Matches everything - bypasses quality gate!
  export CLAUDE_QUALITY_AGENTS="code-developer)|(.*"  # Regex injection
  ```

  **Fix Required**: Validate that `QUALITY_AGENTS` contains only safe characters before constructing regex:
  ```bash
  # Validate agent list contains only alphanumeric, hyphens, commas
  if [[ ! "${QUALITY_AGENTS}" =~ ^[a-zA-Z0-9,_-]+$ ]]; then
      debug_log "ERROR: Invalid QUALITY_AGENTS format: ${QUALITY_AGENTS}"
      debug_log "QUALITY_AGENTS must contain only alphanumeric, hyphens, underscores, and commas"
      exit 2  # Block on invalid configuration
  fi
  ```

  **Impact**: Complete bypass of quality gate enforcement
  **Similar to**: TICKET-lifecycle-cleanup-001 regex bypass (different pattern but same class of vulnerability)

### HIGH Issues
- [x] `hooks/block-unreviewed-edits.sh:54` - **Path traversal in ticket directory detection**

  **Issue**: File paths are not canonicalized before checking if they're in the tickets directory:
  ```bash
  if [[ "$file_path" =~ ^.*tickets/.* ]]; then
      debug_log "Workflow metadata: ticket file ($file_path)"
      return 0
  fi
  ```

  **Attack Vector**:
  ```bash
  # Path contains "tickets/" but traverses outside it
  file_path="/home/user/project/tickets/../../../../etc/shadow"
  # Pattern matches because it contains "tickets/"
  # But canonical path is /etc/shadow
  ```

  **Fix Required**: Canonicalize path and verify it's actually under a tickets directory:
  ```bash
  is_workflow_metadata() {
      local file_path="$1"
      local filename
      filename=$(basename "$file_path")

      # Resolve canonical path if file exists, otherwise use as-is for new files
      local canonical_path
      if [[ -e "$file_path" ]]; then
          canonical_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
      else
          # For new files, canonicalize the directory and append filename
          local dir_path
          dir_path=$(dirname "$file_path")
          if [[ -e "$dir_path" ]]; then
              canonical_path="$(realpath "$dir_path" 2>/dev/null)/$filename"
          else
              canonical_path="$file_path"
          fi
      fi

      # Check if canonical path contains /tickets/ directory component
      if [[ "$canonical_path" =~ (^|/)tickets/ ]]; then
          debug_log "Workflow metadata: ticket file ($canonical_path)"
          return 0
      fi

      # Check if file is a handoff file (unchanged)
      if [[ "$filename" =~ ^HANDOFF.*\.md$ ]]; then
          debug_log "Workflow metadata: handoff file ($filename)"
          return 0
      fi

      return 1
  }
  ```

  **Impact**: Ability to bypass quality gate by crafting paths with traversal sequences
  **Note**: The handoff pattern `^HANDOFF.*\.md$` is properly anchored and not vulnerable

### MEDIUM Issues
- [x] `hooks/block-unreviewed-edits.sh:172,182,186,209` - **Fail-open on JSON parsing errors**

  **Issue**: When JSON parsing fails, the hook exits 0 (allows operation):
  ```bash
  if ! tool_name=$(jq ...) || [[ -z "${tool_name}" ]]; then
      debug_log "ERROR: Failed to parse tool_name from JSON"
      exit 0  # <-- ALLOWS the operation
  fi
  ```

  **Trade-off Analysis**:
  - **Current behavior (fail-open)**: Don't break workflows if hook has bugs or JSON format changes
  - **Alternative (fail-closed)**: Block operations when validation fails, maximum security

  **Recommendation**: Current fail-open behavior is acceptable for usability, but document this design decision. The hook protects against intentional bypasses, not hook failures.

  **Impact**: Low - Requires hook malfunction or unexpected JSON format

- [x] `hooks/block-unreviewed-edits.sh:191-203` - **Sed fallback parsing edge cases**

  **Issue**: The sed-based JSON parsing uses greedy `.*` matching:
  ```bash
  tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  ```

  **Potential Risk**: The greedy `.*` matches the LAST occurrence of `"tool_name"` on a line, not the first.

  **Mitigating Factors**:
  - JSON input from Claude Code is single-line
  - The `head -1` limits to first line
  - Real risk is minimal in practice

  **Recommendation**: Accept as-is. The sed fallback is a compatibility layer for systems without jq, and the greedy matching is unlikely to cause issues with well-formed JSON.

  **Impact**: Low - Edge case requiring malformed JSON

## Approval Decision
**NEEDS_CHANGES**

## Rationale

The implementation demonstrates solid security awareness and follows established patterns from `block-main-commits.sh`. However, **two blocking security issues** were identified:

1. **CRITICAL: Regex injection** - The `CLAUDE_QUALITY_AGENTS` environment variable is used directly in grep regex without validation. An attacker with environment control could set `CLAUDE_QUALITY_AGENTS=".*"` to bypass the quality gate entirely.

2. **HIGH: Path traversal** - File paths are not canonicalized before checking the tickets directory exception. Paths like `/project/tickets/../../../../etc/passwd` would be treated as workflow metadata and bypass the quality gate.

These issues must be fixed before approval because they allow complete bypass of the quality enforcement mechanism.

**Positive aspects**:
- Proper command injection prevention (all variables quoted)
- Comprehensive audit logging
- Helpful error messages
- Good fail-safe design (transcript validation)
- Follows security patterns from vetted hooks

**Additional notes**:
- The MEDIUM issues are acceptable design trade-offs
- The case-sensitive agent matching is correct behavior (not a vulnerability)
- The handoff filename pattern is properly implemented

**Recommendation**: Create fixes for the two blocking issues, then re-review.

**Status Update**: 2025-12-03 23:15 - Audit complete, status remains `critic_review` pending fixes

## Reviewer Verification

**plugin-reviewer verification completed**: 2025-12-03 23:45

I have independently reviewed the security audit findings and confirm:

### Verified Findings
1. **CRITICAL - Regex Injection (Lines 81, 85)**: CONFIRMED
   - `CLAUDE_QUALITY_AGENTS` environment variable used directly in grep regex
   - Attack: `export CLAUDE_QUALITY_AGENTS=".*"` bypasses all quality checks
   - No validation that agents list contains only safe characters

2. **HIGH - Path Traversal (Line 54)**: CONFIRMED
   - File paths not canonicalized before tickets directory check
   - Attack: `/path/tickets/../../../../etc/passwd` matches pattern but escapes directory
   - `realpath` canonicalization required before validation

3. **MEDIUM - Fail-Open Behavior**: CONFIRMED as acceptable trade-off
   - Exits 0 on JSON parsing errors to avoid breaking workflows
   - Documented design decision for usability over fail-closed security

4. **MEDIUM - Sed Greedy Matching**: CONFIRMED as low-risk
   - Fallback parser for systems without jq
   - Minimal real-world risk with well-formed Claude Code JSON

### Additional Security Review

Compared against vetted `block-main-commits.sh` implementation:
- ✅ Command injection prevention: All variables properly quoted
- ✅ Proper printf usage instead of echo
- ✅ Comprehensive audit logging with no sensitive data leaks
- ✅ Correct exit codes (0=allow, 2=block)
- ✅ Fail-safe transcript validation (file existence check)
- ✅ Helpful error messages with workflow guidance
- ✅ Case-sensitive agent matching (correct behavior)
- ✅ Handoff filename pattern properly anchored

### No New Issues Identified

I did not find any security vulnerabilities beyond those already documented in the initial audit. The audit is thorough and accurate.

### Strengths Observed
- Security-conscious design following established patterns
- Comprehensive error handling and logging
- Clear separation of workflow metadata vs. production code
- Well-structured fail-safe defaults

### Approval Decision Confirmed
**NEEDS_CHANGES** - Two blocking security issues must be resolved:
1. Add input validation for `QUALITY_AGENTS` (alphanumeric + hyphens/underscores/commas only)
2. Add path canonicalization for tickets directory detection

Once these fixes are implemented, the hook will be ready for approval.

# Expediter Section

## Validation Results
- Hook syntax valid: [PASS/FAIL]
- Main thread blocked: [PASS/FAIL]
- Quality agent allowed: [PASS/FAIL]
- Ticket exception works: [PASS/FAIL]
- Documentation complete: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-03 22:10] - Ticket Created
- Defined requirements for quality transformer gate hook
- Documented integration architecture with qc-router
- Specified transcript identity detection pattern
- Included declarative hook loading documentation requirements

## [2025-12-03 22:19] - Activated
- Worktree: /home/ddoyle/.novacloud/worktrees/workflow-guard/TICKET-quality-gate-001
- Branch: ticket/TICKET-quality-gate-001
