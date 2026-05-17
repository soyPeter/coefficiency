<!-- FRAMEWORK: GENERAL -->
---
name: create-skill
description: Guides users through creating effective Agent Skills. Use when you want to create, write, or author a new skill, or asks about skill structure, best practices, or SKILL.md format.
framework: general
---

# Creating Skills

Skills are markdown (plus optional scripts) that teach the agent a focused workflow. **Keep SKILL.md short** — the context window is shared with chat, code, and other skills.

## Where Skills Live

| Location | When to use |
|----------|-------------|
| `backbone/skills/<framework>/` | Framework-specific skills (java, quarkus, etc.) |
| `backbone/skills/cross-cutting/<worktype>/` | Cross-cutting skills (testing, security, docker) |
| `backbone/skills/general/` | Universal skills (git-commit, spec-driven-development) |

## Before You Write: Gather Requirements

Ask (or infer) briefly:

1. **Purpose** — one concrete task or workflow.
2. **Triggers** — when should the agent apply this skill?
3. **Gaps** — what does the agent *not* already know?
4. **Outputs** — templates, checklists, or strict formats?
5. **Examples** — follow an existing skill in `backbone/skills/` if one fits.

## File Layout

```
skill-name/
├── SKILL.md       # required
├── reference.md   # optional — detail the agent reads only if needed
├── examples.md    # optional
└── scripts/       # optional
```

### Frontmatter (required)

```yaml
---
name: skill-name          # lowercase, hyphens, max 64 chars
description: >-           # max 1024 chars — see below
  ...
framework: "general"      # or quarkus, springboot, java, etc.
---
```

**Description** (discovery is everything — third person, WHAT + WHEN, trigger words):

- Good: `Generates changelogs from conventional commits. Use when the user says 'generate changelog' or 'what changed'.`
- Bad: `Helps with documents` or `I can help you with PDFs`

## Authoring Rules

1. **Concise** — assume the model is capable; only add non-obvious domain or project facts.
2. **Progressive disclosure** — essentials in `SKILL.md`; long reference in `reference.md`. Link **one level deep**.
3. **Prefer one default** — one library or one workflow; add escape hatches only if needed.
4. **Stable wording** — one term per concept.
5. **Paths** — forward slashes only.

**Rough size:** aim for **well under ~200 lines** in `SKILL.md`; if it grows, split detail out.

### Scope: One Job Per Skill

- **Single responsibility** — one primary workflow per skill.
- **Prefer small + compose** — two focused skills keep irrelevant detail out. A **parent** skill can say *when* to follow each child workflow.
- **When one large skill is OK** — a single end-to-end flow that always runs together.

## Patterns (Pick What Fits)

- **Template** — exact output shape (markdown/code blocks).
- **Checklist** — numbered or `- [ ]` steps.
- **Branching** — "If A → …; if B → …" at the top.
- **Scripts** — document run commands; say whether to execute or read.

## Validation Checklist

Before finishing:

- [ ] Size < 200 lines in SKILL.md?
- [ ] Description has WHAT + WHEN (third person)?
- [ ] One job per skill (or clear parent/child composition)?
- [ ] Examples are clear and copy-pasteable?
- [ ] No duplicate encyclopedic content the model already knows?
- [ ] Framework tag matches the skill's domain?
