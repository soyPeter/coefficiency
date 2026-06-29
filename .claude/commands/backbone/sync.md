---
name: backbone:sync
description: Sync skills from generator to project
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Edit
required-skills: []
---

<objective>
Validate all SKILL.md files and sync the skills manifest.

**Renamed from:** `sync-skills` (now deprecated)

**Checks:**
1. Every SKILL.md has required frontmatter (name, description, framework)
2. No SKILL.md exceeds 300 lines
3. Descriptions use third person (not "I...")
4. Framework tags match directory structure
5. Generate skills manifest for dev-portal

**Fixes applied:**
- Add missing frontmatter fields
- Report oversized skills
- Suggest splitting large skills into reference.md
</objective>

<process>
## Step 1: Find all skills

```bash
find backbone/skills -name "SKILL.md" -type f
```

## Step 2: Validate each skill

For each SKILL.md:
- Check frontmatter contains: name, description, framework
- Check line count <= 300
- Check description doesn't start with "I "
- Verify framework tag matches parent directory

## Step 3: Report violations

- List skills with missing frontmatter
- List skills >300 lines with line counts
- List first-person descriptions
- List framework mismatches

## Step 4: Auto-fix (optional)

- Add missing `framework: GENERAL` if in general/ directory
- Add missing `name:` from directory name

## Step 5: Generate manifest

- Update dev-portal skills index if needed
- Report new skills not in index

## Step 6: Report

```
✅ Skills sync complete

Validated: N skills
  - Valid frontmatter: N
  - Oversized (>300 lines): N (reported)
  - First-person descriptions: N
  - Framework mismatches: N

Manifest updated: dev-portal/skills-index.md
```
</process>

<success_criteria>
- [ ] All skills have valid frontmatter
- [ ] No skills exceed 300 lines (without justification)
- [ ] All descriptions use third person
- [ ] Framework tags match directory structure
- [ ] Manifest updated
</success_criteria>