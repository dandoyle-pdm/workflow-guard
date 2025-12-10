#!/usr/bin/env bash
# test-hook-enforcement.sh - Test script for hook enforcement gaps implementation
#
# Tests all four use cases:
# UC-1: Block main thread reads (Read/Glob/Grep without agent context)
# UC-2: Block writes on protected branches (even with agent context)
# UC-3: Ticket lifecycle rules (queue vs sequenced tickets)
# UC-4: Agent context detection for all agents including Explore

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test counters
PASSED=0
FAILED=0

# Test functions
print_test_header() {
    echo ""
    echo "================================================================================"
    echo "  $1"
    echo "================================================================================"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

# Test UC-1: block-main-thread-reads.sh
test_read_hook() {
    print_test_header "UC-1: Block Main Thread Reads"

    local hook="./hooks/block-main-thread-reads.sh"

    # Test 1: Block Read without agent context
    print_test "Read without agent context should block"
    local json_no_agent=$(cat <<'EOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    echo "" > /tmp/empty-transcript.txt
    if echo "$json_no_agent" | bash "$hook" 2>/dev/null; then
        fail "Read without agent context was allowed"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Read without agent context blocked with exit 2"
        else
            fail "Read without agent context blocked but wrong exit code: $exit_code"
        fi
    fi

    # Test 2: Allow Read with Explore agent context
    print_test "Read with Explore agent context should allow"
    local json_explore=$(cat <<'EOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "transcript_path": "/tmp/explore-transcript.txt"
}
EOF
)
    echo "You are Explore working on investigation" > /tmp/explore-transcript.txt
    if echo "$json_explore" | bash "$hook" 2>/dev/null; then
        pass "Read with Explore agent context allowed"
    else
        fail "Read with Explore agent context was blocked"
    fi

    # Test 3: Allow Read with quality agent context
    print_test "Read with quality agent context should allow"
    local json_quality=$(cat <<'EOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "transcript_path": "/tmp/quality-transcript.txt"
}
EOF
)
    echo "You are working as the code-developer agent" > /tmp/quality-transcript.txt
    if echo "$json_quality" | bash "$hook" 2>/dev/null; then
        pass "Read with quality agent context allowed"
    else
        fail "Read with quality agent context was blocked"
    fi

    # Test 4: Block Glob without agent context
    print_test "Glob without agent context should block"
    local json_glob=$(cat <<'EOF'
{
  "tool_name": "Glob",
  "tool_input": {"pattern": "*.txt"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_glob" | bash "$hook" 2>/dev/null; then
        fail "Glob without agent context was allowed"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Glob without agent context blocked with exit 2"
        else
            fail "Glob without agent context blocked but wrong exit code: $exit_code"
        fi
    fi

    # Test 5: Block Grep without agent context
    print_test "Grep without agent context should block"
    local json_grep=$(cat <<'EOF'
{
  "tool_name": "Grep",
  "tool_input": {"pattern": "test"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_grep" | bash "$hook" 2>/dev/null; then
        fail "Grep without agent context was allowed"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Grep without agent context blocked with exit 2"
        else
            fail "Grep without agent context blocked but wrong exit code: $exit_code"
        fi
    fi
}

# Test UC-2 & UC-3: block-unreviewed-edits.sh with branch detection
test_write_hook() {
    print_test_header "UC-2 & UC-3: Branch Detection and Ticket Rules"

    local hook="./hooks/block-unreviewed-edits.sh"

    # Setup: Create test git repo to simulate branches
    local test_repo="/tmp/test-hook-repo"
    rm -rf "$test_repo"
    git init "$test_repo" >/dev/null 2>&1
    cd "$test_repo"
    git config user.email "test@example.com"
    git config user.name "Test User"
    mkdir -p tickets/queue tickets/active/my-branch tickets/completed
    echo "test" > README.md
    git add README.md
    git commit -m "initial" >/dev/null 2>&1

    # Test 1: Block write without agent context
    print_test "Write without agent context should block"
    local json_no_agent=$(cat <<'EOF'
{
  "tool_name": "Write",
  "tool_input": {"file_path": "test.txt"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_no_agent" | bash "$hook" 2>/dev/null; then
        fail "Write without agent context was allowed"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Write without agent context blocked"
        else
            fail "Write without agent context blocked but wrong exit code: $exit_code"
        fi
    fi

    # Test 2: Allow ticket queue file on main (no sequence)
    print_test "Ticket queue file (no sequence) on main should allow"
    git checkout -b main >/dev/null 2>&1
    local json_queue=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$test_repo/tickets/queue/TICKET-test-feature.md"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_queue" | bash "$hook" 2>/dev/null; then
        pass "Ticket queue file allowed on main"
    else
        fail "Ticket queue file was blocked on main"
    fi

    # Test 3: Block ticket with sequence on main
    print_test "Ticket with sequence on main should block"
    local json_sequence=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$test_repo/tickets/active/my-branch/TICKET-test-feature-001.md"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_sequence" | bash "$hook" 2>/dev/null; then
        fail "Ticket with sequence was allowed on main"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Ticket with sequence blocked on main"
        else
            fail "Ticket with sequence blocked but wrong exit code: $exit_code"
        fi
    fi

    # Test 4: Block quality agent write on main (non-ticket file)
    print_test "Quality agent write on main (non-ticket) should block"
    local json_quality_main=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$test_repo/src/code.js"},
  "transcript_path": "/tmp/quality-transcript.txt"
}
EOF
)
    if echo "$json_quality_main" | bash "$hook" 2>/dev/null; then
        fail "Quality agent write on main was allowed"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            pass "Quality agent write on main blocked"
        else
            fail "Quality agent write on main blocked but wrong exit code: $exit_code"
        fi
    fi

    # Test 5: Allow quality agent write on feature branch
    print_test "Quality agent write on feature branch should allow"
    git checkout -b feature/test-branch >/dev/null 2>&1
    local json_quality_feature=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$test_repo/src/code.js"},
  "transcript_path": "/tmp/quality-transcript.txt"
}
EOF
)
    if echo "$json_quality_feature" | bash "$hook" 2>/dev/null; then
        pass "Quality agent write on feature branch allowed"
    else
        fail "Quality agent write on feature branch was blocked"
    fi

    # Test 6: Allow ticket with sequence on feature branch
    print_test "Ticket with sequence on feature branch should allow"
    local json_sequence_feature=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$test_repo/tickets/active/my-branch/TICKET-test-feature-001.md"},
  "transcript_path": "/tmp/empty-transcript.txt"
}
EOF
)
    if echo "$json_sequence_feature" | bash "$hook" 2>/dev/null; then
        pass "Ticket with sequence allowed on feature branch"
    else
        fail "Ticket with sequence was blocked on feature branch"
    fi

    # Cleanup
    cd - >/dev/null 2>&1
    rm -rf "$test_repo"
}

# Test UC-4: Agent detection patterns
test_agent_detection() {
    print_test_header "UC-4: Agent Context Detection"

    local hook="./hooks/block-main-thread-reads.sh"

    # Test all quality agents
    local agents=("code-developer" "code-reviewer" "code-tester" "plugin-engineer" "plugin-reviewer" "plugin-tester")

    for agent in "${agents[@]}"; do
        print_test "Detect ${agent} agent context"
        local json=$(cat <<EOF
{
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "transcript_path": "/tmp/${agent}-transcript.txt"
}
EOF
)
        echo "You are working as the ${agent} agent on this task" > "/tmp/${agent}-transcript.txt"
        if echo "$json" | bash "$hook" 2>/dev/null; then
            pass "${agent} agent context detected"
        else
            fail "${agent} agent context not detected"
        fi
    done

    # Test Explore agent
    print_test "Detect Explore agent context"
    local json_explore=$(cat <<'EOF'
{
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "transcript_path": "/tmp/explore-agent-transcript.txt"
}
EOF
)
    echo "You are Explore investigating the codebase" > /tmp/explore-agent-transcript.txt
    if echo "$json_explore" | bash "$hook" 2>/dev/null; then
        pass "Explore agent context detected"
    else
        fail "Explore agent context not detected"
    fi
}

# Run all tests
main() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$script_dir"

    echo "================================================================================"
    echo "  Hook Enforcement Gaps - Test Suite"
    echo "================================================================================"

    test_read_hook
    test_write_hook
    test_agent_detection

    # Summary
    echo ""
    echo "================================================================================"
    echo "  Test Summary"
    echo "================================================================================"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""

    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"
