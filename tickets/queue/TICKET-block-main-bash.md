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
ticket_id: TICKET-block-main-bash
session_id: block-main-bash
sequence: null
parent_ticket: null
title: Block ALL Bash Operations from Main Thread
cycle_type: development
status: open
created: 2025-12-11 00:00
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PreToolUse hook that blocks ALL Bash tool invocations from the main thread, requiring all Bash operations to be performed within an agent context. This extends the existing pattern from `block-main-thread-reads.sh` to enforce:

1. **Main thread**: Coordinates via Task tool ONLY
2. **Agents**: Do ALL work including git operations, chmod, and script execution
3. **Bash tool**: Effectively disabled for main thread

### Specific Behaviors to Block

- Git operations (add, commit, push, PR creation) - must go through agents in worktrees
- File system operations (chmod, mkdir, mv, cp)
- Script execution
- Any other shell commands

### No Exceptions

There should be zero carve-outs or special cases. If main thread needs shell work done, it must dispatch an agent.

## Acceptance Criteria

- [ ] PreToolUse hook blocks Bash tool invocations without agent context
- [ ] Clear error message explains that agents must perform all Bash work
- [ ] Error message provides guidance on using Task tool to dispatch agents
- [ ] Violation logged to observations with appropriate metadata
- [ ] Hook follows security hardening patterns from existing hooks
- [ ] Debug logging captures blocked attempts
- [ ] Hook integrated into hooks.json configuration
- [ ] Documentation updated in README.md
- [ ] Tested in real workflow scenarios (git operations, script execution)
- [ ] No false positives (agent context properly detected)

# Context

## Why This Work Matters

**Problem**: Current workflow allows main thread to run Bash commands directly, leading to:
- GitOps (git add, commit, push, PR) done by main thread instead of agents
- Scripts requiring chmod executed on main thread
- Violation of "main thread coordinates, agents work" principle
- Inconsistent separation of concerns

**Impact**: This creates confusion about responsibility boundaries and bypasses the quality cycle enforcement for git operations.

**Solution**: By blocking ALL Bash from main thread, we enforce clean separation:
- Main thread becomes pure coordinator (Task tool only)
- All execution happens in agent contexts
- Git operations naturally happen in worktrees via agents
- Clear, enforceable boundary

## References

- Pattern reference: `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-main-thread-reads.sh`
- Configuration: `/home/ddoyle/.claude/plugins/workflow-guard/hooks/hooks.json`
- Security patterns: `/home/ddoyle/.claude/plugins/workflow-guard/hooks/block-unreviewed-edits.sh`
- Related documentation: `/home/ddoyle/.claude/plugins/workflow-guard/README.md`

# Creator Section

## Implementation Notes

[To be filled by plugin-engineer during implementation]

## Questions/Concerns

[To be filled by plugin-engineer during implementation]

## Changes Made

- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
[To be filled by plugin-reviewer]

### HIGH Issues
[To be filled by plugin-reviewer]

### MEDIUM Issues
[To be filled by plugin-reviewer]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results

- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [N/A - Bash]
- Security scans: [PASS/FAIL]
- Build: [N/A - Plugin]
- Real workflow tests: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-11 00:00] - Creator: created
- Ticket created in queue/
- Requirements defined: Block ALL Bash from main thread
- No exceptions - agents must do all shell work
- Extends pattern from block-main-thread-reads.sh to Bash tool
