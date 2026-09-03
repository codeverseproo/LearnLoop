#!/bin/bash
# MIT Learning Skill Test Runner
DB="$HOME/.mit-learning/goals/test/memory.db"
PASSED=0; FAILED=0
for test in docs/superpowers/tests/unit/*.sql docs/superpowers/tests/integration/*.sql docs/superpowers/tests/edge-cases/*.sql; do
  RESULT=$(sqlite3 "$DB" < "$test" 2>&1)
  if echo "$RESULT" | grep -q "FAIL"; then FAILED=$((FAILED+1)); else PASSED=$((PASSED+1)); fi
done
echo "Passed: $PASSED | Failed: $FAILED"
test $FAILED -eq 0
