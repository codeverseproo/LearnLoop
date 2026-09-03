#!/usr/bin/env python3
"""Research engine for MIT Learning Skill.

Layered research: Academic + Official → Broad Web → Curated sources.
Triangulates claims across ≥3 sources. Compiles into single comprehensive note.
"""

import hashlib
import json
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Optional


class SourceTier(Enum):
    """Research source hierarchy."""
    ACADEMIC_OFFICIAL = "tier1"    # Papers, gov, institutional
    BROAD_WEB = "tier2"           # General web search
    CURATED = "tier3"             # User-specified feeds


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
        """Generate unique citation key."""
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
        """Add a source to this claim."""
        self.sources.append(source)
        self._update_confidence()

    def _update_confidence(self):
        """Update confidence based on source count.

        Normalized so that meeting MIN_SOURCES gives 100% confidence.
        """
        if len(self.sources) < self.MIN_SOURCES:
            self.needs_verification = True
            self.confidence = len(self.sources) / self.MIN_SOURCES
        else:
            self.needs_verification = False
            self.confidence = 1.0

    def is_verified(self) -> bool:
        """Check if claim meets minimum source threshold."""
        return len(self.sources) >= self.MIN_SOURCES

    def to_dict(self) -> dict:
        return {
            "text": self.text,
            "sources": [s.to_dict() for s in self.sources],
            "confidence": round(self.confidence, 2),
            "needs_verification": self.needs_verification
        }


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

    def add_claim(self, claim: Claim):
        """Add a triangulated claim."""
        self.claims.append(claim)
        for source in claim.sources:
            if source not in self.sources_used:
                self.sources_used.append(source)

    def get_verified_claims(self) -> list[Claim]:
        """Get only claims with ≥3 sources."""
        return [c for c in self.claims if c.is_verified()]

    def get_unverified_claims(self) -> list[Claim]:
        """Get claims needing more research."""
        return [c for c in self.claims if not c.is_verified()]

    def compile_note(self) -> str:
        """Compile into single comprehensive note.

        This is the deliverable - a single source the user reads
        without needing external references.
        """
        verified = self.get_verified_claims()
        unverified = self.get_unverified_claims()

        lines = [
            f"# {self.topic}",
            "",
            "## Overview",
            self.summary,
            "",
            "## Key Findings",
            ""
        ]

        # Verified claims (high confidence)
        if verified:
            lines.append("### Verified Information")
            lines.append("_Triangulated across 3+ sources_")
            lines.append("")
            for i, claim in enumerate(verified, 1):
                lines.append(f"**{i}.** {claim.text}")
                lines.append(f"   - Confidence: {claim.confidence:.0%}")
                lines.append("")

        # Unverified claims (needs more research)
        if unverified:
            lines.append("### Needs Verification")
            lines.append("_Found in fewer than 3 sources - verify independently_")
            lines.append("")
            for claim in unverified:
                lines.append(f"- ⚠️ {claim.text}")
                lines.append(f"  - Sources found: {len(claim.sources)}/{Claim.MIN_SOURCES}")
                lines.append("")

        # Source summary
        lines.extend([
            "---",
            "",
            "## Source Summary",
            f"Total sources consulted: {len(self.sources_used)}",
            ""
        ])

        # Group by tier
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
                    if source.author:
                        lines.append(f"  - Author: {source.author}")
                    if source.institution:
                        lines.append(f"  - Institution: {source.institution}")
                lines.append("")

        # Research timestamp
        lines.extend([
            "---",
            f"_Research completed: {self.research_timestamp}_",
            f"_Query: {self.research_query}_"
        ])

        return "\n".join(lines)

    def to_dict(self) -> dict:
        return {
            "topic": self.topic,
            "summary": self.summary,
            "claims": [c.to_dict() for c in self.claims],
            "sources_used": [s.to_dict() for s in self.sources_used],
            "research_timestamp": self.research_timestamp,
            "research_query": self.research_query
        }

    def save(self, path: Path) -> Path:
        """Save research result as JSON for later reference."""
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            json.dump(self.to_dict(), f, indent=2)
        return path


class ResearchEngine:
    """Layered research engine for comprehensive information compilation.

    Usage:
        engine = ResearchEngine()
        result = engine.research("Quantum entanglement", context="physics")
        note = result.compile_note()
    """

    # Source type indicators for tier classification
    ACADEMIC_INDICATORS = [
        ".edu", ".gov", ".org", "arxiv.org", "pubmed", "scholar.google",
        "nature.com", "science.org", "springer", "ieee", "acm.org",
        "researchgate", "semanticscholar", "doi.org"
    ]

    OFFICIAL_INDICATORS = [
        ".gov", ".mil", ".int", ".eu", "un.org", "worldbank.org",
        "who.int", "imf.org", "oecd.org"
    ]

    def __init__(self, min_sources: int = 3):
        self.min_sources = min_sources

    def classify_source_tier(self, url: str) -> SourceTier:
        """Classify source into tier based on URL."""
        url_lower = url.lower()

        # Check for academic/official indicators
        for indicator in self.ACADEMIC_INDICATORS + self.OFFICIAL_INDICATORS:
            if indicator in url_lower:
                return SourceTier.ACADEMIC_OFFICIAL

        # Default to broad web
        return SourceTier.BROAD_WEB

    def research(self, topic: str, context: str = "") -> ResearchResult:
        """
        Perform layered research on a topic.

        NOTE: This method returns a template. In actual usage, the LLM
        must use WebSearch tool to gather sources and populate claims.

        The LLM should:
        1. Call this method to get the structure
        2. Use WebSearch to find tier1 sources (academic/official)
        3. Use WebSearch for tier2 sources (broad web)
        4. Use WebSearch or WebFetch for tier3 sources (curated)
        5. Triangulate each claim across ≥3 sources
        6. Populate claims and compile the final note

        Args:
            topic: The topic to research
            context: Additional context (e.g., "for exam prep")

        Returns:
            ResearchResult structure to populate
        """
        return ResearchResult(
            topic=topic,
            summary="[LLM to fill after research]",
            research_query=f"{topic} {context}".strip()
        )

    def create_source(self, url: str, title: str, snippet: str = "",
                      author: str = None, institution: str = None,
                      published_date: str = None) -> Source:
        """Create a source with automatic tier classification."""
        tier = self.classify_source_tier(url)
        return Source(
            url=url,
            title=title,
            tier=tier,
            snippet=snippet,
            author=author,
            institution=institution,
            published_date=published_date
        )

    def create_claim(self, text: str, sources: list[Source] = None) -> Claim:
        """Create a claim with optional sources."""
        claim = Claim(text=text)
        if sources:
            for source in sources:
                claim.add_source(source)
        return claim
