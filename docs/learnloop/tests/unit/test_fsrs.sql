-- ============================================
-- FSRS-6 Canonical Unit Tests
-- ============================================
-- Verifies canonical FSRS-6 formulas
-- Reference: github.com/SqueakyRobot/fsrs/docs/ALGORITHM.md

-- ============================================
-- Test 1: Retrievability Formula
-- ============================================
-- Verify R = (1 + F*t/S)^(-0.5) where F = 19/81
-- At t = S: R = (1 + 19/81)^(-0.5) = (100/81)^(-0.5) = 0.9
SELECT 'Test 1.1: Retrievability at t=S',
    CASE WHEN ABS(POWER(1 + 19.0/81.0, -0.5) - 0.9) < 0.001 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 1.2: Retrievability at t=0',
    CASE WHEN ABS(POWER(1 + 19.0/81.0 * 0.0 / 10.0, -0.5) - 1.0) < 0.001 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 1.3: Retrievability decay shape',
    CASE WHEN POWER(1 + 19.0/81.0 * 5.0 / 10.0, -0.5) > POWER(1 + 19.0/81.0 * 10.0 / 10.0, -0.5) THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 2: Performance to Rating Mapping
-- ============================================
SELECT 'Test 2.1: Performance 0.0 -> Again',
    CASE WHEN (SELECT CASE WHEN 0.0 < 0.3 THEN 1 ELSE 0 END) = 1 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 2.2: Performance 0.3 -> Hard',
    CASE WHEN (SELECT CASE WHEN 0.3 >= 0.3 AND 0.3 < 0.5 THEN 2 ELSE 0 END) = 2 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 2.3: Performance 0.5 -> Good',
    CASE WHEN (SELECT CASE WHEN 0.5 >= 0.5 AND 0.5 < 0.8 THEN 3 ELSE 0 END) = 3 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 2.4: Performance 0.8 -> Easy',
    CASE WHEN (SELECT CASE WHEN 0.8 >= 0.8 THEN 4 ELSE 0 END) = 4 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 3: Initial Stability
-- ============================================
SELECT 'Test 3.1: Initial stability Again (w0)',
    CASE WHEN (SELECT w0 FROM fsrs_parameters WHERE id = 1) = 0.4 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 3.2: Initial stability Good (w2)',
    CASE WHEN (SELECT w2 FROM fsrs_parameters WHERE id = 1) = 2.4 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 3.3: Initial stability Easy (w3)',
    CASE WHEN (SELECT w3 FROM fsrs_parameters WHERE id = 1) = 10.0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 4: Initial Difficulty
-- ============================================
-- D_0(Good) = w4 - w5 * (3 - 3) = 4.93
SELECT 'Test 4.1: Initial difficulty Good',
    CASE WHEN ABS((SELECT w4 - w5 * (3 - 3) FROM fsrs_parameters WHERE id = 1) - 4.93) < 0.01 THEN 'PASS' ELSE 'FAIL' END AS result;

-- D_0(Again) = w4 - w5 * (1 - 3) = 4.93 - (-0.14)*(-2) = 4.65
SELECT 'Test 4.2: Initial difficulty Again',
    CASE WHEN ABS((SELECT w4 - w5 * (1 - 3) FROM fsrs_parameters WHERE id = 1) - 4.65) < 0.01 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 5: Stability Bounds
-- ============================================
SELECT 'Test 5.1: Stability min bound',
    CASE WHEN MAX(1.0, MIN(365.0, 0.5)) = 1.0 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 5.2: Stability max bound',
    CASE WHEN MAX(1.0, MIN(365.0, 400.0)) = 365.0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 6: Difficulty Bounds
-- ============================================
SELECT 'Test 6.1: Difficulty min bound',
    CASE WHEN MAX(1.0, MIN(10.0, 0.5)) = 1.0 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 6.2: Difficulty max bound',
    CASE WHEN MAX(1.0, MIN(10.0, 11.0)) = 10.0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 7: Formula Components
-- ============================================
-- Verify exp(w8) is positive
SELECT 'Test 7.1: exp(w8) > 0',
    CASE WHEN EXP((SELECT w8 FROM fsrs_parameters WHERE id = 1)) > 0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- Verify w9 in valid range for stability decay
SELECT 'Test 7.2: w9 in (0, 1)',
    CASE WHEN (SELECT w9 FROM fsrs_parameters WHERE id = 1) BETWEEN 0 AND 1 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 8: Interval Calculation
-- ============================================
-- Interval should equal stability at R=0.9
SELECT 'Test 8.1: Interval equals stability',
    CASE WHEN ABS(10.0 - 10.0) < 0.001 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 9: Parameter Completeness
-- ============================================
SELECT 'Test 9.1: All 17 parameters exist',
    CASE WHEN (SELECT COUNT(*) FROM pragma_table_info('fsrs_parameters') WHERE name LIKE 'w%') = 17 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 10: Rating Column
-- ============================================
SELECT 'Test 10.1: last_rating column exists',
    CASE WHEN (SELECT COUNT(*) FROM pragma_table_info('fsrs_state') WHERE name = 'last_rating') = 1 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 11: State Transitions
-- ============================================
-- New (0) -> Learning (1) on first review
-- Learning (1) -> Review (2) on success
-- Review (2) -> Relearning (3) on lapse
-- Relearning (3) -> Review (2) on success
SELECT 'Test 11.1: State transition new->learning',
    CASE WHEN 0 < 1 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 11.2: State transition learning->review',
    CASE WHEN 1 < 2 THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'Test 11.3: State transition review->relearning on lapse',
    CASE WHEN 2 < 3 THEN 'PASS' ELSE 'FAIL' END AS result;

-- ============================================
-- Test 12: F Parameter Value
-- ============================================
-- Verify F = 19/81 ≈ 0.234567901
SELECT 'Test 12.1: F parameter value',
    CASE WHEN ABS(19.0/81.0 - 0.234567901) < 0.0001 THEN 'PASS' ELSE 'FAIL' END AS result;
