#!/bin/bash
# ============================================
# LearnLoop E2E Test Runner
# ============================================
# Runs all E2E test files sequentially and reports pass/fail status

set -euo pipefail

# ============================================
# Configuration
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SCHEMA_PATH="$PROJECT_ROOT/docs/learnloop/mcp-queries/schema.sql"

# Default DB path (can be overridden via argument)
DB_PATH="${1:-$HOME/.learnloop/goals/test-e2e/memory.db}"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================
# Functions
# ============================================

log_info() {
    echo "[INFO] $1"
}

log_pass() {
    echo "[PASS] $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

log_fail() {
    echo "[FAIL] $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

cleanup_wal() {
    local db_dir
    db_dir="$(dirname "$DB_PATH")"
    rm -f "$db_dir"/*.db-wal "$db_dir"/*.db-shm 2>/dev/null || true
}

initialize_db() {
    local db_dir
    db_dir="$(dirname "$DB_PATH")"

    # Create directory if needed
    mkdir -p "$db_dir"

    # Create DB if missing
    if [[ ! -f "$DB_PATH" ]]; then
        log_info "Creating test DB: $DB_PATH"
        sqlite3 "$DB_PATH" < "$SCHEMA_PATH"
    fi

    # Verify schema loaded
    if ! sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' LIMIT 1" >/dev/null 2>&1; then
        echo "[ERROR] Failed to initialize DB with schema"
        exit 1
    fi

    log_info "DB initialized successfully"
}

run_test_file() {
    local test_file="$1"
    local test_name
    test_name="$(basename "$test_file" .sql)"

    log_info "Running: $test_name"

    # Run test and capture output
    if output=$(sqlite3 "$DB_PATH" < "$test_file" 2>&1); then
        # Check for FAIL in output
        if echo "$output" | grep -q "FAIL"; then
            log_fail "$test_name"
            echo "$output"
        else
            log_pass "$test_name"
            echo "$output"
        fi
    else
        log_fail "$test_name (SQL error)"
        echo "$output"
    fi

    # Cleanup WAL between tests
    cleanup_wal

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# ============================================
# Main Execution
# ============================================

log_info "============================================"
log_info "LearnLoop E2E Test Runner"
log_info "============================================"
log_info "DB Path: $DB_PATH"
log_info "Schema: $SCHEMA_PATH"
log_info ""

# Verify schema exists
if [[ ! -f "$SCHEMA_PATH" ]]; then
    echo "[ERROR] Schema not found: $SCHEMA_PATH"
    exit 1
fi

# Initialize DB
initialize_db

# Find and run all test files
log_info "Running E2E tests..."
log_info ""

for test_file in "$SCRIPT_DIR"/test_*.sql; do
    if [[ -f "$test_file" ]]; then
        run_test_file "$test_file"
        echo ""
    fi
done

# ============================================
# Summary
# ============================================
log_info "============================================"
log_info "Test Summary"
log_info "============================================"
echo "Total:  $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
log_info "============================================"

# Exit with failure if any tests failed
if [[ $FAILED_TESTS -gt 0 ]]; then
    exit 1
fi

exit 0
