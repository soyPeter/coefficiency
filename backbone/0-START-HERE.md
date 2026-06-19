<!-- VERSION: 2026.05.29 -->
<!-- PURPOSE: Reading roadmap with reading order for developers and AI agents -->
# 0. START HERE — Reading Roadmap

Welcome to the backbone knowledge system. This document explains the reading order for both developers and AI agents.

## For New Developers (Onboarding Path)

Read these documents in order to understand the project:

1. **`1-PRD.md`** — What we're building (product requirements, feature goals)
2. **`2-PLANNING.md`** — How it's structured (module layout, system flows, architecture style)
3. **`4-KNOWLEDGE.md`** — Rules of the road (tech stack, design preferences, constraints)
4. **`backbone/reference/conventions/<framework>.md`** — Framework-specific translation guide (if applicable)
5. **`9-AGENT-SKILLS.md`** — Available AI skills, slash commands, and agents

**Additional context** (read after understanding the above):
- **`5-DECISIONS.md`** — Why we chose each approach (architectural decisions log)
- **`6-MEMORY.md`** — Hard-won lessons, traps to avoid, current status

## For AI Agents (Pre-Execution Checklist)

Before making any changes, agents MUST read:

1. **`4-KNOWLEDGE.md`** — Understand tech stack and constraints
2. **`backbone/reference/conventions/<framework>.md`** — Learn framework-specific mappings (if applicable)
3. **`AGENTS.md`** — Check SDD review gates (R→D→I→V). **PRD required before design doc. Design doc required before code.**
4. **`8-WORKFLOW.md`** — Understand agent execution requirements and Definition of Done
5. **`3-TASKS.md`** — Identify current objective and WIP status
6. **`9-AGENT-SKILLS.md`** — Load required skills before coding

**Skill Enforcement:** Before writing code, you MUST acknowledge the relevant skill for the layer you're working in. The `pre-tool-use-skill-check.sh` hook will block until you type `acknowledge` or load the skill first.

**Security Layer:** The GSD security layer is active by default. Read Guard and Injection Guard may block operations — type `acknowledge` after review to proceed.

**Context7 (Live Docs):** This project has Context7 configured as an MCP server for up-to-date library documentation. To use it, obtain a free API key via `npx ctx7 setup --claude` and set `CONTEXT7_API_KEY` in your env or `.claude/settings.local.json`. Without the key, the MCP server won't start — see `4-KNOWLEDGE.md` for details.

## Document Dependency Diagram

```
1-PRD.md (WHAT we're building)
    ↓
2-PLANNING.md (HOW it's structured)
    ↓
4-KNOWLEDGE.md (tech stack + constraints)
    ├→ 5-DECISIONS.md (WHY each choice)
    ├→ 6-MEMORY.md (runtime learning, status)
    ├→ backbone/reference/conventions/<framework>.md (Framework mapping)
    │    ↓
    └→ 8-WORKFLOW.md (HOW agents execute work)
          ↓
          9-AGENT-SKILLS.md (WHAT tools available)
```

## Key Checkpoints

**Before writing code:**
- ✅ Read 4-KNOWLEDGE.md (understand constraints)
- ✅ Read backbone/reference/conventions/<framework>.md (verify syntax if applicable)
- ✅ Read 8-WORKFLOW.md (understand DoD)
- ✅ Check 3-TASKS.md (identify current work)
- ✅ **SDD Gates satisfied:** PRD exists → Design doc exists → REQ- IDs in code
- ✅ **Acknowledge required skills** (pre-tool-use-skill-check.sh will block until acknowledged)

**Before committing:**
- ✅ Code adheres to architectural boundaries (4-KNOWLEDGE.md)
- ✅ Tests written according to project standards (8-WORKFLOW.md)
- ✅ Required coverage targets met (8-WORKFLOW.md)
- ✅ Traceability matrix updated (`./scripts/verify-traceability.sh` passes)
- ✅ Hooks validate conventions automatically (if configured)
- ✅ Security: no secrets, no injection patterns (pre-commit + injection guard)
- ✅ Update 5-DECISIONS.md, 6-MEMORY.md, 3-TASKS.md with findings
- ✅ Commit using project's commit format (hooks may enforce this)

## Common Questions

**Q: I'm new. Where do I start?**
A: Read 1-PRD → 2-PLANNING → 4-KNOWLEDGE. Takes 15-30 minutes.

**Q: I'm an AI agent. What should I load?**
A: Load 4-KNOWLEDGE first, then backbone/reference/conventions/<framework>.md if applicable, then check 3-TASKS for your work. Read 8-WORKFLOW for DoD requirements.

**Q: I'm an AI agent. 3-TASKS.md shows M1: Project Bootstrap as [WIP]. What do I do?**
A: **Start bootstrapping immediately.** For new projects, M1 is pre-marked [WIP]. Do not ask the user for permission. Begin with:
1. Read `backbone/reference/conventions/<framework>.md` to understand framework patterns
2. Verify the build tool is configured (e.g., `build.gradle.kts` for Gradle)
3. Set up the source directory structure per the conventions
4. Create a minimal working build
5. Mark M1 tasks as [x] in 3-TASKS.md as you complete them

**Q: Why so many documents?**
A: These docs encode project decisions so agents don't repeat work and maintain consistency.

## Releases

Release notes live in `backbone/releases/`. See `/CHANGELOG.md` for the full changelog.

---

*For the file-level document listing, see each root file above — they serve as their own indexes.
Subdirectory `index.md` files are intentionally omitted to avoid duplication.*
