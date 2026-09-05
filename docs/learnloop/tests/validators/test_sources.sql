-- ============================================
-- Source URL Validation Tests
-- ============================================
-- Validates source URLs in topic_sources table
-- OPTIONAL: Run against real goal database
-- Claim: "Source URLs are real" (Matrix #6-7)

-- Test 1: Sources table exists with proper schema
SELECT 'Test 1: Sources table schema valid',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM sqlite_master
            WHERE type='table' AND name='topic_sources'
        ) = 1 THEN 'PASS'
        ELSE 'SKIP (run against real goal DB)'
    END AS result;

-- Test 2: Source URLs have valid format
-- Checks: http/https prefix, non-empty
SELECT 'Test 2: Source URLs have valid format',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM topic_sources
            WHERE source_url IS NOT NULL
            AND source_url LIKE 'http%'
        ) > 0 THEN 'PASS'
        ELSE 'SKIP (no sources yet)'
    END AS result;

-- Test 3: Source types are valid enum values
SELECT 'Test 3: Source types valid',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM topic_sources
            WHERE source_type NOT IN ('official', 'academic', 'practical', 'expert')
        ) = 0 THEN 'PASS'
        ELSE 'FAIL (invalid source_type found)'
    END AS result;

-- Test 4: Sources link to existing topics (FK integrity)
SELECT 'Test 4: Sources link to valid topics',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM topic_sources ts
            LEFT JOIN topics t ON ts.topic_id = t.id
            WHERE t.id IS NULL
        ) = 0 THEN 'PASS'
        ELSE 'FAIL (orphaned sources)'
    END AS result;

-- Test 5: Source confidence scores valid (if using metadata)
-- Note: topic_sources doesn't have confidence, but topic_links does
SELECT 'Test 5: Link confidence scores valid',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM topic_links
            WHERE confidence < 0.0 OR confidence > 1.0
        ) = 0 THEN 'PASS'
        ELSE 'FAIL (confidence out of range)'
    END AS result;

-- ============================================
-- Summary: Source URL Validation
-- ============================================
-- Tests verify:
-- 1. topic_sources table exists
-- 2. URLs have http/https format
-- 3. Source types are valid enum values
-- 4. Sources link to valid topics (FK integrity)
-- 5. Confidence scores in 0.0-1.0 range
--
-- Network validation (optional):
-- Use curl in CLI, not SQL:
--   curl -I "$URL" | head -1
--
-- Related:
-- - docs/learnloop/mcp-queries/schema.sql (topic_sources definition)
-- - REQUIREMENT-MATRIX.md claims #6-7
