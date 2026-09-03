# Research Methodology

## Overview

MIT Learning Skill performs layered research compiling information from multiple source tiers into a single comprehensive note. User reads nothing else.

---

## Layered Research Approach

### Tier 1: Academic + Official Sources (Highest Priority)

**Indicators:**
- `.edu` domains (universities)
- `.gov` domains (government)
- `.org` domains (institutions)
- Academic publishers: `arxiv.org`, `nature.com`, `science.org`, `ieee.org`, `acm.org`
- Research platforms: `scholar.google.com`, `pubmed`, `researchgate`, `semanticscholar`

**Weight:** 1.0 (full confidence contribution)

**When to prioritize:**
- Exam preparation requiring authoritative sources
- Technical topics needing peer-reviewed accuracy
- Policy/legal topics requiring official documentation

**Example sources:**
```
https://arxiv.org/abs/2301.12345
https://stanford.edu/department/paper
https://gov.in/official-document
https://nature.com/articles/...
```

---

### Tier 2: Broad Web Sources (Secondary)

**Indicators:**
- News outlets (CNN, BBC, Reuters)
- Wikipedia
- Blogs and personal websites
- Medium, Substack
- Stack Overflow, Reddit (for technical topics)

**Weight:** 0.7 (reduced confidence contribution)

**When to use:**
- Supplementary information
- Real-world examples
- Community knowledge
- Quick overviews before deep diving

**Example sources:**
```
https://en.wikipedia.org/wiki/Topic
https://medium.com/@author/article
https://stackoverflow.com/questions/...
https://bbc.com/news/article
```

---

### Tier 3: Curated Sources (Context-Specific)

**Indicators:**
- User-specified feeds
- Domain-specific databases
- Reference works
- Course materials

**Weight:** 0.8 (moderate confidence)

**When to use:**
- User-provided reading lists
- Course syllabi
- Professional databases
- Curated newsletters

---

## Triangulation Rules

### Minimum Sources Per Claim

| Claim Type | Minimum Sources | Notes |
|------------|-----------------|-------|
| Factual statement | 3 | From independent sources |
| Statistics | 3 | Prefer official sources |
| Historical event | 2 | Cross-check dates |
| Scientific claim | 3 | Peer-reviewed preferred |
| Personal opinion | 1 | Label as opinion |

### Confidence Scoring

```
confidence = weighted_sources / max_weighted

where:
  weighted_sources = sum(tier_weight for each source)
  max_weighted = 3 * 1.0  # 3 sources at tier1

Example:
  2 tier1 + 1 tier2 = 2.0 + 0.7 = 2.7
  confidence = 2.7 / 3.0 = 0.90 (90%)
```

### Unverified Claims

When <3 sources found:
1. Mark with ⚠️ warning
2. Show "Sources found: N/3"
3. Suggest verification needed
4. Do not state as fact

---

## Research Workflow

### Step 1: Initialize Research

```python
from scripts.research_engine import ResearchEngine

engine = ResearchEngine()
result = engine.research(topic, context)
```

### Step 2: Gather Tier 1 Sources

Use WebSearch tool:
```
Query: "{topic} site:edu OR site:gov OR site:arxiv.org"
Query: "{topic} scholarly article"
Query: "{topic} research paper"
```

### Step 3: Gather Tier 2 Sources

```
Query: "{topic} overview"
Query: "{topic} explained"
Query: "{topic} wikipedia"
```

### Step 4: Gather Tier 3 Sources

```
Query: "{topic} course syllabus"
Query: "{topic} reading list"
```

### Step 5: Extract Claims

From each source:
1. Extract verbatim quotes
2. Note exact URL
3. Record author/institution
4. Capture publication date

### Step 6: Triangulate

For each claim:
1. Find in ≥3 independent sources
2. Prefer higher tier sources
3. Calculate confidence
4. Flag if unverified

### Step 7: Compile Single Note

```python
note = result.compile_note()
# Contains:
# - Overview summary
# - Verified claims (≥3 sources)
# - Unverified claims (warning)
# - Source bibliography by tier
# - Confidence scores
# - Research timestamp
```

---

## Output Format

### Verified Claim

```markdown
**1.** The Higgs boson was discovered in 2012 at CERN.
   - Confidence: 100%
```

### Unverified Claim

```markdown
- ⚠️ Some researchers suggest the particle may have exotic properties.
  - Sources found: 1/3
```

### Source Bibliography

```markdown
### Academic & Official Sources (5)
- [Higgs Discovery Paper](https://arxiv.org/abs/...)
  - Author: ATLAS Collaboration
  - Institution: CERN

### General Web Sources (3)
- [CERN Press Release](https://home.cern/news)
```

---

## Quality Guardrails

**Refuse to:**
- State claim as fact if <3 sources
- Fabricate citations
- Use single source for systemic claim
- Skip verification for exam topics

**Mark for manual review:**
- Contradictory sources
- Outdated information (>5 years for dynamic topics)
- Single-source statistics
- Controversial claims without majority consensus

---

## Integration with Learning Workflows

### learning_session

```python
if topic_requires_research(topic):
    result = engine.research(topic)
    note = result.compile_note()
    vault.write_note(topic_id, note)
```

### current_affairs_digest

```python
# Dynamic research for current events
result = engine.research(current_event, context="daily digest")
# Prioritize tier1 + tier2 (speed)
# Accept lower source threshold (2) for breaking news
```

### elaborative_interrogation

```python
# Deep research for "why" questions
result = engine.research(question, context="deep dive")
# Require 5 sources for mechanistic explanations
engine = ResearchEngine(min_sources=5)
```

---

## Example Research Query

**Topic:** "Quantum entanglement"

**Tier 1 Search:**
```
"quantum entanglement" site:arxiv.org
→ Found: arxiv.org/abs/quant-ph/1234

"quantum entanglement" scholarly article nature
→ Found: nature.com/articles/...

"bell's theorem" site:edu
→ Found: stanford.edu/physics/bell
```

**Tier 2 Search:**
```
"quantum entanglement explained"
→ Found: wikipedia.org/wiki/Quantum_entanglement
```

**Triangulation:**
```
Claim: "Entangled particles remain correlated regardless of distance"
  - Sources: arxiv paper, nature article, stanford page
  - Confidence: 100%
  - Status: Verified
```

**Compiled Note:**
```markdown
# Quantum Entanglement

## Overview
Quantum entanglement is a phenomenon where particles
remain correlated regardless of spatial separation...

## Key Findings

### Verified Information
_Triangulated across 3+ sources_

**1.** Entangled particles remain correlated regardless of distance.
   - Confidence: 100%

**2.** Bell's theorem proves quantum mechanics cannot be explained
       by local hidden variables.
   - Confidence: 100%

## Source Summary
Total sources consulted: 5

### Academic & Official Sources (4)
- [Quantum Entanglement Paper](https://arxiv.org/...)
- [Bell's Theorem Explained](https://stanford.edu/...)

_Generated: 2026-08-31_
```

---

## Error Handling

| Error | Code | Resolution |
|-------|------|------------|
| No sources found | E600 | Mark "topic needs manual research" |
| Contradicting sources | E601 | Document contradiction, recommend verification |
| Source fetch failed | E602 | Log error, continue with available sources |
| Claim unverified | E603 | Include with warning, suggest manual review |

See `references/error-codes.md` for error code ranges.
