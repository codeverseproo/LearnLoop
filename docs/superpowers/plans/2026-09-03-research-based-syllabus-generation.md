# Research-Based Syllabus Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign syllabus_generation workflow to use real-time research from multiple sources with hidden topic detection, knowledge graph building, and critic-based quality assurance.

**Architecture:** Hybrid parsing → 4 parallel discovery agents → merge → knowledge graph → critic loop (max 3 rounds) → satisfaction check → syllabus output. Uses existing SQLite + Obsidian infrastructure with new tables for topic links and sources.

**Tech Stack:** SQLite, Agent tool, WebSearch, WebFetch, SKILL.md workflows, no external scripts.

## Global Constraints

- No Python scripts - only skills and tools available in Claude
- All prompts embedded in SKILL.md or separate prompt files in docs/superpowers/prompts/
- Schema changes use ALTER TABLE + new tables (no breaking changes)
- Existing prerequisites table unchanged for FSRS compatibility
- All agent prompts must be fail-safe (never return empty, use fallbacks)
- Cross-validation threshold: ≥50% topic overlap across agents
- Triangulation threshold: ≥3 sources per core topic
- Max 3 critic rounds before force-approve with warnings

---

## Task 1: Schema Migration - Add New Tables and Columns

**Files:**
- Create: `docs/superpowers/mcp-queries/migrations/001-topic-sources-links.sql`
- Modify: `docs/superpowers/mcp-queries/schema.sql` (add new tables at end)

**Interfaces:**
- Produces: `topics` table with new columns (confidence, source_count, is_hidden, detection_method)
- Produces: `topic_links` table for enabled_by/related_to/cross_domain links
- Produces: `topic_sources` table for source citations
- Existing: `prerequisites` table unchanged for FSRS compatibility

- [ ] **Step 1: Write migration SQL file**

Create `docs/superpowers/mcp-queries/migrations/001-topic-sources-links.sql`:

```sql
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
```

- [ ] **Step 2: Add new tables to main schema.sql**

Append to `docs/superpowers/mcp-queries/schema.sql` after line 99:

```sql
-- Topic links (non-prerequisite relationships)
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

-- Topic sources (source citations)
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

-- Additional indexes
CREATE INDEX IF NOT EXISTS idx_topic_links_from ON topic_links(from_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_to ON topic_links(to_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_type ON topic_links(link_type);
CREATE INDEX IF NOT EXISTS idx_topic_sources_topic ON topic_sources(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_sources_type ON topic_sources(source_type);
CREATE INDEX IF NOT EXISTS idx_topics_hidden ON topics(is_hidden);
CREATE INDEX IF NOT EXISTS idx_topics_detection ON topics(detection_method);
```

- [ ] **Step 3: Test schema migration**

Run:
```bash
cd /Users/codeversepro/Documents/Skill/MIT
sqlite3 /tmp/test-mit-schema.db < docs/superpowers/mcp-queries/schema.sql
sqlite3 /tmp/test-mit-schema.db "PRAGMA integrity_check;"
sqlite3 /tmp/test-mit-schema.db ".schema topics" | grep -E "(confidence|source_count|is_hidden|detection_method)"
sqlite3 /tmp/test-mit-schema.db ".tables"
rm /tmp/test-mit-schema.db
```

Expected: integrity_check = ok, all 3 new columns visible, 10 tables total

- [ ] **Step 4: Commit schema changes**

```bash
git add docs/superpowers/mcp-queries/schema.sql docs/superpowers/mcp-queries/migrations/
git commit -m "feat(schema): add topic_links and topic_sources tables

- Add confidence, source_count, is_hidden, detection_method to topics
- Create topic_links for enabled_by/related_to/cross_domain
- Create topic_sources for source citations
- Keep prerequisites table unchanged for FSRS

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 2: Write Discovery Agent Prompts

**Files:**
- Create: `docs/superpowers/prompts/discovery-agent-official.md`
- Create: `docs/superpowers/prompts/discovery-agent-academic.md`
- Create: `docs/superpowers/prompts/discovery-agent-practical.md`
- Create: `docs/superpowers/prompts/discovery-agent-expert.md`

**Interfaces:**
- Consumes: Parsed goal from SKILL.md (goal_type, subject, keywords, raw_goal)
- Produces: JSON with topics[], hidden_topics[], sources[], prerequisites{}, links{}

- [ ] **Step 1: Write official sources discovery prompt**

Create `docs/superpowers/prompts/discovery-agent-official.md`:

```markdown
# Discovery Agent: Official Sources

