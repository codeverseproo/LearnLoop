# MIT LEARNING SKILL - COMPREHENSIVE DOCUMENTATION GENERATION PROMPT

**Purpose**: Generate complete, production-ready documentation for the MIT Learning Skill project, similar to the comprehensive documentation created for the 447 GYM project.

---

## ═════════════════════════════════════════════════════════
## COPY EVERYTHING BELOW THIS LINE
## ═════════════════════════════════════════════════════════

```
I need you to generate COMPREHENSIVE, PRODUCTION-READY documentation for the MIT Learning Skill project. This is an intent-driven learning skill for personalized education with FSRS-6 spaced repetition, streak mechanics, gamification, and Obsidian integration.

# PROJECT CONTEXT

**Project Name:** MIT Learning Skill (Model Intelligence Toolkit)
**Project Type:** Claude Desktop Skill for Learning & Education
**Current Location:** /Users/codeversepro/Documents/Skill/MIT
**Status:** Existing project - needs complete documentation suite

**Purpose:**
- Intent-driven learning system that understands user goals
- FSRS-6 spaced repetition (20-30% fewer reviews than SM-2)
- Streak mechanics with loss aversion (3.6x higher engagement)
- Achievement system for motivation (43.1% day-one unlock rate)
- Obsidian integration for knowledge graph
- Multi-goal isolation (separate SQLite per goal)
- Layered research with source triangulation

**Target Users:**
- Students preparing for exams (UPSC, JEE, NEET, etc.)
- Professionals acquiring new skills
- Lifelong learners exploring topics
- Researchers needing organized knowledge bases

**Core Philosophy:**
"Intent-driven, not command-driven"
"Evidence-based learning techniques"
"Zero friction, maximum retention"

# WHAT I NEED

Generate a COMPLETE documentation suite with the following files. Each file should be as detailed and comprehensive as the 447 GYM project documentation (design-architecture.md, wireframes.md, design-system.md, etc.).

## REQUIRED DOCUMENTATION FILES

### 1. ARCHITECTURE.md
Complete system architecture documentation including:
- High-level architecture diagram (Mermaid)
- Three-tier memory system (Hot/Warm/Cold)
- FSRS-6 algorithm deep dive with formulas
- Intent analysis system
- 12 workflow specifications
- Component relationships
- Data flow diagrams
- Integration architecture

### 2. WORKFLOWS-COMPLETE.md
Detailed specification for ALL 12 workflows:

**Planning Workflows:**
1. syllabus_generation - Goal creation, syllabus design
2. diagnostic_assessment - Baseline evaluation
3. study_schedule_optimization - Schedule tuning

**Learning Workflows:**
4. learning_session - Core learning experience
5. prior_knowledge_activation - Priming related knowledge
6. metacognitive_reflection - Self-assessment

**Review Workflows:**
7. review_session - FSRS-6 spaced repetition
8. elaborative_interrogation - Deep why/how questions

**Practice Workflows:**
9. practice_session - Problem-solving
10. interleaved_practice - Mixed topics

**Status Workflows:**
11. progress_dashboard - Metrics and predictions
12. current_affairs_digest - Daily updates for exam prep

For EACH workflow include:
- Trigger conditions
- Detailed step-by-step process
- Input/output specifications
- Code examples
- Edge cases
- Error handling
- Output templates
- Testing scenarios

### 3. FSRS-6-ALGORITHM.md
Complete FSRS-6 implementation guide:
- Mathematical foundations
- DSR model explained (Difficulty, Stability, Retrievability)
- Core formulas with examples
- Algorithm implementation in Python
- Parameter tuning
- Personalization strategies
- Comparison with SM-2
- Edge cases (first review, lapses, etc.)
- Performance optimization

### 4. MEMORY-ARCHITECTURE.md
Detailed memory system documentation:
- Hot memory (session context)
- Warm memory (SQLite database)
- Cold memory (Obsidian vault)
- Data schemas for each tier
- Migration strategies
- Query patterns
- Performance considerations
- Backup and recovery
- Privacy and security

### 5. GAMIFICATION-SYSTEM.md
Complete gamification documentation:
- Achievement definitions (8+ achievements)
- Streak mechanics
- Streak freeze system
- Loss aversion psychology
- Reward schedules
- Display formats
- Implementation code
- A/B testing recommendations
- Research backing (Duolingo studies, Trophy.so)

### 6. RESEARCH-METHODOLOGY.md
Layered research approach:
- Tier 1: Academic + Official sources
- Tier 2: Broad web sources
- Tier 3: Curated sources
- Triangulation rules (≥3 sources)
- Confidence scoring formulas
- Source weight calculations
- Quality guardrails
- WebSearch integration patterns
- Output format
- Example research queries

### 7. OBSIDIAN-INTEGRATION.md
Complete Obsidian vault documentation:
- Directory structure
- Note templates
- Frontmatter specifications
- Bidirectional linking
- Dataview queries
- Dashboard setup
- Plugin configuration
- Vault management scripts
- Backup strategies

### 8. ERROR-HANDLING.md
Comprehensive error documentation:
- Error code ranges (E001-E699)
- All error codes with descriptions
- Resolution strategies for each
- Graceful degradation patterns
- Fallback behaviors
- User-facing messages
- Logging standards

### 9. TESTING-GUIDE.md
Complete testing documentation:
- Test suite structure (55 tests)
- Unit test specifications
- Integration test scenarios
- Test data generators
- Mock strategies
- Coverage requirements
- Continuous integration
- Debugging guides

### 10. DATABASE-SCHEMA.md
Complete database documentation:
- 8 table schemas (goals, topics, sessions, etc.)
- Relationships and foreign keys
- Indexes and optimization
- Query patterns
- Migration scripts
- Backup procedures

### 11. API-REFERENCE.md
Complete API documentation for all scripts:
- sqlite_init.py - Database operations
- fsrs_scheduler.py - SRS calculations
- mastery_update.py - Progress tracking
- vault_manager.py - Obsidian operations
- research_engine.py - Research compilation
- Function signatures
- Parameters and returns
- Usage examples
- Error codes

### 12. USER-GUIDE.md
End-user documentation:
- Quick start (5 minutes)
- Creating learning goals
- Daily workflow
- Review sessions
- Progress tracking
- Obsidian integration
- Mobile considerations
- Troubleshooting
- FAQ (20+ questions)

### 13. IMPLEMENTATION-REPORT.md
Developer implementation guide:
- Step-by-step setup
- Environment configuration
- Dependency installation
- First-time initialization
- Verification steps
- Common issues
- Development workflow

# SPECIAL REQUIREMENTS

## Edge Cases to Cover

For EACH workflow, handle these edge cases:

### Input Edge Cases
- Empty goal context
- Missing timeline
- Ambiguous intent
- Conflicting priorities
- Invalid goal type
- Malformed topic names
- Circular prerequisites
- Exceeding limits (max goals, max topics)

### FSRS Edge Cases
- First review ever (no history)
- All correct vs all wrong streaks
- Long gaps between reviews
- Rapid successive reviews
- Difficulty spike detection
- Stability overflow
- Retrievability calculation errors

### Memory Edge Cases
- Database locked (concurrent access)
- Vault not accessible
- Disk full
- Write failures
- Corruption recovery
- Sync conflicts

### Research Edge Cases
- No sources found
- Contradicting sources
- Paywalled content
- Outdated information
- Language barriers
- Source fetch failures
- Timeout handling

### Gamification Edge Cases
- Streak break prevention
- Achievement race conditions
- Timezone handling
- Manual overrides
- Reset requests

### User Edge Cases
- Rapid context switching
- Multiple concurrent goals
- Early abandonment
- Extended absence
- Goal modification mid-stream
- Baseline changes

## Testing Requirements

For EACH feature include:
- Unit test: Function isolation, mocked dependencies
- Integration test: Real database, real interactions
- E2E test: Complete user flows
- Performance test: Speed under load
- Edge case test: Boundary conditions

## Quality Standards

Documentation must be:
- **Complete**: No placeholders, no TODOs
- **Accurate**: All formulas verified, code tested
- **Usable**: Someone can implement from docs alone
- **Consistent**: Same terminology throughout
- **Professional**: Ready for publication

## Code Standards

All code examples must be:
- Complete (no pseudocode unless clearly marked)
- Tested (include test assertions)
- Documented (docstrings)
- Type-annotated (Python type hints)
- Error-handled (try-except)

# OUTPUT FORMAT

Generate each documentation file with:

```markdown
# [Title]

