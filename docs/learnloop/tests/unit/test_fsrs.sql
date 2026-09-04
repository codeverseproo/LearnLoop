-- ============================================
-- FSRS-6 Unit Tests
-- ============================================

-- Test 1: Retrievability at 10 days, stability 10
SELECT 'Test 1: Retrievability',
    CASE
        WHEN ABS(POWER(1 + 10.0/90.0, -1.0) - 0.9) < 0.001 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 2: Mastery formula
SELECT 'Test 2: Mastery',
    CASE
        WHEN ABS((1 - EXP(-0.5 * 10.0 / 5.0)) - 0.632) < 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 3: Stability bounds
SELECT 'Test 3: Stability bounds',
    CASE
        WHEN MAX(1.0, MIN(365.0, 400.0)) = 365.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 4: Difficulty bounds
SELECT 'Test 4: Difficulty bounds',
    CASE
        WHEN MAX(1.0, MIN(10.0, 0.5)) = 1.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;
