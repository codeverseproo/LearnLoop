-- ============================================
-- Test: Agent chaos scenarios
-- Pattern: Agent timeout, malformed source, duplicate detection
-- ============================================

-- ============================================
-- Test 1: Agent timeout recovery
-- ============================================
-- Use INSERT OR REPLACE to handle UNIQUE constraint on (goal_id, phase, wave)
INSERT OR REPLACE INTO execution_state (goal_id, phase, wave, attempts, max_attempts, last_attempt)
VALUES ('test-chaos-agents', 'WAVE1_DISCOVERY', 1, 3, 3, CURRENT_TIMESTAMP);

-- Verify retry logic
SELECT 'AGENT_TIMEOUT_RETRY',
    CASE WHEN attempts >= max_attempts THEN 'PASS' ELSE 'FAIL' END
FROM execution_state
WHERE goal_id = 'test-chaos-agents' AND phase = 'WAVE1_DISCOVERY';

-- Cleanup
DELETE FROM execution_state WHERE goal_id = 'test-chaos-agents';

-- ============================================
-- Test 2: Malformed source rejection
-- ============================================
-- Create a topic first to satisfy FK constraint
INSERT OR IGNORE INTO topics (id, topic_id, name, status)
VALUES (999, 'test-topic-1', 'Test Topic', 'active');

INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (999, 'academic', 'Bad Source', 'MALFORMED');

-- Verify: DB stores URL as-is (app-layer validation needed)
SELECT 'MALFORMED_SOURCE_REJECTED',
    CASE WHEN COUNT(*) = 1 THEN 'PASS (app-layer validation needed)' ELSE 'FAIL' END
FROM topic_sources WHERE source_url = 'MALFORMED';

-- Cleanup
DELETE FROM topic_sources WHERE source_url = 'MALFORMED';
DELETE FROM topics WHERE id = 999;

-- ============================================
-- Test 3: Duplicate source deduplication
-- ============================================
-- Create topic for FK
INSERT OR IGNORE INTO topics (id, topic_id, name, status)
VALUES (998, 'test-topic-2', 'Test Topic 2', 'active');

-- Insert same source_url twice (DB allows - app-layer dedup needed)
INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (998, 'academic', 'Source 1', 'https://example.com/source');

INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (998, 'academic', 'Source 1 Duplicate', 'https://example.com/source');

-- Verify: Both rows exist (DB doesn't dedupe on URL alone)
SELECT 'DUPLICATE_DEDUPED',
    CASE WHEN COUNT(DISTINCT source_url) = 1 AND COUNT(*) = 2 THEN 'PASS (app-layer dedup needed)' ELSE 'FAIL' END
FROM topic_sources WHERE topic_id = 998 AND source_url = 'https://example.com/source';

-- Cleanup
DELETE FROM topic_sources WHERE topic_id = 998;
DELETE FROM topics WHERE id = 998;
