<!-- VERSION: 2026.06.13#ImprovebackbonecommandswithGSDpatterns+decisions+memory+compact(CHNG-038) -->
<!-- PURPOSE: Claude Code settings, hook bindings, agent definitions -->
# Claude Code Configuration for Your Project

> AI-powered development workspace configuration
>
> **Note:** This is an example configuration. Replace placeholders with your project-specific details after running `./scripts/init-backbone.sh`.

## Available Skills

Skills are organized in `backbone/skills/` under different categories.

To use a skill, load it first, then invoke with natural language:
`view backbone/skills/<category>/<skill-name>/SKILL.md`

### Skill Enforcement (MANDATORY)

**Before writing ANY code**, you MUST acknowledge the relevant skill for the layer:

| Layer | Required Skill | When |
|-------|---------------|------|
| `domain/` | `java/java-core` | Always |
| `app/` | `java/java-cdi` (Quarkus) | When using CDI |
| `api/` | `quarkus/java-quarkus` (Quarkus) | Always |
| `infra/` | None | Always allowed |

**How to acknowledge:**
1. The `pre-tool-use-skill-check.sh` hook blocks Write/Edit operations
2. Type `acknowledge` when prompted, OR load the skill first
3. Acknowledgments reset each session

**Task-linked skills:** If working on a WIP task with required skills in `3-TASKS.md`, acknowledge those at session start.

### 🟢 General Skills
| Skill | Description |
|-------|-------------|
| `api-contract-review` | Review REST API contracts for HTTP semantics, versioning, backward compatibility, and response consistency. |
| `architecture-review` | Analyze project architecture at macro level - package structure, module boundaries, dependency direction, and layering. |
| `changelog-generator` | Generate changelogs from git commits. |
| `clean-code` | Clean Code principles (DRY, KISS, YAGNI), naming conventions, function design, and refactoring. |
| `concurrency-review` | Review concurrency code for thread safety, race conditions, deadlocks, and modern patterns. |
| `design-patterns` | Common design patterns with examples (Factory, Builder, Strategy, Observer, Decorator, etc.). |
| `git-commit` | Generate conventional commit messages. |
| `issue-triage` | Triage and categorize GitHub issues with priority labels. |
| `test-quality` | Write high quality tests with appropriate frameworks. |

### 🔴 Framework-Specific Skills
Your project may have framework-specific skills. Check `backbone/skills/` after initialization.

## Available Slash Commands

This project ships **13 `/backbone:*` slash commands** for AI-assisted workflows. Type `/backbone:<command>` at the prompt:

```
Feature pipeline:  → design → task (xN) → close → close --ship
                   → design --plan (lightweight)
                   → design --amend CHNG-XXX (delta)
Utilities:         review, review --depth quick, review --depth deep, debug, status, help
Admin:             decide, map, qms, cost, sync, push-clean
```

Full reference: `COMMANDS.md` at project root. Command files: `.claude/commands/backbone/`.

### 🟢 Always Available Skills (Auto-Copied)
These are installed automatically on every project init:

**Project Management (15 skills):**
`ab-test-analysis`, `brainstorm-okrs`, `create-prd`, `dummy-dataset`, `job-stories`, `outcome-roadmap`, `pre-mortem`, `prioritization-frameworks`, `release-notes`, `retro`, `sprint-plan`, `sql-queries`, `stakeholder-map`, `test-scenarios`, `user-stories`

**Database (4 skills):**
`postgres-patterns`, `query-optimization`, `schema-design`, `setup`

**Frontend (optional, with `--frontend` flag):**
`frontend-patterns`, `frontend-slides`

