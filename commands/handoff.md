---
description: Auto-generate session continuation handoff prompt
---

Analyze the current session and automatically generate a comprehensive handoff prompt that captures my current mental model, insights, and understanding.

## Session Analysis

Systematically analyze this session to understand:

1. **What we're working on** - Extract from conversation what task/problem is being addressed
2. **Current mental model** - What do I understand about the codebase, problem, and solution
3. **File changes** - Extract from tool usage (Read, Edit, Write) what files were modified and why
4. **Execution flow** - What commands were run, what worked, what failed
5. **Insights gained** - What did I learn during this session that next Claude must know
6. **Current position** - Where are we in the workflow (investigating, implementing, testing, blocked)
7. **Next logical steps** - Based on current state, what should next Claude do

## Auto-Detection

Automatically determine session type based on conversation:
- **DEBUG**: If investigating/fixing bugs, errors, failures
- **DEVELOPMENT**: If building features, adding functionality
- **HOTFIX**: If handling critical/emergency issues
- **INVESTIGATE**: If researching, exploring, analyzing

## Mental Model Transfer

The handoff must capture:
- **Problem understanding**: How do I currently understand the issue
- **Solution approach**: What strategy am I pursuing and why
- **Code insights**: What did I discover about how the code works
- **Assumptions**: What am I assuming to be true
- **Uncertainties**: What's still unclear or unknown
- **Context**: Why certain decisions were made

## Generate Complete Handoff

Using the appropriate template from SESSION_CONTINUATION_FORMAT.md:

1. **Automatically gather system state**:
   - `pwd` for working directory
   - `git status` for file changes and branch
   - `git log -3 --oneline` for recent commits
   - `docker ps` for running containers
   - Container health checks if applicable

2. **Extract from conversation**:
   - Modified files with line numbers (from tool usage)
   - Commands executed (from Bash tool usage)
   - Errors encountered (from tool results)
   - Solutions attempted (from conversation flow)
   - Current hypothesis/understanding (from my reasoning)

3. **Generate handoff sections**:
   - Executive Summary: 2-3 sentences capturing what we're doing and where we are
   - Problem Statement: What we're solving (for debug/hotfix/investigate)
   - Changes Made: Extract from Read/Edit/Write tool usage
   - Current Understanding: My mental model of the problem/solution
   - Next Steps: Logical continuation based on current state
   - Success Criteria: How to know when done

4. **Present the handoff**:
   - Show complete prompt in markdown code block
   - Explain what session type was detected
   - Highlight key insights that next Claude must understand
   - Ask if user wants to save to file or use as-is

## Key Principle

The generated handoff should allow next Claude to continue thinking and working exactly as I would - with the same understanding, insights, and mental model. Not just "here's what happened" but "here's what I know and understand."
