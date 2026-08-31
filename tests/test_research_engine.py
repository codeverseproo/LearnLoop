"""Tests for research engine functionality."""

import pytest
from scripts.research_engine import (
    Claim, Source, SourceTier, ResearchResult, ResearchEngine
)


class TestSourceClassification:
    """Test automatic source tier classification."""

    def test_academic_source_edu(self):
        """Test .edu domains classified as tier1."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://stanford.edu/physics",
            title="Quantum Physics"
        )
        assert source.tier == SourceTier.ACADEMIC_OFFICIAL

    def test_government_source(self):
        """Test .gov domains classified as tier1."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://nasa.gov/mission",
            title="Space Mission"
        )
        assert source.tier == SourceTier.ACADEMIC_OFFICIAL

    def test_arxiv_source(self):
        """Test arxiv.org classified as tier1."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://arxiv.org/abs/1234",
            title="Research Paper"
        )
        assert source.tier == SourceTier.ACADEMIC_OFFICIAL

    def test_blog_source(self):
        """Test blog domains classified as tier2."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://medium.com/article",
            title="Blog Post"
        )
        assert source.tier == SourceTier.BROAD_WEB

    def test_news_source(self):
        """Test news sites classified as tier2."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://cnn.com/news/article",
            title="News Article"
        )
        assert source.tier == SourceTier.BROAD_WEB


class TestClaimTriangulation:
    """Test claim verification and triangulation."""

    def test_single_source_unverified(self):
        """Claim with 1 source is unverified."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://example.com",
            title="Example"
        )
        claim = engine.create_claim("Test claim", sources=[source])
        assert not claim.is_verified()
        assert claim.needs_verification

    def test_three_sources_verified(self):
        """Claim with 3 sources is verified."""
        engine = ResearchEngine()
        sources = [
            engine.create_source(f"https://source{i}.com", f"Source {i}")
            for i in range(3)
        ]
        claim = engine.create_claim("Test claim", sources=sources)
        assert claim.is_verified()
        assert not claim.needs_verification

    def test_confidence_increases_with_sources(self):
        """Confidence increases as more sources added."""
        claim = Claim(text="Test")
        assert claim.confidence == 0.0

        source1 = Source(url="https://a.com", title="A", tier=SourceTier.ACADEMIC_OFFICIAL)
        claim.add_source(source1)
        conf1 = claim.confidence

        source2 = Source(url="https://b.com", title="B", tier=SourceTier.ACADEMIC_OFFICIAL)
        claim.add_source(source2)
        assert claim.confidence > conf1

    def test_confidence_normalization_three_tier2_sources(self):
        """3 tier2 sources should give 100% confidence (normalized)."""
        claim = Claim(text="Test")

        for i in range(3):
            claim.add_source(Source(
                url=f"https://blog{i}.com",
                title=f"Blog {i}",
                tier=SourceTier.BROAD_WEB
            ))

        assert claim.is_verified()
        assert claim.confidence == 1.0


class TestResearchResult:
    """Test research result compilation."""

    def test_compile_note_structure(self):
        """Compiled note has required sections."""
        result = ResearchResult(
            topic="Test Topic",
            summary="Test summary"
        )
        note = result.compile_note()

        assert "# Test Topic" in note
        assert "## Overview" in note
        assert "Test summary" in note
        assert "## Key Findings" in note
        assert "## Source Summary" in note

    def test_verified_claims_section(self):
        """Verified claims appear in dedicated section."""
        engine = ResearchEngine()
        sources = [
            engine.create_source(f"https://s{i}.com", f"S{i}")
            for i in range(3)
        ]
        claim = engine.create_claim("Verified claim", sources=sources)

        result = ResearchResult(topic="Test", summary="Summary")
        result.add_claim(claim)
        note = result.compile_note()

        assert "### Verified Information" in note
        assert "Verified claim" in note
        assert "100%" in note or "Triangulated" in note

    def test_unverified_claims_warning(self):
        """Unverified claims show warning."""
        engine = ResearchEngine()
        claim = engine.create_claim("Unverified claim", sources=[
            engine.create_source("https://one.com", "One")
        ])

        result = ResearchResult(topic="Test", summary="Summary")
        result.add_claim(claim)
        note = result.compile_note()

        assert "### Needs Verification" in note
        assert "Unverified claim" in note
        assert "Sources found: 1/3" in note

    def test_source_summary_by_tier(self):
        """Sources grouped by tier in summary."""
        engine = ResearchEngine()
        sources = [
            engine.create_source("https://stanford.edu/paper", "Academic Paper"),
            engine.create_source("https://blog.com/post", "Blog Post")
        ]
        claim = engine.create_claim("Claim", sources=sources)

        result = ResearchResult(topic="Test", summary="Summary")
        result.add_claim(claim)
        note = result.compile_note()

        assert "Academic & Official Sources" in note
        assert "General Web Sources" in note


class TestResearchEngine:
    """Test research engine operations."""

    def test_create_source_with_metadata(self):
        """Source created with full metadata."""
        engine = ResearchEngine()
        source = engine.create_source(
            url="https://nature.com/article",
            title="Nature Article",
            snippet="Key findings...",
            author="Dr. Smith",
            institution="MIT",
            published_date="2024-01-15"
        )

        assert source.url == "https://nature.com/article"
        assert source.author == "Dr. Smith"
        assert source.institution == "MIT"
        assert source.published_date == "2024-01-15"
        assert source.tier == SourceTier.ACADEMIC_OFFICIAL

    def test_min_sources_configurable(self):
        """Minimum sources can be configured."""
        engine = ResearchEngine(min_sources=5)
        assert engine.min_sources == 5
