---
description: Auto-generate investigation/research handoff prompt
---

Analyze this investigation session and automatically generate a handoff prompt that captures my research questions, findings, evidence, mental model, and understanding of the codebase.

## What I Know About This Investigation

From the conversation, I understand we're researching something. Let me automatically extract:

### The Questions
- What are we trying to understand (from conversation context)
- Why it matters (from discussion of motivation)
- What specific questions need answers (from my investigation focus)

### My Exploration
- What code did I read (from Read tool usage - which files, what I was looking for)
- What patterns did I search for (from Grep tool usage)
- What tests did I run (from Bash commands - experiments, reproductions)
- What documentation did I review (from WebFetch or file reads)

### Findings and Insights
- What have I confirmed (from code analysis with evidence)
- What do I suspect (from partial evidence or reasoning)
- What have I ruled out (from evidence disproving hypotheses)
- What connections did I discover (from code relationships)

### My Mental Model
- How do I now understand this system/component (from my analysis)
- What patterns or architecture did I uncover (from code structure)
- Why does it work this way (from design insights)
- Where is complexity hiding (from investigation discoveries)

## Auto-Generate Investigation State

Gather without asking:
```bash
pwd                                    # Working directory
git status --short                     # Any experimental changes
git log -3 --oneline                   # Recent context
```

## Extract From Tool Usage

Automatically analyze my investigation actions:
- **Read calls**: Pattern of exploration (which files I examined, in what order, why)
- **Grep calls**: What I was searching for (keywords, patterns, function names)
- **Bash calls**: Experiments run (tests, queries, reproductions)
- **Patterns discovered**: Common code patterns, architectural insights

## Capture My Investigation Mental Model

From my reasoning throughout the research, extract:

1. **Understanding gained**: What do I now know that I didn't before
2. **Code architecture**: How components fit together (from analysis)
3. **Design rationale**: Why the code is structured this way (from insights)
4. **Gotchas discovered**: Surprising behavior or complexity (from investigation)
5. **Knowledge gaps**: What I still need to learn or verify

## Generate Investigation Handoff

Using the INVESTIGATION template from SESSION_CONTINUATION_FORMAT.md:

```markdown
# Session Continuation: INVESTIGATION

## Executive Summary
[Auto-generated: What we're investigating + key findings + current focus]

## Working Directory
[From pwd]

## Investigation Goals
- [Question 1 to answer - from conversation]
- [Question 2 to answer]
- [Question 3 to answer]

## Current State
- **Files Examined**: [Count and key files - from Read tool usage]
- **Search Patterns**: [What I searched for - from Grep usage]
- **Experiments Run**: [Tests/reproductions - from Bash usage]
- **Documentation Reviewed**: [Docs/specs read]

## Findings

### Confirmed ✓
[High-confidence findings with evidence]

1. **[Finding]**: [What I discovered]
   - Evidence: [File:line showing this, or test result proving it]
   - Significance: [Why this matters]

2. **[Finding]**: [What I learned]
   - Evidence: [Code analysis, behavior observation]
   - Significance: [Impact on understanding]

### Suspected ~
[Medium-confidence hypotheses with partial evidence]

1. **[Hypothesis]**: [What I think is true]
   - Partial Evidence: [What supports this]
   - Needs: [What would confirm or disprove]

2. **[Hypothesis]**: [What seems likely]
   - Partial Evidence: [Supporting clues]
   - Needs: [Further investigation needed]

### Ruled Out ✗
[Disproven hypotheses - important to document]

1. **[Initially Thought]**: [What I suspected but disproved]
   - Why Eliminated: [Evidence disproving this]
   - Lesson: [What this teaches about the system]

## Evidence Collected

[From tool usage - files examined, code snippets, test results, logs]

1. **[File/Location]**: [What it shows]
   - Line: [file:line]
   - Insight: [What this reveals]

2. **[Test/Experiment]**: [What happened]
   - Command: [bash command run]
   - Result: [output/behavior observed]
   - Meaning: [what this tells us]

## Code Architecture Understanding

[How the system works - from my investigation]

- **Component Structure**: [How pieces are organized]
- **Data Flow**: [How information moves through system]
- **Key Patterns**: [Architectural patterns discovered]
- **Integration Points**: [How components interact]

## Mental Model (Critical Insight)

[Deep understanding of how/why the code works this way - this is what next Claude needs to think like me]

What I now understand about this system that isn't obvious from just reading code:
- [Insight 1 - design rationale, historical context, subtle behavior]
- [Insight 2 - why certain patterns exist]
- [Insight 3 - where complexity lies and why]

## Investigation Journey

[Chronological path of discovery - helps next Claude understand my thought process]

1. Started by examining [X] because [reasoning]
2. Discovered [Y] which led me to investigate [Z]
3. Found [pattern/behavior] which explained [question]
4. Confirmed by [test/analysis]

## Next Steps

[Logical continuation of investigation - what to examine next]

1. [Next thing to check - specific file, test, or experiment]
2. [Next question to answer - based on current findings]
3. [Next verification - confirm or disprove hypothesis]

## Success Criteria

✓ [Question answered]
✓ [Hypothesis confirmed or disproven]
✓ [Architecture understood]
✓ [Can explain to others how this works]

## Open Questions

[What's still unclear or unknown]

- [Question needing investigation]
- [Uncertainty to resolve]
- [Assumption to verify]
```

## Key Insights to Preserve

Highlight the most important discoveries that next Claude MUST understand:
- Non-obvious code behavior or design decisions
- Why certain patterns exist (historical context, constraints)
- Where complexity hides and why
- What mistakes to avoid (learned from investigation)
- Critical relationships between components

## Present Handoff

Show the complete handoff in a code block, explain what I discovered about the system, and ask if the user wants to save it to `handoff-investigate-YYYYMMDD-HHMM.md` or use as-is.