**Community (with `--autoskills` flag):**
Skills from [skills.sh](https://skills.sh) auto-detected from tech stack.

## Project Setup (First Time)

1. **Read the documentation roadmap** in [[`backbone/0-START-HERE.md`](backbone/0-START-HERE.md)](backbone/0-START-HERE.md)
    - Explains the dependency hierarchy of all backbone docs
    - Provides reading checklist for developers vs agents

2. **Initialize the backbone** (if `backbone/` is missing):
   ```bash
   ./scripts/init-backbone.sh
   ```

3. **Install git hooks** (one-time, per developer):
   ```bash
   ./scripts/install-hooks.sh
   ```
   This installs validation hooks that check:
    - Framework annotation contamination (blocks commit)
    - Domain layer framework leakage (blocks commit)
    - WIP tasks still open in [[`backbone/3-TASKS.md`](backbone/3-TASKS.md)](backbone/3-TASKS.md) (warning)
    - Project compilation (blocks commit, skip with `SKIP_BUILD=1`)

   **Claude Code hooks** (`.claude/settings.json`) run automatically during AI sessions

## Before Each Session (Agent Checklist)

Agents MUST read these documents in order before making changes:

1. **`COMMANDS.md`** — Available `/backbone:*` slash commands for the feature pipeline
2. **[`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md)** — Understand tech stack, constraints, build commands
3. **`backbone/reference/conventions/java.md`** — Learn framework-specific mappings (if applicable)
4. **[`backbone/8-WORKFLOW.md`](backbone/8-WORKFLOW.md)** — Understand Definition of Done requirements
5. **`backbone/3-TASKS.md`** — Identify current work objective and WIP status

**Full documentation roadmap:** See `backbone/0-START-HERE.md` for complete context.

## Common Workflows

### First-Time Setup
```bash
# 1. Read documentation roadmap
view backbone/0-START-HERE.md

# 2. Initialize backbone (if not done)
./scripts/init-backbone.sh

# 3. Install git hooks
./scripts/install-hooks.sh

# 4. You're ready to develop!
```

### Daily Development Flow
```bash
# 1. Start session
claude code .

# 2. Pre-session: Agent checklist
# Read: COMMANDS.md (slash commands)
# Read: backbone/4-KNOWLEDGE.md
# Read: backbone/reference/conventions/java.md
# Read: backbone/8-WORKFLOW.md
# Check: backbone/3-TASKS.md for current work

# 3. Start a feature (first time)
/backbone:design <name>

# 4. Implement tasks
/backbone:task

# 4. Add tests
> view backbone/skills/general/test-quality/SKILL.md
> "Add tests for new functionality"

# 5. Commit
> view backbone/skills/general/git-commit/SKILL.md
> "Commit staged changes"
```

### Weekly Maintenance
```bash
# Monday morning: Issue triage
claude code .

> view backbone/skills/general/issue-triage/SKILL.md
> "Triage the last 20 issues, categorize and prioritize"

# Review suggested actions
> "Apply labels and post responses as suggested"
```

### Code Review
```bash
# Review PR
> "Review PR #456 focusing on:
   - Test coverage (use test-quality skill)
   - Commit message quality (use git-commit skill)
   - Code patterns and best practices"
```

## Token Budget Guidelines

To optimize token usage:

1. **Load skills once per session** - Skills stay in context
2. **Batch operations** - Process multiple issues/tests together
3. **Use MCP when available** - More efficient than bash commands
4. **Targeted file reads** - Only read files you need

## What to Avoid

1. **Don't reload skills repeatedly** - Load once per session
2. **Don't process issues one-by-one** - Batch them
3. **Don't over-engineer** - Use skills for appropriate tasks
4. **Don't ignore skill guidelines** - They're optimized for tokens

## Project-Specific Notes

### Build Commands
```bash
# [Your build tool - e.g., gradlew, mvn, npm, etc.]
./gradlew clean build
# or: ./mvnw clean package
# or: npm run build
```

### Testing Strategy
- Target: 80%+ coverage on core logic
- Focus: Business logic, skills, hooks, scripts
- Tools: JUnit 5, Mockito, Testcontainers

### Commit Guidelines
- Follow Conventional Commits: `type: description`
- Reference issues: "Fixes #123"
- Keep subject under 50 chars

### Issue Management
- Label all new issues within 48h
- Respond to questions within 1 week
- Close stale (>90 days, no activity) issues

## Resources

- [Claude Code Docs](https://code.claude.com/docs) - Official documentation
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit format

---

**After initializing your project**, update this file with your specific:
- Framework name and version
- Available skills
- Build commands
- Testing strategy
- Commit guidelines
- Issue management SLAs

**Last updated**: 2026-06-16