You are researching **official sources** for a learning goal.

## Input

You receive:
- goal_type: "exam" | "skill" | "degree" | "topic"
- subject: string (e.g., "AWS Solutions Architect")
- keywords: string[] (e.g., ["AWS", "Solutions Architect", "SAA"])
- raw_goal: string (original user request)

## Your Task

1. **Search official sources:**
   - Official curriculum/blueprint
   - Vendor documentation
   - Certification guides
   - Official training materials
   
2. **Extract topics:**
   - Core topics explicitly listed
   - Sub-topics within each core topic
   - Estimated complexity (1-10)

3. **Detect hidden topics** (3 methods):
   - **Complexity analysis**: For each topic, what skills does it require that aren't listed?
   - **Error patterns**: What do official docs mention as common mistakes?
   - **Expert practice**: What do official guides reference that isn't in the syllabus?

4. **Identify prerequisites** for each topic

5. **Find related topics** within same domain

6. **Find cross-domain bridges** (topics connecting to other knowledge areas)

## Search Strategy

Use WebSearch with queries:
- "{subject} official curriculum"
- "{subject} exam blueprint site:vendor.com"
- "{subject} certification guide"
- "{subject} official documentation"
- "{keywords[0]} {keywords[1]} syllabus"

## Output Format

Return JSON:

```json
{
  "source_type": "official",
  "topics": [
    {
      "name": "VPC Fundamentals",
      "description": "Virtual Private Cloud basics",
      "complexity": 5,
      "source_title": "AWS SAA-C03 Exam Guide",
      "source_url": "https://aws.amazon.com/certification/",
      "source_date": "2024-01-15"
    }
  ],
  "hidden_topics": [
    {
      "name": "Policy Evaluation Logic",
      "detection_method": "complexity_analysis",
      "reason": "IAM requires understanding evaluation order, not mentioned in syllabus"
    }
  ],
  "prerequisites": {
    "VPC Fundamentals": []
    "Subnet Design": ["VPC Fundamentals"]
  },
  "related_topics": {
    "S3": ["Glacier", "EFS"]
  },
  "cross_domain": {
    "IAM Policies": ["Lambda", "S3 bucket policies"]
  },
  "search_iterations": 3,
  "confidence": 0.9
}
```

## Fail-Safety

- If no official sources found: return empty arrays with explanation in "`search_notes`"
- If partial results: return what you found, mark confidence lower
- Never return null/undefined - use empty arrays/objects
- If search fails: return with "search_failed": true and reason
```

- [ ] **Step 2: Write academic sources discovery prompt**

Create `docs/superpowers/prompts/discovery-agent-academic.md`:

```markdown
# Discovery Agent: Academic Sources

You are researching **academic sources** for a learning goal.

## Input

You receive:
- goal_type: "exam" | "skill" | "degree" | "topic"
- subject: string
- keywords: string[]
- raw_goal: string

## Your Task

1. **Search academic sources:**
   - Scholarly papers
   - Textbooks
   - University course syllabi
   - Research publications
   
2. **Extract topics** - focus on theoretical foundations

3. **Detect hidden topics:**
   - **Complexity analysis**: What theoretical concepts underpin each topic?
   - **Error patterns**: What misconceptions do papers identify?
   - **Expert practice**: What do researchers emphasize vs practitioners?

4. **Identify prerequisites** (often deeper than practical)

5. **Find cross-domain bridges** (interdisciplinary connections)

## Search Strategy

Use WebSearch with queries:
- "{subject} textbook"
- "{subject} research paper"
- "{subject} university syllabus"
- "{keywords[0]} academic"
- "{subject} arxiv" (if technical)

## Output Format

Same JSON structure as official agent, with:
- source_type: "academic"
- Focus on theoretical depth
- Include paper citations when available

## Fail-Safety

