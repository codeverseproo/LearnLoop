-- ============================================
-- LearnLoop - Error Registry Migration
-- ============================================
-- Migration: 010-error-registry.sql
-- Purpose: Centralized error code registry with user-facing messages
-- Created: 2026-09-05
-- ============================================

-- Create error registry table
CREATE TABLE IF NOT EXISTS error_registry (
    error_code TEXT PRIMARY KEY,
    category TEXT NOT NULL CHECK(category IN ('system', 'topic', 'research', 'interview', 'goal', 'fsrs', 'session', 'vault')),
    severity TEXT NOT NULL CHECK(severity IN ('critical', 'high', 'medium', 'low')),
    message_template TEXT NOT NULL,
    user_message TEXT NOT NULL,
    recovery_action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for category lookups
CREATE INDEX IF NOT EXISTS idx_error_category ON error_registry(category);
CREATE INDEX IF NOT EXISTS idx_error_severity ON error_registry(severity);

-- ============================================
-- E0XX: Input/Goal Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E001', 'goal', 'high', 'Goal database already exists: {goal_id}',
 'A learning goal with this name already exists. Choose a different name or continue with the existing goal.',
 'Use unique goal name or load existing goal'),

('E002', 'fsrs', 'medium', 'Tolerance parameter out of range: {tolerance}',
 'Invalid learning preference setting. Default settings will be used.',
 'Reset tolerance to default (0.9)'),

('E003', 'goal', 'high', 'Maximum 3 concurrent goals exceeded',
 'You have reached the maximum of 3 active learning goals. Complete or archive a goal before creating a new one.',
 'Archive inactive goal or upgrade to premium'),

('E004', 'goal', 'high', 'Invalid goal_id format: {goal_id}',
 'The goal name contains invalid characters. Use only letters, numbers, hyphens, and spaces.',
 'Use alphanumeric characters and hyphens only'),

('E005', 'goal', 'high', 'Invalid goal_type: {goal_type}',
 'Invalid goal type specified. Please choose from: exam, skill, degree, or topic.',
 'Select valid goal type: exam, skill, degree, or topic');

-- ============================================
-- E1XX: State/Topic Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E101', 'topic', 'medium', 'Topic not found: {topic_id}',
 'The requested topic does not exist in your syllabus. It may have been removed or archived.',
 'Check topic_id or regenerate syllabus'),

('E102', 'goal', 'high', 'Maximum goals reached (limit: 3)',
 'Maximum number of concurrent goals reached. You can have up to 3 active learning goals at once.',
 'Archive completed goal to create new one'),

('E103', 'vault', 'critical', 'Obsidian vault not initialized',
 'Your note-taking vault is not set up. Learning notes cannot be saved until this is configured.',
 'Configure vault path in settings or run setup'),

('E104', 'session', 'medium', 'Session already in progress',
 'You have an active learning session running. Please complete or cancel it before starting a new one.',
 'Complete current session or cancel to proceed');

-- ============================================
-- E2XX: Calculation/FSRS Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E201', 'fsrs', 'high', 'Invalid stability value: {stability}',
 'An error occurred in the spaced repetition algorithm. Your progress has been saved with default settings.',
 'Reset FSRS state to defaults'),

('E202', 'fsrs', 'high', 'Invalid difficulty value: {difficulty}',
 'Difficulty setting is out of range. Default difficulty level (5.0) has been applied.',
 'Ensure difficulty is between 1.0 and 10.0'),

('E203', 'fsrs', 'high', 'Invalid performance score: {performance}',
 'Performance score must be between 0 and 100 percent. Your session data has been saved.',
 'Ensure performance is between 0.0 and 1.0'),

('E204', 'fsrs', 'critical', 'Numerical overflow in FSRS calculation',
 'A calculation error occurred in the learning algorithm. This topic has been reset to prevent data loss.',
 'Report issue with topic details; reset topic FSRS state');

-- ============================================
-- E3XX: Vault Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E301', 'vault', 'critical', 'Cannot write to Obsidian vault: {path}',
 'Unable to save your learning notes. Please check that Obsidian is installed and the vault path is correct.',
 'Check vault permissions and path in settings'),

('E302', 'topic', 'high', 'Invalid topic_id format: {topic_id}',
 'Topic name contains invalid characters. Use only letters, numbers, hyphens, and underscores.',
 'Use alphanumeric characters and hyphens'),

('E303', 'vault', 'medium', 'Note not found: {note_path}',
 'The learning note for this topic cannot be found. It may have been moved or deleted externally.',
 'Regenerate topic note from syllabus'),

