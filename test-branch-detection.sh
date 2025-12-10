#!/usr/bin/env bash
# Test script to verify branch detection fix in block-unreviewed-edits.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="${SCRIPT_DIR}/hooks/block-unreviewed-edits.sh"

echo "Testing branch detection security fix..."
echo

# Test 1: Empty cwd with non-git directory should block
echo "Test 1: Empty cwd with non-git directory"
test_json=$(cat <<'EOF'
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test-file.txt"
  },
  "transcript_path": "/dev/null",
  "cwd": ""
}
EOF
)

if echo "$test_json" | bash "$HOOK" 2>&1; then
    echo "  FAILED: Should have blocked operation"
    exit 1
else
    exit_code=$?
    if [[ $exit_code -eq 2 ]]; then
        echo "  PASSED: Blocked with exit 2 (fail-secure)"
    else
        echo "  FAILED: Wrong exit code: $exit_code"
        exit 1
    fi
fi

echo

# Test 2: Valid git directory should succeed
echo "Test 2: Valid git directory with workflow metadata"
test_json=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "${SCRIPT_DIR}/tickets/queue/TICKET-test.md"
  },
  "transcript_path": "/dev/null",
  "cwd": "${SCRIPT_DIR}"
}
EOF
)

if echo "$test_json" | bash "$HOOK" 2>&1; then
    echo "  PASSED: Allowed workflow metadata in valid git repo"
else
    echo "  FAILED: Should have allowed workflow metadata"
    exit 1
fi

echo

# Test 3: Empty cwd with valid git directory via dirname fallback
echo "Test 3: Empty cwd with valid git directory via dirname fallback"
test_json=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "${SCRIPT_DIR}/tickets/queue/TICKET-test.md"
  },
  "transcript_path": "/dev/null",
  "cwd": ""
}
EOF
)

if echo "$test_json" | bash "$HOOK" 2>&1; then
    echo "  PASSED: Allowed workflow metadata with dirname fallback"
else
    echo "  FAILED: Should have allowed workflow metadata with dirname fallback"
    exit 1
fi

echo
echo "All tests passed!"
