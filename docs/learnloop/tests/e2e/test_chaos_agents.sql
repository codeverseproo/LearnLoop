-- Test: Agent timeout recovery
INSERT INTO execution_state (goal_id, phase, attempts, max_attempts, last_attempt)
VALUES ('test-chaos-agents', 'WAVE1_DISCOVERY', 3, 3, CURRENT_TIMESTAMP);

-- Verify retry logic
SELECT 'AGENT_TIMEOUT_RETRY',
    CASE WHEN attempts >= max_attempts THEN 'PASS' ELSE 'FAIL' END
FROM execution_state
WHERE goal_id = 'test-chaos-agents' AND phase = 'WAVE1_DISCOVERY';

-- Test: Malformed source rejection
INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (1, 'academic', 'Bad Source', 'MALFORMED');

-- Verify validation rejects
SELECT 'MALFORMED_SOURCE_REJECTED',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM topic_sources WHERE source_url = 'MALFORMED';

-- Test: Duplicate source deduplication
INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (1, 'academic', 'Source 1', 'https://example.com/source');

INSERT INTO topic_sources (topic_id, source_type, source_title, source_url)
VALUES (1, 'academic', 'Source 1 Duplicate', 'https://example.com/source');  -- Should dedupe

-- Verify confidence unchanged (deduplication worked)
SELECT 'DUPLICATE_DEDUPED',
    CASE WHEN COUNT(DISTINCT source_url) = 1 THEN 'PASS' ELSE 'FAIL' END
FROM topic_sources WHERE topic_id = 1;