- Academic sources may not exist for certification exams - that's OK
- Return what you find, even if 0 topics (mark confidence: 0.3)
- Prefer textbooks over papers for practical skills
```

- [ ] **Step 3: Write practical sources discovery prompt**

Create `docs/superpowers/prompts/discovery-agent-practical.md`:

```markdown
# Discovery Agent: Practical Sources

You are researching **practical sources** for a learning goal.

## Input

Same as other agents.

## Your Task

1. **Search practical sources:**
   - Blog posts
   - Tutorials
   - Stack Overflow
   - YouTube videos
   - Online courses
   
2. **Extract topics** - focus on hands-on skills

3. **Detect hidden topics:**
   - **Complexity analysis**: What practical skills do tutorials assume?
   - **Error patterns**: Search "{subject} common mistakes", "{subject} gotchas"
   - **Expert practice**: What do practitioners blog about that official docs miss?

4. **Identify prerequisites** (practical application level)

5. **Find related topics** (alternative approaches)

## Search Strategy

Use WebSearch with queries:
- "{subject} tutorial"
- "{subject} common mistakes"
- "{subject} gotchas"
- "{keywords[0]} {keywords[1]} stack overflow"
- "{subject} best practices"
- "{subject} hands-on"

## Output Format

Same JSON structure, with:
- source_type: "practical"
- Include_urls for tutorials
- Focus on error patterns

## Fail-Safety

- Practical sources should always exist for any topic
- If nothing found, try broader queries
- Mark confidence: 0.5 minimum if found
```

- [ ] **Step 4: Write expert sources discovery prompt**

Create `docs/superpowers/prompts/discovery-agent-expert.md`:

```markdown
# Discovery Agent: Expert Sources

You are researching **expert practitioner sources** for a learning goal.

## Input

Same as other agents.

## Your Task

1. **Search expert sources:**
   - Industry standards
   - Practitioner blogs
   - Conference talks
   - Case studies
   - Real-world implementations
   
2. **Extract topics** - focus on production reality vs exam theory

3. **Detect hidden topics:**
   - **Complexity analysis**: What do experts use that isn't taught?
   - **Error patterns**: What production incidents reveal?
   - **Expert practice**: "What I wish I knew" type content

4. **Identify prerequisites** (real-world application)

5. **Find cross-domain bridges** (how experts combine skills)

## Search Strategy

Use WebSearch with queries:
- "{subject} production"
- "{subject} real world"
- "{subject} case study"
- "{subject} conference talk"
- "{keywords[0]} best practices enterprise"
- "{subject} lessons learned"

## Output Format

Same JSON structure, with:
- source_type: "expert"
- Include war stories/lessons learned
- Focus on gaps between exam and reality

## Fail-Safety

- Expert sources valuable but may be scarce
- Return confidence: 0.4 if minimal results
- Any real-world insights are valuable
```

- [ ] **Step 5: Commit prompt files**

```bash
git add docs/superpowers/prompts/discovery-agent-*.md
git commit -m "feat(prompts): add 4 discovery agent prompts

- Official sources: curriculum, vendor docs
- Academic sources: papers, textbooks
- Practical sources: tutorials, blogs, forums
- Expert sources: production, case studies

Each includes hidden topic detection and fail-safety

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 3: Write Critic Agent Prompt

**Files:**
- Create: `docs/superpowers/prompts/critic-agent.md`

**Interfaces:**
- Consumes: Merged research (topics[], hidden_topics[], prerequisites{}, links{})
- Produces: JSON with verdict and challenges[]

- [ ] **Step 1: Write critic agent prompt**

Create `docs/superpowers/prompts/critic-agent.md`:

