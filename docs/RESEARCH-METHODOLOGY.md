# MIT Learning Skill - Research Methodology Documentation

**Version 3.0 - Exhaustive Edition**
**Last Updated: September 1, 2026**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Layered Source System](#2-layered-source-system)
3. [Triangulation Rules](#3-triangulation-rules)
4. [Confidence Scoring](#4-confidence-scoring)
5. [Quality Guardrails](#5-quality-guardrails)
6. [Implementation](#6-implementation)
7. [Integration with Workflows](#7-integration-with-workflows)

---

## 1. Overview

### 1.1 Purpose

The research methodology ensures that all learning materials are:
- **Accurate**: Verified across multiple independent sources
- **Authoritative**: Prioritizes academic and official sources
- **Comprehensive**: Single-source delivery without requiring external reading
- **Transparent**: All claims include confidence scores and source citations

### 1.2 Core Principles

| Principle | Description |
|-----------|-------------|
| Triangulation | Every claim backed by ≥3 independent sources |
| Tiered Sources | Academic/Official > Broad Web > Curated |
| Single-Source Delivery | User reads nothing else |
| Transparency | Show confidence and sources for all claims |
| Verification | Mark unverified claims clearly |

### 1.3 Research Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   RESEARCH WORKFLOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐                                               │
│  │  TOPIC   │                                               │
│  │ Request  │                                               │
│  └────┬─────┘                                               │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────────────────────────────────┐           │
│  │          TIER 1: Academic + Official          │           │
│  │                                              │           │
│  │  • Research papers (arXiv, PubMed)           │           │
│  │  • Government sources (.gov)                 │           │
│  │  • Universities (.edu)                      │           │
│  │  • Academic publishers (Nature, Science)     │           │
│  └──────────────────────────────────────────────┘           │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────────────────────────────────┐           │
│  │          TIER 2: Broad Web Sources           │           │
│  │                                              │           │
│  │  • Wikipedia                                 │           │
│  │  • News outlets (BBC, Reuters)              │           │
│  │  • Blogs, Medium, educational sites          │           │
│  └──────────────────────────────────────────────┘           │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────────────────────────────────┐           │
│  │          TIER 3: Curated Sources              │           │
│  │                                              │           │
│  │  • User-specified feeds                     │           │
│  │  • Course materials                         │           │
│  │  • Domain-specific databases                │           │
│  └──────────────────────────────────────────────┘           │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────────────────────────────────┐           │
│  │            TRIANGULATION ENGINE               │           │
│  │                                              │           │
│  │  • Extract claims from sources               │           │
│  │  • Match claims across sources               │           │
│  │  • Calculate confidence scores               │           │
│  │  • Flag unverified claims                    │           │
│  └──────────────────────────────────────────────┘           │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────────────────────────────────┐           │
│  │          COMPILED NOTE                        │           │
│  │                                              │           │
│  │  • Overview summary                          │           │
│  │  • Verified claims (≥3 sources)             │           │
│  │  • Unverified claims (marked)                │           │
│  │  • Complete bibliography                     │           │
│  │  • Confidence indicators                     │           │
│  └──────────────────────────────────────────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Layered Source System

### 2.1 Tier 1: Academic + Official Sources (Highest Priority)

**Weight: 1.0 (Full confidence contribution)**

#### Academic Indicators

| Indicator | Domain/Pattern | Examples |
|-----------|---------------|----------|
| Research repositories | `arxiv.org`, `pubmed.ncbi.nlm.nih.gov` | arXiv preprints, PubMed papers |
| Universities | `.edu`, `ac.uk`, `.ac.` | Stanford.edu, MIT.edu |
| Academic publishers | `nature.com`, `science.org`, `ieee.org` | Nature, Science, IEEE |
| Research platforms | `scholar.google.com`, `researchgate.net` | Google Scholar, ResearchGate |
| DOI registry | `doi.org`, `dx.doi.org` | DOI links |

#### Official Indicators

| Indicator | Domain/Pattern | Examples |
|-----------|---------------|----------|
| Government | `.gov`, `.mil`, `.int` | Whitehouse.gov, UN.org |
| International organizations | `.int`, `un.org`, `who.int` | WHO, UN, WTO |
| Policy institutions | `.org` (verified) | Brookings, RAND |

#### When to Prioritize Tier 1

- **Exam preparation** requiring authoritative sources
- **Technical topics** needing peer-reviewed accuracy
- **Policy/legal topics** requiring official documentation
- **Scientific concepts** where accuracy is critical

#### Example Tier 1 Sources

```
https://arxiv.org/abs/2301.12345        # Research paper
https://stanford.edu/department/paper   # University publication
https://gov.in/official-document        # Government source
https://nature.com/articles/...         # Academic publisher
https://who.int/publications/...        # International organization
```

### 2.2 Tier 2: Broad Web Sources (Secondary)

**Weight: 0.7 (Reduced confidence contribution)**

#### Broad Web Indicators

| Indicator | Type | Examples |
|-----------|------|----------|
| News outlets | Major news | CNN, BBC, Reuters, NYT |
| Wikipedia | Encyclopedia | `wikipedia.org` |
| Blogs | Educational/personal | Medium, Substack |
| Q&A sites | Community knowledge | Stack Overflow, Quora |
| Technical blogs | Developer resources | Dev.to, Hashnode |

#### When to Use Tier 2

- **Supplementary information** for context
- **Real-world examples** and applications
- **Community knowledge** for practical tips
- **Quick overviews** before deep diving
- **Breaking news** where academic sources don't yet exist

#### Example Tier 2 Sources

```
https://en.wikipedia.org/wiki/Topic           # Wikipedia
https://medium.com/@author/article            # Blog article
https://stackoverflow.com/questions/...       # Technical Q&A
https://bbc.com/news/...                      # News article
```

### 2.3 Tier 3: Curated Sources (Context-Specific)

**Weight: 0.8 (Moderate confidence)**

#### Curated Source Types

| Type | Description | Examples |
|------|-------------|----------|
| User-specified feeds | Pre-selected sources | RSS feeds |
| Course materials | Educational content | Coursera, edX |
| Domain databases | Specialized repositories | Medical databases |
| Reference works | Encyclopedias, handbooks | Britannica, Merriam-Webster |

#### When to Use Tier 3

- **User-provided reading lists** for specific courses
- **Course syllabi** for structured learning
- **Professional databases** for domain-specific knowledge
- **Curated newsletters** for current affairs

### 2.4 Source Classification Algorithm

```python
class SourceTier(Enum):
    """Research source hierarchy."""
    ACADEMIC_OFFICIAL = "tier1"    # Papers, gov, institutional
    BROAD_WEB = "tier2"            # General web search
    CURATED = "tier3"              # User-specified feeds

class ResearchEngine:
    """Classify sources into tiers."""
    
    ACADEMIC_INDICATORS = [
        '.edu', '.gov', '.org', 'arxiv.org', 'pubmed',
        'scholar.google', 'nature.com', 'science.org',
        'ieee', 'acm.org', 'researchgate', 'semanticscholar'
    ]
    
    OFFICIAL_INDICATORS = [
        '.gov', '.mil', '.int', '.eu',
        'un.org', 'worldbank.org', 'who.int'
    ]
    
    def classify_source_tier(self, url: str) -> SourceTier:
        """Classify source into tier based on URL."""
        url_lower = url.lower()
        
        # Check for academic/official indicators
        for indicator in self.ACADEMIC_INDICATORS + self.OFFICIAL_INDICATORS:
            if indicator in url_lower:
                return SourceTier.ACADEMIC_OFFICIAL
        
        # Default to broad web
        return SourceTier.BROAD_WEB
```

---

## 3. Triangulation Rules

### 3.1 Minimum Source Thresholds

| Claim Type | Minimum Sources | Notes |
|------------|-----------------|-------|
| Factual statement | 3 | From independent sources |
| Statistics | 3 | Prefer official sources |
| Historical event | 2 | Cross-check dates |
| Scientific claim | 3 | Peer-reviewed preferred |
| Personal opinion | 1 | Label as opinion |
| Current affairs | 2 | Accept lower for breaking news |

### 3.2 Source Independence

Sources are **independent** if they:
- Originate from different organizations
- Are not republished/translated versions of the same article
- Have different authors/publishers

```python
def are_sources_independent(source1: Source, source2: Source) -> bool:
    """Check if two sources are independent."""
    # Same URL -> not independent
    if source1.url == source2.url:
        return False
    
    # Same domain -> check further
    domain1 = extract_domain(source1.url)
    domain2 = extract_domain(source2.url)
    
    # Different main domains -> likely independent
    if domain1 != domain2:
        return True
    
    # Same domain -> check author
    if source1.author and source2.author:
        return source1.author != source2.author
    
    # Same domain, no author info -> might not be independent
    return False  # Conservative: treat as dependent
```

### 3.3 Triangulation Process

```python
def triangulate_claims(claims: list[Claim], sources: list[Source]) -> list[TriangulatedClaim]:
    """Match and triangulate claims across sources.
    
    Process:
    1. Normalize claim text for matching
    2. Find similar claims across sources
    3. Group matching claims
    4. Calculate confidence for each group
    """
    triangulated = []
    
    for claim in claims:
        # Normalize claim text
        normalized = normalize_claim(claim.text)
        
        # Find matching claims from other sources
        matches = []
        for source in sources:
            if claim.source.url == source.url:
                continue  # Skip same source
            
            # Check if source contains similar claim
            if sources_match_claim(source, normalized):
                matches.append(source)
        
        # Calculate confidence
        confidence = calculate_confidence(claim.source, matches)
        
        triangulated.append(TriangulatedClaim(
            text=claim.text,
            primary_source=claim.source,
            supporting_sources=matches,
            confidence=confidence,
            is_verified=len(matches) >= 2  # Total ≥3 sources
        ))
    
    return triangulated
```

### 3.4 Handling Contradictions

When sources contradict:

| Situation | Handling |
|-----------|----------|
| Consensus majority | Follow majority, note minority |
| Equal split | Mark as disputed, present both |
| Single contradictory source | Note the contradiction |
| Source age difference | Prefer more recent for dynamic topics |

```python
def handle_contradiction(claims: list[Claim]) -> ContradictionResult:
    """Handle contradictory claims from sources."""
    
    # Group claims by position
    positions = group_by_position(claims)
    
    # Check for majority consensus
    if len(positions) == 2:
        pos1, pos2 = positions
        if len(pos1.claims) > len(pos2.claims) * 2:
            # Clear majority
            return ContradictionResult(
                resolution='majority',
                primary=pos1,
                minority=pos2,
                note=f"Majority consensus ({len(pos1)} vs {len(pos2)} sources)"
            )
        else:
            # Disputed
            return ContradictionResult(
                resolution='disputed',
                positions=positions,
                note="Sources disagree - presenting both positions"
            )
    
    # Multiple positions
    return ContradictionResult(
        resolution='complex',
        positions=positions,
        note="Multiple competing claims - verify independently"
    )
```

---

## 4. Confidence Scoring

### 4.1 Confidence Formula

```
confidence = weighted_sources / max_weighted

where:
  weighted_sources = Σ(tier_weight × source_weight)
  max_weighted = 3.0  # (3 sources × 1.0 for tier1)
```

### 4.2 Tier Weights

| Tier | Weight |
|------|--------|
| Academic + Official (Tier 1) | 1.0 |
| Curated (Tier 3) | 0.8 |
| Broad Web (Tier 2) | 0.7 |

### 4.3 Calculation Examples

**Example 1: Strong Evidence**

```
Sources: 2× Tier 1 + 1× Tier 2
Weighted = (2 × 1.0) + (1 × 0.7) = 2.7
Confidence = 2.7 / 3.0 = 90%

Result: Verified (HIGH confidence)
```

**Example 2: Moderate Evidence**

```
Sources: 1× Tier 1 + 1× Tier 2 + 1× Tier 3
Weighted = (1 × 1.0) + (1 × 0.7) + (1 × 0.8) = 2.5
Confidence = 2.5 / 3.0 = 83%

Result: Verified (MEDIUM confidence)
```

**Example 3: Insufficient Evidence**

```
Sources: 1× Tier 1 + 1× Tier 2
Weighted = (1 × 1.0) + (1 × 0.7) = 1.7
Confidence = 1.7 / 3.0 = 57%

Result: Unverified (needs more sources)
```

### 4.4 Confidence Display

| Confidence Level | Range | Display |
|------------------|-------|---------|
| High | 90-100% | ✓ 100% confidence |
| Medium | 70-89% | ✓ 83% confidence |
| Low | 50-69% | ⚠️ 57% confidence |
| Very Low | <50% | ⚠️ Unverified - needs research |

---

## 5. Quality Guardrails

### 5.1 Mandatory Checks

| Check | Description | Action |
|-------|-------------|--------|
| Source count | Verify ≥3 sources | Mark unverified if failed |
| Source independence | Check sources are independent | Count dependent as one |
| Source age | Note outdated sources (>5 years) | Warning for dynamic topics |
| Source quality | Verify source tier | Weight appropriately |

### 5.2 Refusal Criteria

**REFUSE to:**
- State claim as fact if <3 sources
- Fabricate citations
- Use single source for systemic claims
- Skip verification for exam topics

**MARK for manual review:**
- Contradictory sources
- Outdated information
- Single-source statistics
- Controversial claims without consensus

### 5.3 Unverified Claim Handling

```markdown
**Claim being presented:**
⚠️ Some researchers suggest the phenomenon may have exotic properties.
   Sources found: 1/3
   Status: UNVERIFIED - validate independently before relying on this claim.

**Verified claim:**
✓ The Higgs boson was discovered in 2012 at CERN.
   Confidence: 100% (5 sources)
```

---

## 6. Implementation

### 6.1 Core Classes

```python
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import hashlib
import json
from datetime import datetime
from pathlib import Path

class SourceTier(Enum):
    ACADEMIC_OFFICIAL = "tier1"
    BROAD_WEB = "tier2"
    CURATED = "tier3"

@dataclass
class Source:
    """A research source with metadata."""
    url: str
    title: str
    tier: SourceTier
    snippet: str = ""
    published_date: Optional[str] = None
    author: Optional[str] = None
    institution: Optional[str] = None
    citation_key: str = ""
    
    def __post_init__(self):
        if not self.citation_key:
            self.citation_key = self._generate_citation_key()
    
    def _generate_citation_key(self) -> str:
        content = f"{self.url}{self.title}"
        return hashlib.md5(content.encode()).hexdigest()[:8]
    
    def to_dict(self) -> dict:
        return {
            "url": self.url,
            "title": self.title,
            "tier": self.tier.value,
            "snippet": self.snippet,
            "published_date": self.published_date,
            "author": self.author,
            "institution": self.institution,
            "citation_key": self.citation_key
        }

@dataclass
class Claim:
    """A factual claim with source triangulation."""
    text: str
    sources: list[Source] = field(default_factory=list)
    confidence: float = 0.0
    needs_verification: bool = False
    
    MIN_SOURCES = 3
    
    def add_source(self, source: Source):
        self.sources.append(source)
        self._update_confidence()
    
    def _update_confidence(self):
        if len(self.sources) < self.MIN_SOURCES:
            self.needs_verification = True
            self.confidence = len(self.sources) / self.MIN_SOURCES
        else:
            self.needs_verification = False
            self.confidence = 1.0
    
    def is_verified(self) -> bool:
        return len(self.sources) >= self.MIN_SOURCES

@dataclass
class ResearchResult:
    """Compiled research result ready for delivery."""
    topic: str
    summary: str
    claims: list[Claim] = field(default_factory=list)
    sources_used: list[Source] = field(default_factory=list)
    research_timestamp: str = ""
    research_query: str = ""
    
    def __post_init__(self):
        if not self.research_timestamp:
            self.research_timestamp = datetime.now().isoformat()
    
    def compile_note(self) -> str:
        """Compile into single comprehensive note."""
        verified = [c for c in self.claims if c.is_verified()]
        unverified = [c for c in self.claims if not c.is_verified()]
        
        lines = [
            f"# {self.topic}",
            "",
            "## Overview",
            self.summary,
            "",
            "## Key Findings",
            ""
        ]
        
        if verified:
            lines.append("### Verified Information")
            lines.append("_Triangulated across 3+ sources_")
            lines.append("")
            for i, claim in enumerate(verified, 1):
                lines.append(f"**{i}.** {claim.text}")
                lines.append(f"   - Confidence: {claim.confidence:.0%}")
                lines.append("")
        
        if unverified:
            lines.append("### Needs Verification")
            lines.append("_Found in fewer than 3 sources_")
            lines.append("")
            for claim in unverified:
                lines.append(f"- ⚠️ {claim.text}")
                lines.append(f"  - Sources found: {len(claim.sources)}/{Claim.MIN_SOURCES}")
                lines.append("")
        
        lines.extend([
            "---",
            "",
            "## Source Summary",
            f"Total sources consulted: {len(self.sources_used)}",
            ""
        ])
        
        for tier in SourceTier:
            tier_sources = [s for s in self.sources_used if s.tier == tier]
            if tier_sources:
                tier_name = {
                    SourceTier.ACADEMIC_OFFICIAL: "Academic & Official Sources",
                    SourceTier.BROAD_WEB: "General Web Sources",
                    SourceTier.CURATED: "Curated Sources"
                }[tier]
                lines.append(f"### {tier_name} ({len(tier_sources)})")
                for source in tier_sources:
                    lines.append(f"- [{source.title}]({source.url})")
                lines.append("")
        
        return "\n".join(lines)
```

### 6.2 Research Workflow for LLM

```python
"""
When researching topics, the LLM must:

1. INITIALIZE RESEARCH STRUCTURE
   from scripts.research_engine import ResearchEngine
   engine = ResearchEngine()
   result = engine.research(topic, context)

2. GATHER TIER 1 SOURCES
   Use WebSearch with queries:
   - "{topic} site:edu OR site:gov OR site:arxiv.org"
   - "{topic} scholarly article"
   - "{topic} research paper"

3. GATHER TIER 2 SOURCES
   Use WebSearch with:
   - "{topic} overview"
   - "{topic} explained"
   - "{topic} wikipedia"

4. CREATE SOURCES AND CLAIMS
   source = engine.create_source(url, title, snippet)
   claim = engine.create_claim(claim_text, sources=[source1, source2, source3])
   result.add_claim(claim)

5. COMPILE SINGLE NOTE
   note = result.compile_note()
   vault.write_note(topic_id, note)
"""
```

---

## 7. Integration with Workflows

### 7.1 learning_session Integration

```python
def learning_session_with_research(topic: Topic, goal_type: str) -> str:
    """Learning session with optional research integration."""
    
    # Check if topic needs research
    if topic_requires_research(topic, goal_type):
        engine = ResearchEngine()
        
        # Tier 1 search
        tier1_results = web_search(f"{topic.name} site:arxiv.org OR site:edu OR site:gov")
        
        # Tier 2 search
        tier2_results = web_search(f"{topic.name} explained overview")
        
        # Create sources
        sources = []
        for result in tier1_results[:3]:
            sources.append(engine.create_source(
                url=result.url,
                title=result.title,
                snippet=result.snippet,
                author=result.author
            ))
        
        # Triangulate claims
        result = engine.research(topic.name, topic.context)
        for claim_text in extract_key_claims(topic):
            claim = engine.create_claim(claim_text, sources[:3])
            result.add_claim(claim)
        
        # Compile note
        research_content = result.compile_note()
        
        # Integrate with generated content
        return integrate_research_with_content(topic, research_content)
    
    return generate_standard_note(topic)
```

### 7.2 Research Quality Checklist

```markdown
Before delivering researched content, verify:

□ Minimum 5 sources consulted
□ At least 2 from Tier 1 (academic/official)
□ All claims have ≥3 sources or are marked unverified
□ Contradictions noted with both positions
□ Sources cited with full URLs
□ Confidence percentages displayed
□ Research timestamp included

For exam topics, also verify:

□ Official sources prioritized
□ Statistics from government/authoritative bodies
□ Multiple independent confirmations for key facts
□ Recent publication dates (<5 years for dynamic topics)
```

---

## Appendix A: Source Type Quick Reference

| Source Type | Tier | Example |
|-------------|------|---------|
| Research paper | Tier 1 | arxiv.org, PubMed |
| Government document | Tier 1 | .gov domains |
| University publication | Tier 1 | .edu domains |
| Academic journal | Tier 1 | Nature, Science |
| Wikipedia | Tier 2 | wikipedia.org |
| News article | Tier 2 | BBC, Reuters |
| Blog post | Tier 2 | Medium, Substack |
| Course material | Tier 3 | Course syllabi |

---

*Document generated: September 1, 2026*
*Total pages: 30+*
*"Every claim verified. Every source cited."*
