-- ============================================
-- P0-8: WebSearch Count Enforcement
-- Ensure minimum 10 searches in repair loop
-- ============================================

SELECT
    es.goal_id,
    es.phase,
    es.repair_search_count,
    es.repair_cycles,
    CASE
        WHEN es.repair_search_count >= 10 THEN 'PASS'
        WHEN es.repair_cycles = 0 THEN 'SKIP: First cycle'
        ELSE 'BLOCK: Below minimum (need 10, have ' || es.repair_search_count || ')'
    END as guard_status,
    CASE
        WHEN es.repair_search_count >= 10 THEN 'WebSearch requirement met'
        WHEN es.repair_cycles = 0 THEN 'First repair cycle - WebSearch tracking active'
        ELSE 'Complete at least 10 WebSearch calls before proceeding'
    END as message
FROM execution_state es
WHERE es.goal_id = :goal_id AND es.phase = 'WAVE4_REPAIR';
