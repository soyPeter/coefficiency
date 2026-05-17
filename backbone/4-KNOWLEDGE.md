<!-- VERSION: 2026.05.13#5-commandpipeline,16commandstotal -->
# 4. Knowledge (Product Soul)

*This file describes THIS project — a software project built with the Agentic Backbone framework.*

## What This Project Is

This is a **jooby** software project scaffolded with Agentic Backbone. It includes:
- Framework-specific conventions and best practices
- AI agent guardrails and documentation standards
- CI/CD, Docker, and deployment configurations

## Current Tech Stack

### Core Technologies
- **Framework:** jooby
- **Build Tool:** gradle
- **Language:** See framework conventions for language details

### Architecture

Generated projects use **DDD / Hexagonal Architecture** with three layers:

```
<project-root>/
├── backbone/              # Documentation, PRDs, plans, decisions
│   ├── skills/           # AI agent skills (framework-specific patterns)
│   ├── reference/        # Conventions, guides, patterns
│   └── prd/              # Product requirement documents
├── src/                  # Application source code
│   ├── domain/          # Domain layer (entities, value objects, events)
│   ├── app/             # Application layer (services, use cases, ports)
│   └── infra/           # Infrastructure layer (ALL framework code)
│       ├── io/rest/     # REST controllers, resources, routes
│       ├── data/dto/    # Request/response DTOs
│       ├── data/persistence/  # Repositories, database access
│       └── config/      # Framework configuration
├── scripts/             # Automation scripts
│   └── hooks/          # Git hooks and agent hooks
├── tests/               # Test suites
└── .claude/             # Claude Code configuration (hooks, settings, agents)
```

**Layer rules:**
- `domain/` — **Framework-free.** No Quarkus, Spring, Jakarta, or Lombok imports
- `app/` — Use cases and ports (interfaces). No framework annotations
- `infra/` — **All** framework code. REST controllers live in `infra/io/rest/`, not a separate top-level package

## Universal Naming Convention (MANDATORY)

**All identifiers MUST be in English.** This applies to every framework, every language, every file.

| What | Rule | Good | Bad |
|------|------|------|-----|
| **Classes / Types** | PascalCase, English only | `UserController`, `OrderService` | `UsuarioControlador`, `CommandeService` |
| **Methods / Functions** | camelCase, English only | `getAllMetrics()`, `parseCsv()` | `obtenerMetricas()`, `analyserFichier()` |
| **Variables / Fields** | camelCase, English only | `metricCount`, `isActive` | `contadorMetricas`, `estActif` |
| **Constants** | UPPER_SNAKE_CASE, English only | `MAX_RETRY_COUNT`, `DEFAULT_PORT` | `MAX_INTENTOS`, `PORT_PAR_DEFAUT` |
| **Packages / Modules** | lowercase, English only | `io.bitnomio.metric` | `io.bitnomio.metricas` |
| **Files / Directories** | lowercase-with-dashes or PascalCase, English only | `metric-controller.ts`, `MetricController.java` | `controlador-metricas.ts` |
| **Database tables / columns** | snake_case, English only | `metrics`, `created_at` | `metricas`, `fecha_creacion` |
| **API endpoints** | kebab-case, English only | `/api/metrics`, `/file-import` | `/api/metricas`, `/importar-archivo` |
| **Environment variables** | UPPER_SNAKE_CASE, English only | `DATABASE_URL`, `API_KEY` | `URL_BASE_DE_DATOS` |

**Why:** AI agents, code review tools, documentation generators, and international team members all expect English. Mixed-language identifiers break search, static analysis, and LLM context windows.

**NEVER use:** Spanish, French, German, or any other language in identifiers. Comments may be bilingual if the team requires it, but code must be English-only.

## Key Distinction

| | This Project | Agentic Backbone (Generator) |
|---|---|---|
| **Purpose** | Your software application | Project scaffolding & DX framework |
| **Location** | Your workspace | `$HOME/projects/agentic-backbone` |
| **Language** | jooby | Bash, Python, Node.js |

## Development Workflow

1. **Plan:** Write PRDs in `backbone/prd/`
2. **Implement:** Follow framework conventions in `backbone/reference/conventions/`
3. **Test:** Use skills from `backbone/skills/` for testing patterns
4. **Document:** Update decisions in `backbone/5-DECISIONS.md`, lessons in `backbone/6-MEMORY.md`
5. **Commit:** Follow conventional commits (load `backbone/skills/general/git-commit/SKILL.md`)

## Reference Documentation

- **Conventions:** `backbone/reference/conventions/` — framework-specific syntax and patterns
- **Hooks:** `scripts/hooks/` — pre-commit, pre-push, agent integration
- **Skills:** `backbone/skills/` — AI agent patterns for this framework

## Context7 Integration (Live Documentation)

Context7 brings up-to-date, version-specific library docs into the agent's context. It's configured as an MCP server in `.claude/settings.json` — agents call `resolve-library-id` + `query-docs` natively.

### Setup (One-Time, Per Developer)

> **⚠️ REQUIRED: You must obtain and configure an API key, or the MCP server won't start.**

```bash
# 1. Run the setup wizard (opens browser for OAuth, generates a free key):
npx ctx7 setup --claude

# 2. Copy the key from the output, add it to your shell profile:
echo 'export CONTEXT7_API_KEY=ctx7sk_your_key_here' >> ~/.zshrc
source ~/.zshrc

# Alternative: add to .claude/settings.local.json (stays in project scope):
# {
#   "mcpServers": {
#     "context7": {
#       "command": "npx",
#       "args": ["-y", "@upstash/context7"],
#       "env": { "CONTEXT7_API_KEY": "ctx7sk_your_key_here" }
#     }
#   }
# }
```

**Without the key**, agents attempting `query-docs` will receive an auth error. The session continues normally — only Context7 is unavailable.

## Skills

Skills in `backbone/skills/` are for AI agents working on THIS project:
- **General:** `git-commit`, `spec-driven-development`
- **Cross-cutting:** `testing`, `security`, `docker`
- **Framework-specific:** `java/`, `quarkus/`, `springboot/` (as applicable)

**Important:** When working on this project, load framework-specific skills from `backbone/skills/jooby/`. Language-specific patterns are defined in the conventions file.

*For full knowledge, see: [[knowledge/index]]*
