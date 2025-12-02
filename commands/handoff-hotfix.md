---
description: Auto-generate emergency hotfix handoff prompt
---

Analyze this emergency hotfix session and automatically generate a handoff prompt that captures the critical issue, my investigation, applied fixes, and current state - optimized for urgent continuation.

## What I Know About This Crisis

From the conversation, I understand this is urgent. Let me automatically extract:

### The Failure
- What broke and how (from error messages, alerts, user reports)
- When it started (from timestamps, conversation context)
- Who/what is affected (from impact discussion)
- Current severity (from conversation tone and context)

### My Emergency Response
- What I examined first (from initial Read/Bash tool usage - triage)
- What diagnostics I ran (from Bash commands - logs, health checks, monitoring)
- What I discovered (from my analysis of errors and system state)

### Quick Fix Status
- Did I apply a temporary fix? (from Edit tool usage)
- Is it deployed? (from deployment commands)
- Is it working? (from verification tests)
- Is it truly fixing the root cause or just symptoms?

### Root Cause (If Known)
- Why did it break (from my analysis)
- Confidence level (certain/likely/still investigating)
- Evidence supporting this (from logs, code analysis, reproduction)

## Auto-Generate Emergency State

Gather system state immediately:
```bash
pwd                           # Working directory
git status --short            # Any emergency changes
docker ps                     # Service status
docker logs --tail=50 [container]  # Recent errors
```

Check health endpoints if services are running.

## Extract From Tool Usage

Automatically analyze my emergency actions:
- **Read calls**: What code/config did I examine while triaging
- **Edit calls**: What emergency fixes did I apply (file:line, what changed)
- **Bash calls**: Diagnostic commands, deployment commands, verification tests
- **Error patterns**: What failures are occurring

## Capture My Crisis Understanding

From my reasoning during this emergency, extract:

1. **Failure mode**: Not just "it's down" but "why it's failing"
2. **Blast radius**: Who/what is affected and how severely
3. **Fix rationale**: Why I chose this quick fix vs alternatives
4. **Risk assessment**: Is the quick fix safe or does it introduce new risks
5. **Monitoring**: What to watch to know if fix is working

## Generate Hotfix Handoff

Using the EMERGENCY_HOTFIX template from SESSION_CONTINUATION_FORMAT.md:

```markdown
# Session Continuation: EMERGENCY HOTFIX ⚠️

## Executive Summary
[Auto-generated: What broke + quick fix status + current state]

## Working Directory
[From pwd]

## Impact Assessment
- **Severity**: [Critical/High/Medium - from context]
- **Users Affected**: [Who/how many - from discussion]
- **Services Down**: [What's broken - from diagnostics]
- **Started**: [When - from timestamps]
- **Duration**: [How long has this been down]

## Current State
- **Fix Applied**: [Yes/No - what was done]
- **Deployed**: [Where - prod/staging, how verified]
- **Services**: [Up/Down/Degraded - from health checks]
- **Monitoring**: [What metrics show - from logs/dashboards]

## The Failure
**What Broke**: [Specific component/service that failed]
**How It Manifests**: [Error messages, user-visible symptoms]
**Timeline**: [When discovered, when started, key events]

## My Investigation
[Chronological triage: What I checked → What I found → What I concluded]

## Root Cause
**Current Understanding**: [Why it broke - from my analysis]
**Evidence**:
- [Log entries showing failure]
- [Code analysis showing bug]
- [System state showing resource exhaustion/etc]

**Confidence**: [Certain/Likely/Suspected/Still Investigating]

## Quick Fix Applied
**What**: [Specific changes made - from Edit tool usage]
**Why**: [Rationale for this approach]
**Risk**: [Is this safe? Side effects? Introduces new issues?]
**Verification**: [How I tested it works]

## Changes Made
[From Edit tool usage - file:line format]

## Service Status
- **Before Fix**: [What was broken]
- **After Fix**: [What's working now]
- **Remaining Issues**: [What's still not right]

## Next Steps (Prioritized)
1. **[Immediate]**: [Verify fix holds, monitor metrics]
2. **[Short-term]**: [Plan proper fix if quick fix is temporary]
3. **[Follow-up]**: [Post-mortem, prevent recurrence]

## Success Criteria
✓ [Service restored]
✓ [Users unblocked]
✓ [Errors stopped]
✓ [Monitoring shows recovery]

## Follow-Up Required
- **Proper Fix**: [If quick fix is temporary - what's the real solution]
- **Post-Mortem**: [When scheduled - what to analyze]
- **Prevention**: [How to prevent this in future]

## Critical Monitoring
Watch these metrics/logs to ensure fix is holding:
- [Metric 1 - what value indicates health]
- [Log pattern - what indicates failure recurring]
```

## Key Insights to Preserve

Highlight critical information next Claude MUST know:
- Why this failure mode occurred (not obvious from code)
- Why quick fix was chosen (time pressure, risk trade-offs)
- What to watch for (early warning signs of fix failing)
- What NOT to do (approaches that will make it worse)

## Present Handoff

Show the complete handoff in a code block with **EMERGENCY HOTFIX** clearly marked at top.

Explain the urgency level and current status, and ask if the user wants to save it to `handoff-HOTFIX-YYYYMMDD-HHMM.md` (all caps for visibility) or use as-is.