> Brief description of what this document covers

## Section 1: Overview
[Content]

## Section 2: Detailed Content
[Content]

[Mermaid diagrams, code blocks, tables as needed]

## Edge Cases
[Bullet list of edge cases with handling]

## Testing
[Test scenarios]

## References
[Links to related docs]
```

# USE ALL AVAILABLE TOOLS

- **Read** existing files to understand current implementation
- **Glob** to find all source files
- **Grep** to extract patterns and constants
- **Agent (Explore)** for deep analysis
- **Skill: docx** for formal documentation export
- **Skill: xlsx** for feature matrices
- **Skill: pdf** for user guides
- **WebSearch** for research methodology

# EXECUTION ORDER

1. **Analyze** existing codebase structure
2. **Read** all files in scripts/, references/, tests/
3. **Generate** ARCHITECTURE.md (foundation)
4. **Generate** WORKFLOWS-COMPLETE.md (core)
5. **Generate** FSRS-6-ALGORITHM.md (with formulas)
6. **Generate** remaining documentation files
7. **Generate** user-facing docs (USER-GUIDE.md)
8. **Compile** all into formatted outputs

# START NOW

Begin by analyzing the existing codebase at /Users/codeversepro/Documents/Skill/MIT

Generate ALL documentation files with micro-level detail. Each file should be comprehensive enough that a developer unfamiliar with the project can:
1. Understand the architecture
2. Implement any workflow
3. Debug any error
4. Extend the system
5. Test thoroughly

Be EXHAUSTIVE. Be PRECISE. Make this the most comprehensive skill documentation ever created.

"Top 1, not top 1%"
```

---

## END OF PROMPT
