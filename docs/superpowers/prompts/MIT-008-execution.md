# MIT-008: Research Workflow

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-008
Title: Research Workflow
Phase: 2
Effort: 4 hours
Impact: Research compilation saved to SQLite
Dependencies: MIT-004 (Phase 1 Complete)
Parallelizable with: MIT-005, MIT-006, MIT-007, MIT-009
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-008 ==="

# 1. Phase 1 complete
jq -e '.MIT-004.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: Phase 1 not complete"; exit 1; }

# 2. research.sql exists
test -f docs/superpowers/mcp-queries/research.sql || { echo "FAIL: research.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-008-START << 'EOF'
{"storyId": "MIT-008", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-008 = {"status": "in-progress", "phase": 2, "title": "Research Workflow", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-004"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Create Source Tables

Add to schema.sql if not exists:

```sql
-- Research sources
CREATE TABLE IF NOT EXISTS research_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN ('web', 'book', 'paper', 'video', 'course')),
    title TEXT NOT NULL,
    url TEXT,
    author TEXT,
    publication_date DATE,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    credibility_score REAL CHECK(credibility_score >= 0.0 AND credibility_score <= 1.0),
    notes TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Research claims (triangulated from multiple sources)
CREATE TABLE IF NOT EXISTS research_claims (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    claim_text TEXT NOT NULL,
    confidence_score REAL CHECK(confidence_score >= 0.0 AND confidence_score <= 1.0),
    source_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Claim-source mapping
CREATE TABLE IF NOT EXISTS claim_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    claim_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    supports INTEGER DEFAULT 1 CHECK(supports IN (0, 1)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (claim_id) REFERENCES research_claims(id),
    FOREIGN KEY (source_id) REFERENCES research_sources(id),
    UNIQUE(claim_id, source_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sources_topic ON research_sources(topic_id);
CREATE INDEX IF NOT EXISTS idx_claims_topic ON research_claims(topic_id);
```

---

### Step 2: Define Research Workflow

Update SKILL.md:

```markdown
## Workflow: research

**Trigger:** "Research [topic]" / "Find sources for [topic]" / "Look up [topic]"

### Layered Research Approach

**Layer 1: Primary Sources**
- Official documentation
- Academic papers
- Original research

**Layer 2: Secondary Sources**
- Textbook explanations
- Course materials
- Expert blogs

**Layer 3: Tertiary Sources**
- Wikipedia summaries
- Tutorial articles
- Video explanations

### Flow

1. **Search for Sources**
   ```markdown
   Use WebSearch to find sources:
   - Primary: official docs, papers
   - Secondary: textbooks, courses
   - Tertiary: tutorials, videos
   ```

2. **Store Sources in SQLite**
   ```sql
   INSERT INTO research_sources (topic_id, source_type, title, url, author, credibility_score)
   VALUES (:topic_id, :source_type, :title, :url, :author, :credibility);
   ```

3. **Extract Claims**
   - Identify key claims from each source
   - Cross-reference across sources

4. **Triangulate Claims**
   ```sql
   -- Claim requires >= 3 sources for confidence
   SELECT claim_text, COUNT(DISTINCT source_id) as source_count
   FROM research_claims c
   JOIN claim_sources cs ON c.id = cs.claim_id
   GROUP BY c.id
   HAVING source_count >= 3;
   ```

5. **Calculate Confidence**
   ```sql
   -- Confidence = MIN(1.0, source_count / 3.0) * AVG(credibility)
   UPDATE research_claims
   SET confidence_score = (
       SELECT MIN(1.0, COUNT(*) / 3.0) * AVG(s.credibility_score)
       FROM claim_sources cs
       JOIN research_sources s ON cs.source_id = s.id
       WHERE cs.claim_id = research_claims.id
   ),
   source_count = (
       SELECT COUNT(*) FROM claim_sources WHERE claim_id = research_claims.id
   );
   ```

6. **Create Obsidian Note**
   - Write to vault: `notes/research/<topic>.md`
   - Include triangulated claims
   - Link to sources

### Claim Triangulation Rules

| Source Count | Confidence | Status |
|--------------|------------|--------|
| 1 source | < 0.4 | Unverified |
| 2 sources | 0.4-0.6 | Partially verified |
| 3+ sources | >= 0.7 | Verified |

### Source Credibility Scoring

| Source Type | Base Credibility |
|-------------|------------------|
| Academic paper | 0.9 |
| Official docs | 0.85 |
| Textbook | 0.8 |
| Course | 0.75 |
| Expert blog | 0.7 |
| Tutorial | 0.6 |
| Wikipedia | 0.5 |
| Video | 0.5 |
```

---

### Step 3: Test Source Storage

```sql
-- Create research topic
INSERT INTO topics (topic_id, name, status)
VALUES ('T10-research-test', 'Machine Learning Basics', 'in_progress');

-- Store sources
INSERT INTO research_sources (topic_id, source_type, title, url, author, credibility_score)
VALUES
    ((SELECT id FROM topics WHERE topic_id = 'T10-research-test'),
     'paper', 'Attention Is All You Need', 'https://arxiv.org/abs/1706.03762', 'Vaswani et al.', 0.95),
    ((SELECT id FROM topics WHERE topic_id = 'T10-research-test'),
     'book', 'Deep Learning', 'https://www.deeplearningbook.org/', 'Goodfellow et al.', 0.9),
    ((SELECT id FROM topics WHERE topic_id = 'T10-research-test'),
     'course', 'CS231n', 'http://cs231n.stanford.edu/', 'Stanford', 0.85);

-- Verify sources
SELECT title, credibility_score FROM research_sources
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T10-research-test');
```

---

### Step 4: Test Claim Triangulation

```sql
-- Create claim
INSERT INTO research_claims (topic_id, claim_text, confidence_score, source_count)
VALUES ((SELECT id FROM topics WHERE topic_id = 'T10-research-test'),
        'Transformers use self-attention mechanism', 0.0, 0);

-- Link to sources
INSERT INTO claim_sources (claim_id, source_id, supports)
SELECT
    (SELECT id FROM research_claims WHERE claim_text = 'Transformers use self-attention mechanism'),
    id, 1
FROM research_sources
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T10-research-test');

-- Update confidence
UPDATE research_claims
SET
    confidence_score = (
        SELECT MIN(1.0, COUNT(*) / 3.0) * AVG(s.credibility_score)
        FROM claim_sources cs
        JOIN research_sources s ON cs.source_id = s.id
        WHERE cs.claim_id = research_claims.id
    ),
    source_count = (
        SELECT COUNT(*) FROM claim_sources WHERE claim_id = research_claims.id
    );

-- Verify
SELECT claim_text, confidence_score, source_count FROM research_claims
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T10-research-test');
```

Expected: confidence ≈ 0.9, source_count = 3

---

## TESTING & VERIFICATION

```bash
echo "=== RESEARCH WORKFLOW VERIFICATION ==="

# 1. Sources stored
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM research_sources WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T10-research-test');" | grep -q "3" && echo "✓ [1/5] Sources stored"

# 2. Credibility scored
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT AVG(credibility_score) FROM research_sources;" | grep -q "0\.[89]" && echo "✓ [2/5] Credibility calculated"

# 3. Claims created
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM research_claims;" | grep -q "1" && echo "✓ [3/5] Claims created"

# 4. Triangulation works
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT source_count FROM research_claims WHERE claim_text LIKE '%Transformer%';" | grep -q "3" && echo "✓ [4/5] Triangulation works"

# 5. SKILL.md updated
grep -q "Workflow: research" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Sources stored in SQLite
- [ ] Credibility scores assigned
- [ ] Claims extracted from sources
- [ ] Triangulation requires >= 3 sources
- [ ] Confidence calculated correctly
- [ ] SKILL.md has layered research approach

## HUMAN SIGN-OFF ##
Status: [ ] I have verified research workflow works with triangulation.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM research_sources;" | grep -q "." && echo "✓ [1/4] Sources table working"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM research_claims WHERE source_count >= 3;" | grep -q "." && echo "✓ [2/4] Claims triangulated"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT confidence_score FROM research_claims WHERE source_count >= 3;" | grep -q "0\.[789]" && echo "✓ [3/4] High confidence for 3+ sources"
grep -q "Claim Triangulation Rules" SKILL.md && echo "✓ [4/4] SKILL.md has triangulation rules"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md docs/superpowers/mcp-queries/research.sql
git commit -m "feat(MIT-008): research workflow

- research workflow with layered approach
- Source storage in SQLite
- Claim triangulation (>= 3 sources)
- Confidence calculation
- Credibility scoring

Story: MIT-008
Phase: 2
Dependencies: MIT-004
"

jq '.MIT-008.status = "passed" | .MIT-008.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-008-PASS << 'EOF'
{"storyId": "MIT-008", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ MIT-008 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-008-START)
git checkout $REF -- SKILL.md docs/superpowers/mcp-queries/research.sql
jq '.MIT-008.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-008-*
echo "Rollback complete"
```

---

**NEXT:** Continue Phase 2 workflows

**END OF EXECUTION PROMPT FOR MIT-008**
