<!--
TICKET LIFECYCLE

1. Create ticket in tickets/queue/ as TICKET-{session-id}.md (no sequence number)
2. Activate: ./scripts/activate-ticket.sh tickets/queue/TICKET-{session-id}.md
   - Assigns sequence number (001, 002, etc.) automatically
   - Renames to TICKET-{session-id}-{sequence}.md
   - Creates worktree at $WORKTREE_BASE/<project>/<session-id>
   - Moves ticket to tickets/active/<session-id>/ in worktree
   - Sets status to in_progress

3. Work in worktree (quality cycle: Creator → Critic → Expediter)

4. Complete: ./scripts/complete-ticket.sh
   - Moves ticket to tickets/completed/<branch>/
   - Sets status to approved
   - Commits the change

5. Create PR: gh pr create --base main
   - Squash merge includes ticket in completed/

6. Cleanup: ./scripts/cleanup-merged-ticket.sh <branch>
   - Removes worktree
   - Deletes local/remote branch

ENUM DEFINITIONS

Use these standardized values in ticket metadata and changelog entries:

CHANGELOG_ROLE (quality cycle roles):
  - Creator     : Plugin-engineer, code-developer, tech-writer (creates work)
  - Critic      : Plugin-reviewer, code-reviewer, tech-editor (reviews work)
  - Expediter   : Plugin-tester, code-tester, tech-publisher (validates work)

TICKET_STATUS (workflow states):
  - open                : Ticket created in queue/
  - claimed             : Ticket claimed, sequence assigned
  - in_progress         : Active development in worktree
  - critic_review       : Creator done, awaiting Critic audit
  - expediter_review    : Critic approved, awaiting Expediter validation
  - approved            : Ready for PR/merge
  - blocked             : Work cannot proceed (requires intervention)

ENTRY_TYPE (changelog entry types):
  - created     : Ticket created in queue/
  - claimed     : Ticket claimed (sequence assigned, moved to active/)
  - activated   : Worktree created for development
  - work_done   : Creator finished implementation
  - reviewed    : Critic completed audit
  - validated   : Expediter completed validation
  - completed   : Ticket moved to completed/, ready for PR

CHANGELOG FORMAT:
  ## [YYYY-MM-DD HH:MM] - ROLE: ENTRY_TYPE
  - Description of action taken
  - Additional details

  Examples:
    ## [2025-12-10 19:45] - Creator: created
    ## [2025-12-11 08:30] - Creator: activated
    ## [2025-12-11 15:20] - Creator: work_done
    ## [2025-12-11 16:00] - Critic: reviewed
    ## [2025-12-11 16:45] - Expediter: validated

  Entries MUST be in chronological order (oldest first).
-->
---
# Metadata
ticket_id: TICKET-doc-enforcement-hook
session_id: doc-enforcement-hook
sequence: null
parent_ticket: null
title: Implement PostToolUse hook for documentation specification enforcement
cycle_type: development
status: open
created: 2025-12-11 14:30
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PostToolUse hook (`hooks/enforce-doc-spec.sh`) that enforces documentation quality standards by:

1. Detecting documentation file writes/edits
2. Counting substantive lines (excluding blanks, YAML frontmatter, comments)
3. Blocking files exceeding 50 substantive lines
4. Logging violations for observability
5. Optionally invoking tech-writer agent for remediation

**Current Problem:**
- Main thread agents can read/write documentation without validation
- No enforcement of the 50 substantive lines rule
- Documentation changes bypass quality cycles
- No word count validation at write-time

**Solution:**
PostToolUse hook that validates documentation artifacts after Write/Edit operations complete, ensuring compliance with documentation standards before allowing the operation to persist.

## Acceptance Criteria

- [ ] PostToolUse hook fires after Write/Edit operations on documentation files
- [ ] Documentation file detection includes: `*.md`, `docs/**`, `README*`, `tickets/**/*.md`
- [ ] Substantive line counter implemented (excludes blanks, YAML frontmatter delimited by `---`, comments `<!--`, single-line `#`)
- [ ] Files exceeding 50 substantive lines are blocked with actionable error message
- [ ] Error message explains:
  - What was violated (50 line rule)
  - How to fix (split into downstream artifacts, use tech-writer agent)
  - Why it matters (maintainability, reviewability)
- [ ] Violations logged to `~/.novacloud/observations/violations.jsonl` using observe-violation.sh
- [ ] hooks.json updated with PostToolUse matcher for Write/Edit on documentation
- [ ] Hook timeout set appropriately (5-10 seconds)
- [ ] Debug logging to `~/.claude/logs/hooks-debug.log`
- [ ] Exit code 2 blocks operation, exit code 0 allows

# Context

## Why This Work Matters

**Documentation Quality:**
Documentation artifacts serve as single source of truth for implementation, design decisions, and system behavior. Oversized documents become:
- Hard to review (cognitive overload)
- Difficult to maintain (scattered changes)
- Unmaintainable knowledge bases (no clear boundaries)

**Enforcement Gap:**
Current workflow has PreToolUse hooks for quality agent enforcement (block-unreviewed-edits.sh) but no PostToolUse validation of artifact specifications. This allows compliant agents to produce non-compliant artifacts.

**Integration with Quality Cycles:**
- PreToolUse: Ensures quality agent context exists
- PostToolUse: Ensures quality agent produces spec-compliant artifacts
- Together: Complete quality enforcement pipeline

**Observability:**
Violations logged to JSONL provide:
- Audit trail of specification breaches
- Patterns for process improvement
- Data for automated reporting/alerting

## References

