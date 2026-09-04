-- ============================================
-- Telemetry Archival - Phase Cleanup
-- ============================================
-- Archive completed phases older than 90 days to maintain performance
-- Moves old telemetry records from phase_telemetry to archive storage
--
-- Parameters: :archival_date (default: date('now', '-90 days'))
--
-- Returns: Archived record count per goal
--
-- Usage: Run weekly via scheduled maintenance task
-- ============================================

-- Step 1: Select records for archival
WITH old_telemetry AS (
    SELECT
        goal_id,
        phase,
        wave,
        agent_type,
        started_at,
        completed_at,
        duration_seconds,
        success,
        error_message,
        error_code,
        gate_result
    FROM phase_telemetry
    WHERE completed_at IS NOT NULL
      AND completed_at < :archival_date
)
SELECT
    goal_id,
    COUNT(*) AS archived_count,
    MIN(started_at) AS oldest_record,
    MAX(completed_at) AS newest_record
FROM old_telemetry
GROUP BY goal_id
ORDER BY goal_id;

-- Step 2: Delete archived records (run after confirming archival)
-- DELETE FROM phase_telemetry
-- WHERE completed_at IS NOT NULL
--   AND completed_at < :archival_date;