('E304', 'vault', 'medium', 'Cannot archive topic: {topic_id}',
 'Unable to move this topic to archive. Topic data is preserved in the database.',
 'Manually move note or check vault permissions');

-- ============================================
-- E4XX: Session Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E401', 'session', 'low', 'Session timeout after {duration} minutes',
 'Your learning session timed out due to inactivity. Progress has been saved automatically.',
 'Resume session or start new session'),

('E402', 'session', 'low', 'Assessment incomplete: {topic_id}',
 'You left before completing the assessment. Your partial progress has been saved.',
 'Resume assessment or restart when ready'),

('E403', 'session', 'low', 'Session cancelled by user',
 'Learning session was cancelled. Any unsaved progress may be lost.',
 'No action needed; start new session to continue');

-- ============================================
-- E5XX: Research Errors
-- ============================================
-- NOTE: E501-E503 have COLLISION:
--   Lines 1364-1366: E501/E502/E503 used for research engine errors
--   Lines 1445-1449: E501-E506 used for error recovery scenarios
-- SOLUTION: Renumber research engine errors to E511-E513

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
-- Renumbered from E501-E503 to E511-E513 (research engine errors)
('E511', 'research', 'medium', 'Source unreachable: {url}',
 'Unable to access one or more research sources. The syllabus may be less comprehensive without these sources.',
 'Retry with alternate sources or proceed with available data'),

('E512', 'research', 'high', 'Insufficient sources for claim: {claim_id}',
 'Unable to find enough credible sources to verify a claim. This topic will be marked with low confidence.',
 'Expand search scope or accept lower confidence'),

('E513', 'research', 'medium', 'Cannot triangulate sources for claim: {claim_id}',
 'Unable to cross-verify this claim across multiple independent sources.',
 'Review source quality or accept single-source claim'),

-- E5XX: Error Recovery Scenarios (E501-E506 for user choice protocol)
('E501', 'research', 'medium', 'WebSearch timeout for topic: {topic_name}',
 'The search for learning resources timed out. You can retry, test your connection, proceed without this topic, or cancel.',
 'Retry/Test Connection/Proceed Without/Cancel'),

('E502', 'research', 'medium', 'Insufficient sources for topic: {topic_name}',
 'Not enough sources were found for this topic. You can retry the search, proceed with limited sources, or cancel.',
 'Retry/Proceed with Limited Sources/Cancel'),

('E504', 'system', 'high', 'Agent spawn failed: {agent_type}',
 'Unable to start a background research process. This may affect syllabus quality.',
 'Retry agent spawn or proceed with reduced research'),

('E505', 'system', 'high', 'Gate check failed: {gate_name}',
 'A quality check failed during syllabus generation. The output may not meet quality standards.',
 'Retry gate/Skip with warnings/Cancel'),

('E506', 'system', 'medium', 'Maximum repair cycles reached',
 'The system made multiple attempts to fix issues but was unable to resolve all problems.',
 'Accept syllabus with warnings/Manual review/Cancel');

-- ============================================
-- E6XX: System Errors
-- ============================================

INSERT INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action)
VALUES
('E601', 'research', 'high', 'Research contradiction detected: {topic_id}',
 'Sources present conflicting information. The syllabus reflects the majority view with a note about the contradiction.',
 'Review conflicting sources; select authoritative source'),

('E602', 'system', 'critical', 'Database locked',
 'Your learning database is temporarily locked. This usually resolves automatically within a few seconds.',
 'Wait 30 seconds and retry; restart app if persistent'),

('E603', 'fsrs', 'high', 'FSRS runtime error',
 'An unexpected error occurred in the spaced repetition algorithm. Default settings have been applied for this session.',
 'Report issue with error details; topic reset to defaults'),

('E699', 'system', 'critical', 'Unknown error: {error_details}',
 'An unexpected error occurred. Your progress has been saved, but some features may be temporarily unavailable.',
 'Report issue with reproduction steps; check logs');

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify all error codes inserted
SELECT 'Error Registry: ' || COUNT(*) || ' error codes registered'
FROM error_registry;

-- Check for any missing user_message (should return 0 rows)
SELECT error_code, message_template
FROM error_registry
WHERE user_message IS NULL OR user_message = '';

-- Group by category
SELECT category, COUNT(*) as count
FROM error_registry
GROUP BY category
ORDER BY category;

-- Check severity distribution
SELECT severity, COUNT(*) as count
FROM error_registry
GROUP BY severity
ORDER BY
  CASE severity
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
  END;
