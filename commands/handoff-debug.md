---
description: Auto-generate debugging session handoff prompt
---

Analyze this debugging session and automatically generate a handoff prompt that captures my current understanding of the bug, solution approach, and mental model.

## What I Know About This Session

From the conversation, I understand we're debugging. Let me automatically extract:

### The Bug
- What's broken and how it manifests (from error messages, user reports, failed tests)
- When it was discovered (from conversation context)
- Impact and severity (from discussion)

### My Investigation
- What I've examined (from Read tool usage - which files, why)
- What I've tested (from Bash commands - tests run, reproductions attempted)
- What I've discovered (from my analysis and reasoning in conversation)

### Root Cause Understanding
- Current hypothesis about why the bug occurs (from my reasoning)
- Evidence supporting this hypothesis (from code analysis, logs, tests)
- Confidence level (certain, likely, suspected, unknown)

### Solution Approach
- What fixes I've attempted or applied (from Edit/Write tool usage)
- Why I chose this approach (from my reasoning)
- What worked and what didn't (from command results, test outcomes)

### Current State
- Is a fix applied but not tested?
- Is a fix applied and partially working?
- Still investigating root cause?
- Blocked on something?

## Auto-Generate System State

Gather without asking:
```bash
pwd                           # Working directory
git status --short            # Modified files
git log -3 --oneline          # Recent work
docker ps --filter "name=novacloud"  # Running containers
```

If containers are running, check health endpoints.

## Extract From Tool Usage

Automatically analyze my tool usage in this session:
- **Read calls**: Which files did I examine and what was I looking for
- **Edit calls**: What did I change (file:line, old → new, why)
- **Bash calls**: What commands did I run, what were the results
- **Error messages**: What failures occurred and what they told me

## Capture My Mental Model

From my reasoning throughout the conversation, extract:

1. **How I understand the bug**: Not just "what's wrong" but "why it happens"
2. **My debugging strategy**: What approach am I using (binary search, trace execution, compare working vs broken, etc.)
3. **Code insights**: What did I learn about how this code works
4. **Connections**: What relationships between components did I discover
5. **Assumptions**: What am I assuming to be true that next Claude should verify or maintain

## Generate Debugging Handoff

Using the DEBUGGING template from SESSION_CONTINUATION_FORMAT.md:

```markdown
# Session Continuation: DEBUGGING

## Executive Summary
[Auto-generated: What bug + where we are in fixing it + current hypothesis]

## Working Directory
[From pwd]

## Current State
[From git status, container status, build status]

## The Bug
**Symptoms**: [How it manifests - from errors, failures, unexpected behavior]
**Impact**: [Who/what affected - from conversation context]
**Discovered**: [When/how found - from conversation]

## Root Cause Analysis
**Current Hypothesis**: [My understanding of why it happens]
**Evidence**:
- [Finding 1 from code analysis]
- [Finding 2 from test results]
- [Finding 3 from logs/errors]

**Confidence**: [How certain I am - certain/likely/suspected/investigating]

## My Investigation Journey
[Chronological: What I examined → What I discovered → What I tried → Results]

## Changes Applied
[From Edit/Write tool usage - file:line format with explanations]

## Current Understanding (Mental Model)
[Deep insight into how the code works and why the bug occurs - this is the critical section that transfers my mental model]

## What Worked / What Didn't
**Worked**: [Successful approaches]
**Didn't Work**: [Failed attempts and why - important lessons]

## Next Steps
[Logical continuation based on current state - ordered, specific commands]

## Success Criteria
✓ [How to verify the fix works]
✓ [What tests must pass]
✓ [What behavior must be correct]

## Open Questions
[What's still uncertain or needs investigation]
```

## Key Insights to Preserve

Highlight the most important insights I've gained that next Claude MUST understand to continue effectively:
- Critical code relationships discovered
- Why certain approaches won't work
- What the code is actually doing vs what it appears to do
- Important context that isn't obvious from code alone

## Present Handoff

Show the complete handoff in a code block, explain what I detected about the session, and ask if the user wants to save it to `handoff-debug-YYYYMMDD-HHMM.md` or use as-is.
