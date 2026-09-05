#!/bin/bash
# ============================================
# LearnLoop Test Runner
# ============================================
# Runs all SQL tests against a migrated database
#
# Usage: ./run-tests.sh [goal_id]
# If goal_id provided, tests against that goal's database
# Otherwise, creates temporary in-memory database

set -e

DB_PATH=""

if [ -n "$1" ]; then
    DB_PATH="$HOME/.learnloop/goals/$1/memory.db"
    if [ ! -f "$DB_PATH" ]; then
        echo "ERROR: Database not found at $DB_PATH"
        exit 1
    fi
    echo "Testing against goal: $1"
else
    # Create temporary database with schema + migrations
    TEMP_DB=$(mktemp)
    sqlite3 "$TEMP_DB" ".read ../mcp-queries/schema.sql"
    sqlite3 "$TEMP_DB" ".read ../mcp-queries/migrations/008-p0-audit-fixes.sql"
    DB_PATH="$TEMP_DB"
    echo "Testing against temporary database"
fi

echo ""
echo "=== LearnLoop SQL Tests ==="
echo ""

# Run each test file
for test_file in unit/*.sql integration/*.sql validators/*.sql; do
    echo "--- Running: $test_file ---"
    sqlite3 "$DB_PATH" < "$test_file"
    echo ""
done

echo "=== All Tests Complete ==="

# Cleanup temp database
if [ -n "$TEMP_DB" ]; then
    rm "$TEMP_DB"
fi