```markdown
# Critic Agent: Syllabus Quality Review

You are an adversarial reviewer. Your job is to find gaps and issues in syllabus research.

## Input

You receive merged research:
```json
{
  "topics": [...],
  "hidden_topics": [...],
  "prerequisites": {...},
  "related_topics": {...},
  "cross_domain": {...},
  "sources": {...}
}
```

## Your Task: Run 9 Checks

### Check 1: Missing Prerequisites
For each topic, verify all prerequisites are in the topic list.
**Issue format:** "Topic '{x}' requires '{y}' but it's not in syllabus"

### Check 2: Hidden Topics Missed
Are there obvious hidden topics the agents didn't find?
**Issue format:** "Agents missed '{x}' - {reason}"

### Check 3: Source Gaps
Does each topic have sources from multiple types?
**Issue format:** "Topic '{x}' has only {type} sources, missing {missing_types}"

### Check 4: Triangulation Failures
Does each core topic have ≥3 sources?
**Issue format:** "Topic '{x}' has only {n} sources (needs ≥3)"

### Check 5: Outdated Content
Are sources recent (≤2 years)?
**Issue format:** "Topic '{x}' sources avg age {n} months"

### Check 6: Depth vs Breadth
Is topic count appropriate for goal_type?
- exam: 30-60 topics
- skill: 20-40 topics  
- degree: 80-150 topics
- topic: 15-30 topics

**Issue format:** "{n} topics for {goal_type} - {assessment}"

### Check 7: Cross-Domain Bridges
Are there cross_domain links?
**Issue format:** "No cross-domain links found - knowledge is isolated"

### Check 8: Practical Gaps
Are there hands-on/practice elements?
**Issue format:** "No practical exercises/labs mentioned"

### Check 9: Timeline Match
Can topics be learned in timeline?
Assume: 1 topic = 2-4 hours study

**Issue format:** "{n} topics in {timeline} = {hours} hours/week"

## Output Format

```json
{
  "verdict": "reject" | "approve_with_warnings" | "approve",
  "challenges": [
    {
      "check": 1,
      "severity": "critical" | "warning" | "info",
      "issue": "Description of problem",
      "affected_topics": ["topic1", "topic2"],
      "suggested_fix": "How to resolve"
    }
  ],
  "summary": "Brief overall assessment"
}
```

## Severity Levels

- **critical**: Must fix before syllabus generation (missing core topics, no sources)
- **warning**: Should fix but can proceed (low source count, outdated)
- **info**: Nice to have (cross-domain links, practical gaps)

## Rules

- If ANY critical: verdict = "reject"
- If warnings only: verdict = "approve_with_warnings"
- If all pass: verdict = "approve"
- Always provide at least 1 piece of positive feedback
- Never output empty challenges array - use "all checks passed" if no issues
```

- [ ] **Step 2: Commit critic prompt**

```bash
git add docs/superpowers/prompts/critic-agent.md
git commit -m "feat(prompts): add critic agent with 9 quality checks

- Missing prerequisites, hidden topics, source gaps
- Triangulation (≥3 sources), recency, depth/breadth
- Cross-domain bridges, practical gaps, timeline match

Severity levels: critical/warning/info

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 4: Update SKILL.md - Redesign syllabus_generation Workflow

**Files:**
- Modify: `SKILL.md` (lines 80-89, syllabus_generation workflow)

**Interfaces:**
- Uses: All prompts from Tasks 2-3
- Produces: New 9-step workflow with parallel research

- [ ] **Step 1: Rewrite syllabus_generation workflow**

Replace lines 80-89 in `SKILL.md` with:

```markdown
#### 1. syllabus_generation

Create research-based learning plan with hidden topic detection.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "I want to learn X", "Create a study plan for Y", "Syllabus for Z exam" |
| **Prerequisites** | Goal identified, timeline known (optional) |
| **Steps** | See §2.1 Research-Based Syllabus Generation |
| **Outputs** | SQLite with all tables + topic_links + topic_sources, `00-Dashboard/Syllabus.md` |
```

- [ ] **Step 2: Add new section §2.1 with full workflow**

Insert after line 89 in `SKILL.md`:

```markdown

---

### §2.1 Research-Based Syllabus Generation (9 Steps)

#### Step 1: Parse Goal (Hybrid)

**Deterministic parsing (cannot fail):**
```json
{
  "goal_id": "aws-solutions-architect",
  "goal_type": "exam",
  "subject": "AWS Solutions Architect",
  "keywords": ["AWS", "Solutions Architect", "SAA", "certification"],
  "timeline": "3 months",
  "raw_goal": "I want to pass the AWS Solutions Architect exam in 3 months"
}
```

**Pass to each agent:**
- Structured data (goal_type, subject, keywords)
- Raw goal (fallback if parsing unclear)

#### Step 2: Database Initialization

