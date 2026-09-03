-- Migration 001: Add topic sources and links tables
-- Run after schema.sql

-- Add new columns to topics table
ALTER TABLE topics ADD COLUMN confidence REAL DEFAULT 1.0;
ALTER TABLE topics ADD COLUMN source_count INTEGER DEFAULT 0;
ALTER TABLE topics ADD COLUMN is_hidden INTEGER DEFAULT 0;
ALTER TABLE topics ADD COLUMN detection_method TEXT CHECK(detection_method IN ('complexity_analysis', 'error_pattern', 'expert_practice'));

-- Topic links table (non-prerequisite relationships)
CREATE TABLE IF NOT EXISTS topic_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_topic INTEGER NOT NULL,
    to_topic INTEGER NOT NULL,
    link_type TEXT NOT NULL CHECK(link_type IN ('enabled_by', 'related_to', 'cross_domain')),
    confidence REAL DEFAULT 1.0 CHECK(confidence >= 0.0 AND confidence <= 1.0),
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_topic) REFERENCES topics(id),
    FOREIGN KEY (to_topic) REFERENCES topics(id),
    UNIQUE(from_topic, to_topic, link_type)
);

-- Topic sources table (source citations)
CREATE TABLE IF NOT EXISTS topic_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN ('official', 'academic', 'practical', 'expert')),
    source_title TEXT NOT NULL,
    source_url TEXT,
    source_date DATE,
    cited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_topic_links_from ON topic_links(from_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_to ON topic_links(to_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_type ON topic_links(link_type);
CREATE INDEX IF NOT EXISTS idx_topic_sources_topic ON topic_sources(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_sources_type ON topic_sources(source_type);
CREATE INDEX IF NOT EXISTS idx_topics_hidden ON topics(is_hidden);
CREATE INDEX IF NOT EXISTS idx_topics_detection ON topics(detection_method);
