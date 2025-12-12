#!/usr/bin/env bash
# counter.sh - Shared counter logic for QC Observer utilities
#
# Provides fail-safe sequence number generation with file locking.
# Used by observe-violation.sh and observe-iteration.sh.

# Get next sequence number (fail-safe)
# Returns 0 on failure, caller should proceed without sequence
get_next_sequence() {
    local counter_file="$1"
    local counter_dir
    counter_dir=$(dirname "${counter_file}")

    # Ensure directory exists
    if ! mkdir -p "${counter_dir}" 2>/dev/null; then
        echo "0"
        return 1
    fi

    # Try to acquire lock with timeout (5 seconds max)
    local lock_file="${counter_file}.lock"
    local lock_timeout=50  # 50 * 0.1s = 5 seconds
    local lock_attempts=0

    while [[ ${lock_attempts} -lt ${lock_timeout} ]]; do
        if mkdir "${lock_file}" 2>/dev/null; then
            break
        fi
        sleep 0.1
        lock_attempts=$((lock_attempts + 1))
    done

    if [[ ${lock_attempts} -ge ${lock_timeout} ]]; then
        echo "0"
        return 1
    fi

    # Lock acquired - read current counter
    local current_seq=0
    if [[ -f "${counter_file}" ]]; then
        current_seq=$(cat "${counter_file}" 2>/dev/null || echo "0")
        # Validate counter is numeric
        if ! [[ "${current_seq}" =~ ^[0-9]+$ ]]; then
            current_seq=0
        fi
    fi

    # Increment and write back
    local next_seq=$((current_seq + 1))
    if ! printf '%d\n' "${next_seq}" > "${counter_file}" 2>/dev/null; then
        # Release lock
        rmdir "${lock_file}" 2>/dev/null || true
        echo "0"
        return 1
    fi

    # Release lock
    rmdir "${lock_file}" 2>/dev/null || true

    # Return next sequence
    echo "${next_seq}"
    return 0
}