See §1.5 - Auto-initialize `~/.mit-learning/goals/{goal_id}/memory.db`

#### Step 3: Launch Discovery Agents (Parallel)

Spawn 4 agents simultaneously using `Agent` tool:

| Agent | Prompt File | Source Focus |
|-------|-------------|--------------|
| Agent 1 | `prompts/discovery-agent-official.md` | Curriculum, vendor docs |
| Agent 2 | `prompts/discovery-agent-academic.md` | Papers, textbooks |
| Agent 3 | `prompts/discovery-agent-practical.md` | Tutorials, blogs, forums |
| Agent 4 | `prompts/discovery-agent-expert.md` | Production, case studies |

**Each agent returns:**
- topics[] with sources
- hidden_topics[] with detection method
- prerequisites{}
- related_topics{}
- cross_domain{}
- confidence score

#### Step 4: Merge Results

**Merge logic:**
1. Union all topics (dedupe by name similarity)
2. Calculate confidence per topic: avg(agent confidence) × source_count_factor
3. Cross-validate: topics in ≥3 sources = high confidence
4. Topics in 1-2 sources = needs verification (flag)
5. Aggregate hidden topics with detection method
6. Union all prerequisite links
7. Union all related and cross-domain links

**Fail-safety:**
- If 1 agent fails: proceed with 3 agents, note in warnings
- If 2+ agents fail: prompt user to retry

#### Step 5: Build Knowledge Graph

**Create links in SQLite:**

| Link Type | Source | Storage |
|-----------|--------|---------|
| prerequisite | Agents (prerequisites{}) | `prerequisites` table |
| enabled_by | Derived (reverse of prerequisite) | `topic_links` table |
| related_to | Agents (related_topics{}) | `topic_links` table |
| cross_domain | Agents (cross_domain{}) | `topic_links` table |

**Insert queries:**
```sql
-- Prerequisites
INSERT INTO prerequisites (topic_id, prerequisite_id) VALUES (?, ?);

-- Other links
INSERT INTO topic_links (from_topic, to_topic, link_type, confidence) 
VALUES (?, ?, 'related_to', ?);
```

#### Step 6: Run Critic Loop (Max 3 Rounds)

Launch critic agent with merged research:
- Read: `prompts/critic-agent.md`
- Input: merged JSON from Step 4
- Output: verdict + challenges

**Critic verdict handling:**
- `reject`: Identify gaps from challenges → re-research specific topics → back to Step 3 (max 2 re-research rounds)
- `approve_with_warnings`: Present warnings to user → user accepts or requests fixes
- `approve`: Proceed to Step 7

**Max iterations:**
- 3 critic rounds total
- If still rejected after 3: force approve with warnings

#### Step 7: Check Satisfaction Criteria

Verify 7 criteria:

| # | Criterion | Pass Threshold |
|---|-----------|-----------------|
| 1 | Minimum sources | ≥3 per core topic |
| 2 | Hidden topic coverage | All 3 detection methods ran |
| 3 | Prerequisites checked | All topics have entry |
| 4 | Critic approved | No critical challenges |
| 5 | Cross-validation | ≥50% topic overlap |
| 6 | Recency | Sources ≤2 years old |
| 7 | Goal type fit | Topic count matches |

**If criteria fail:**
- Critical: Re-research (max 2 rounds)
- Warnings: Proceed with flags

#### Step 8: Generate Syllabus

**Create `00-Dashboard/Syllabus.md` in Obsidian vault:**

Structure:
```markdown
# {Goal Name} Syllabus

**Generated:** {date}
**Goal Type:** {type}
**Timeline:** {timeline}
**Total Topics:** {n}
**Hidden Topics Found:** {m}

---

## Executive Summary
{Synthesis of research}

---

## Core Topics (High Confidence)
| # | Topic | Prerequisites | Sources | Confidence |
|---|-------|---------------|---------|------------|
...

## Hidden Topics
| # | Topic | Detection Method | Reason |
|---|-------|------------------|--------|
...

## Knowledge Graph
### Prerequisite Chain
{ASCII tree}

### Related Topics
{Bulleted lists}

### Cross-Domain Bridges
{Bulleted lists}

---

## Source Bibliography
{Table by topic}

---

## Warnings
{Any criteria warnings}
```

