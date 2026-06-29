---
name: backbone:decide
description: Record important decision — options, rationale, ADR, decision log.
argument-hint: "<decision-title> [--impl] [--supersedes D5,D8] [--adr]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Question
required-skills:
  - general/documentation-and-adrs
---

<objective>
Record a small but important decision with full context, alternatives
considered, rationale, and consequences.

**Renamed from:** `decision` (now deprecated)

**When to use:**
- Choosing a library, framework, or tool
- Deciding on an architectural approach
- Changing a convention or standard
- Any decision that would be expensive to reverse

**Flags:**
- `--impl` — Generate EARS requirements and tasks after recording
- `--supersedes D5,D8` — Mark old decisions as superseded
- `--adr` — Create an ADR file in backbone/reference/patterns/adr/
</objective>

<process>
## Step 0: Load Required Skills & Scaffold

1. **Load skills** — Read this command's `required-skills` frontmatter. For each entry:
   - If `backbone/skills/<path>/SKILL.md` exists → `view backbone/skills/<path>/SKILL.md`
   - If not → use `skill tool "<basename>"` as fallback

2. **Scaffold:**
- Extract `<decision-title>` (required) — short slug, lowercase with hyphens
- Parse `--impl`, `--supersedes`, `--adr`
- Run `./scripts/backbone-change-init.sh <decision-title>` to scaffold CHNG-NNN
- Note the CHNG-ID

## Step 1: Collect Decision Context

Ask the user using the `Question` tool (one at a time):

1. **Title** — What is the decision about?
2. **Context** — What situation prompted this decision?
3. **Options** — What were the alternatives considered? List each with pros/cons.
4. **Decision** — Which option was chosen and why?
5. **Consequences** — What are the positive and negative consequences?

## Step 2: Write Decision Proposal

Edit `$CHANGE_DIR/proposal.md` with the decision context.

## Step 3: Mark Superseded Decisions (if --supersedes)

For each decision number in the `--supersedes` list:
1. Find the entry in [[`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md)](backbone/5-DECISIONS.md)
2. Add `**Status:** Superseded` and `**Superseded by:** D-NEW`

## Step 4: Create ADR (if --adr)

Find next available ADR number and create:
`backbone/reference/patterns/adr/NNN-decision-name.md`

Update [`backbone/reference/patterns/adr/README.md`](backbone/reference/patterns/adr/README.md).

## Step 5: Update Decision Log

Add an entry to `backbone/5-DECISIONS.md`.

## Step 6: Tasks (if --impl)

If `--impl` was set:
1. Load EARS requirements skill
2. Edit `$CHANGE_DIR/tasks.md` with granular implementation tasks
3. Add entries to [`backbone/3-TASKS.md`](backbone/3-TASKS.md)
4. Mark first task as `[WIP]`

## Step 7: Report

```
✅ Decision recorded: <decision-title>

Artifacts:
  - Change folder: backbone/artifacts/changes/$CHNG_ID/
  - Proposal:      proposal.md
  - ADR:           backbone/reference/patterns/adr/NNN-name.md (if --adr)
  - Decision Log:  backbone/5-DECISIONS.md (D$NEXT_N)

Next: Run /backbone:task
```
</process>

<critical_rules>
- ALWAYS create a CHNG folder — decisions should be traceable
- ALWAYS record at least 2 alternatives considered
- If `--impl` is set, generate proper EARS requirements
</critical_rules>

<success_criteria>
- [ ] CHNG folder scaffolded
- [ ] Decision context, options, rationale, and consequences documented
- [ ] ADR file created (if --adr)
- [ ] Decision log updated
- [ ] (if --impl) EARS requirements and tasks written
</success_criteria>