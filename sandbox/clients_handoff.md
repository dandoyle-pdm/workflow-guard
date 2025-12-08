Handoff: Quality Cycle Agents Enhancement

Context

During MWAA DAG tracking implementation in /home/ddoyle/workspace/clients, gaps were identified in quality
cycle workflow. Code-developer, code-reviewer, code-tester role prompts need enhancements.

Source Code to Introspect

/home/ddoyle/workspace/clients/mcp/internal/dagstate/
├── store.go (373 lines) - SQLite persistence
├── sync.go (248 lines) - MWAA sync with N+1 issues found
├── report.go (161 lines) - Change detection
├── \*\_test.go - 80% coverage

Code Review Findings That Inform Enhancements

| Severity | Issue Found                      | Gap in Reviewer Checklist              |
| -------- | -------------------------------- | -------------------------------------- |
| CRITICAL | Missing pagination (sync.go:136) | Need "unbounded list" check            |
| HIGH     | N+1 API calls (sync.go:171)      | Need "sequential API in loop" check    |
| HIGH     | Incomplete state mapping         | Need "enum completeness" check         |
| MEDIUM   | Interface duplicated             | Need "DRY across files" check          |
| MEDIUM   | No transaction batching          | Need "bulk operation efficiency" check |

Requested Enhancements

1. code-reviewer checklist additions

- Pagination on list operations returning >100 items
- Sequential API/DB calls inside loops (N+1 pattern)
- Enum/switch completeness for external data
- Transaction batching for bulk writes

2. code-developer self-check gates

- "Did I add pagination?" for any list endpoint
- "Did I consider concurrency?" for >10 sequential calls

3. Orchestration

developer → reviewer → (NEEDS_REVISION? → developer) → tester → DONE

Files Needing Fixes (for context)

- sync.go:136-142 - Add pagination loop
- sync.go:171-173 - Add worker pool for concurrent calls
- sync.go:218-229 - Add missing Airflow states
