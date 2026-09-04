-- Migration: Add research execution metadata tracking
-- Purpose: Track WebSearch execution and research artifacts per agent

--------------------------------------------------------------------------------
-- Research Metadata Table
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS research_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL CHECK(agent_type IN ('official', 'academic', 'practical', 'expert')),
    search_iterations INTEGER DEFAULT 0,
    research_dir TEXT,
    artifacts_saved INTEGER DEFAULT 0,
    researched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confidence REAL DEFAULT 0.0 CHECK(confidence >= 0.0 AND confidence <= 1.0),
    search_failed INTEGER DEFAULT 0,
    failure_reason TEXT,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, agent_type)
);

--------------------------------------------------------------------------------
-- Indexes for Performance
--------------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_agent ON research_metadata(agent_type);
CREATE INDEX IF NOT EXISTS idx_research_failed ON research_metadata(search_failed);

--------------------------------------------------------------------------------
-- Verification Queries
--------------------------------------------------------------------------------

-- Check all agents ran for a goal
SELECT agent_type, search_iterations, search_failed
FROM research_metadata
WHERE goal_id = ?
ORDER BY agent_type;

-- Get agents with insufficient searches
SELECT agent_type, search_iterations
FROM research_metadata
WHERE goal_id = ? AND search_iterations < 3 AND search_failed = 0;

-- Get failed agents
SELECT agent_type, failure_reason
FROM research_metadata
WHERE goal_id = ? AND search_failed = 1;