- Existing hook patterns:
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-unreviewed-edits.sh` - PreToolUse quality enforcement
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/observe-violation.sh` - Violation logging utility
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/detect-protected-commits.sh` - PostToolUse example

- Configuration:
  - `/home/ddoyle/.claude/plugins/workflow-guard/hooks/hooks.json` - Hook registration

- Documentation:
  - `/home/ddoyle/.claude/plugins/workflow-guard/README.md` - Plugin documentation
  - `/home/ddoyle/.claude/plugins/workflow-guard/CLAUDE.md` - Development guidelines

- Related workflow:
  - Quality Cycles: Creator → Critic → Expediter
  - Plugin Recipe: plugin-engineer → plugin-reviewer → plugin-tester

# Creator Section

## Implementation Notes

**Hook Design:**

1. **Trigger:** PostToolUse on Write/Edit tools
2. **File Matching:**
   - Extension: `*.md`
   - Directories: `docs/`, `README*` in any location
   - Special case: `tickets/**/*.md` (workflow metadata)

3. **Substantive Line Counting:**
   ```bash
   count_substantive_lines() {
       local file="$1"
       local in_frontmatter=false
       local count=0

       while IFS= read -r line; do
           # Toggle frontmatter state
           if [[ "$line" =~ ^---$ ]]; then
               in_frontmatter=$(! $in_frontmatter)
               continue
           fi

           # Skip if in frontmatter
           [[ $in_frontmatter == true ]] && continue

           # Skip blank lines
           [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]] && continue

           # Skip comment lines
           [[ "$line" =~ ^[[:space:]]*#[[:space:]]* ]] && continue
           [[ "$line" =~ ^[[:space:]]*\<!-- ]] && continue

           # Count substantive line
           ((count++))
       done < "$file"

       echo "$count"
   }
   ```

4. **Blocking Logic:**
   - If substantive lines > 50: Exit 2 (block)
   - If substantive lines <= 50: Exit 0 (allow)

5. **Violation Logging:**
   ```json
   {
     "type": "workflow-guard",
     "timestamp": "ISO-8601",
     "observation_type": "blocking",
     "cycle": "tech",
     "session_id": "",
     "agent": "tech-writer",
     "tool": "Write|Edit",
     "file": "/absolute/path/to/file.md",
     "violation": "doc_spec_exceeded",
     "severity": "MEDIUM",
     "blocking": true,
     "context": {
       "substantive_lines": 75,
       "limit": 50,
       "excess": 25
     }
   }
   ```

6. **Error Message:**
   ```
   ================================================================================
     DOCUMENTATION SPECIFICATION VIOLATION - Artifact Size Exceeded
   ================================================================================

   You attempted to write a documentation file exceeding the 50 substantive line limit:
     File: {file_path}
     Substantive lines: {count}
     Limit: 50
     Excess: {count - 50}

   --------------------------------------------------------------------------------
     WHAT ARE SUBSTANTIVE LINES?
   --------------------------------------------------------------------------------

   Substantive lines exclude:
     - Blank lines
     - YAML frontmatter (between --- delimiters)
     - Comment lines (# or <!-- -->)

   --------------------------------------------------------------------------------
     WHY THIS MATTERS
   --------------------------------------------------------------------------------

   - Oversized documents are hard to review (cognitive overload)
   - Large files become unmaintainable (scattered changes)
   - Single-purpose artifacts improve reusability
   - Modular documentation supports composition

   --------------------------------------------------------------------------------
     HOW TO FIX
   --------------------------------------------------------------------------------

   Option 1: Split into downstream artifacts
     - Break document into logical sections
     - Create separate files for each section
     - Link sections together with references

   Option 2: Use tech-writer agent for refactoring
     - Invoke tech-writer to analyze and split
     - Tech-editor will validate structure
     - Tech-publisher will ensure quality

   Example:
     Task(subagent_type="general-purpose",
          prompt="You are the tech-writer agent. Refactor {file} into modular artifacts...")

   ================================================================================
   ```

**hooks.json Update:**
```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/enforce-doc-spec.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

## Questions/Concerns

1. **Should tickets be exempt from 50-line rule?**
   - Tickets accumulate changelog entries over quality cycle
   - Ticket sections (Creator, Critic, Expediter) expand naturally
   - Proposal: Exempt tickets from enforcement OR raise limit to 100 for tickets

2. **Should hook validate on Edit as well as Write?**
   - Write creates new files
   - Edit modifies existing files
   - Both should be validated for consistency
   - Proposal: Validate both Write and Edit

3. **Should hook invoke tech-writer automatically or just suggest?**
   - Automatic invocation could be intrusive
   - Manual suggestion puts control with user
   - Proposal: Block with helpful message, let user decide remediation

4. **What about incremental edits that push over limit?**
   - File starts at 48 lines, edit adds 5 lines → violation
   - Should we warn before violation (45-50 lines)?
   - Proposal: Block at violation, no pre-warnings (fail-fast principle)

## Changes Made

*To be filled during implementation*

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
*To be filled by plugin-reviewer*

### HIGH Issues
*To be filled by plugin-reviewer*

### MEDIUM Issues
*To be filled by plugin-reviewer*

## Approval Decision
*To be filled by plugin-reviewer*

## Rationale
*To be filled by plugin-reviewer*

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
*To be filled by plugin-tester*

- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [N/A - bash scripts]
- Security scans: [PASS/FAIL]
- Build: [N/A]

## Quality Gate Decision
*To be filled by plugin-tester*

## Next Steps
*To be filled by plugin-tester*

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-doc-enforcement-hook-{next-seq}`

# Changelog

## [2025-12-11 14:30] - Creator: created
- Ticket created in queue/
- Requirements defined for PostToolUse documentation enforcement
- Acceptance criteria specified
- Implementation design outlined
- Questions raised for discussion