#### Step 9: Store in SQLite

**Insert topics:**
```sql
INSERT INTO topics (topic_id, name, confidence, source_count, is_hidden, detection_method, status)
VALUES (?, ?, ?, ?, ?, ?, 'pending');

INSERT INTO topic_sources (topic_id, source_type, source_title, source_url, source_date)
VALUES (?, ?, ?, ?, ?);

INSERT INTO topic_links (from_topic, to_topic, link_type, confidence, source)
VALUES (?, ?, ?, ?, ?);

INSERT INTO prerequisites (topic_id, prerequisite_id)
VALUES (?, ?);
```

**Update goal_meta:**
```sql
UPDATE goal_meta 
SET total_topics = (SELECT COUNT(*) FROM topics WHERE is_hidden = 0),
    mastered_topics = 0
WHERE goal_id = ?;

INSERT INTO streak_state (goal_id) VALUES (?);
```

---

## Research Output Example

```json
{
  "satisfied": true,
  "criteria": {
    "sources": {"pass": true, "avg_per_topic": 4.2},
    "hidden_detection": {"pass": true, "methods_run": 3, "found": 12},
    "prerequisites": {"pass": true, "coverage": 0.95},
    "critic": {"pass": true, "rounds": 2, "warnings": 3},
    "cross_validation": {"pass": true, "overlap": 0.52},
    "recency": {"pass": true, "avg_age_months": 8},
    "goal_fit": {"pass": true, "topic_count": 45, "goal_type": "exam"}
  },
  "warnings": ["Topic 'Edge Cases' has 2 sources only"]
}
```
```

- [ ] **Step 3: Verify SKILL.md renders correctly**

Read modified section to ensure formatting is correct.

- [ ] **Step 4: Commit SKILL.md changes**

```bash
git add SKILL.md
git commit -m "feat(workflow): redesign syllabus_generation with 9-step research

- Parse goal (hybrid deterministic + agent refinement)
- 4 parallel discovery agents (official/academic/practical/expert)
- Merge with cross-validation
- Knowledge graph building (prerequisite/related/cross-domain)
- Critic loop (max 3 rounds, 9 checks)
- Satisfaction criteria (7 thresholds)
- Syllabus generation + SQLite storage

References prompts/discovery-agent-*.md and critic-agent.md

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 5: Install Updated Skill to Claude Desktop

**Files:**
- Copy: `~/.claude/skills/mit-learning/` (all updated files)

**Interfaces:**
- Uses: All files from Tasks 1-4

- [ ] **Step 1: Copy updated files to Claude skills directory**

```bash
cp /Users/codeversepro/Documents/Skill/MIT/SKILL.md ~/.claude/skills/mit-learning/
cp -r /Users/codeversepro/Documents/Skill/MIT/docs ~/.claude/skills/mit-learning/
```

- [ ] **Step 2: Verify installation**

```bash
ls -la ~/.claude/skills/mit-learning/
ls ~/.claude/skills/mit-learning/docs/superpowers/prompts/ | grep discovery
ls ~/.claude/skills/mit-learning/docs/superpowers/mcp-queries/ | grep schema
```

Expected: SKILL.md updated, 4 discovery prompts, schema.sql present

- [ ] **Step 3: Test skill trigger in new session**

Close and reopen Claude Desktop, then test trigger:
```
"I want to learn AWS Lambda fundamentals"
```

Expected: Skill activates, research begins

---

## Verification Checklist

- [ ] Schema migration runs without errors
- [ ] All 4 discovery agent prompts created
- [ ] Critic agent prompt created
- [ ] SKILL.md updated with new workflow
- [ ] Skill installed to ~/.claude/skills/mit-learning/
- [ ] Manual test: syllabus generation triggers correctly

---

## Rollback Plan

If issues arise:
1. Revert SKILL.md: `git checkout HEAD~1 -- SKILL.md`
2. Remove new prompt files: `rm docs/superpowers/prompts/discovery-*.md docs/superpowers/prompts/critic-agent.md`
3. Schema rollback: New tables don't affect existing data - safe to leave
4. Reinstall: `cp SKILL.md ~/.claude/skills/mit-learning/`
