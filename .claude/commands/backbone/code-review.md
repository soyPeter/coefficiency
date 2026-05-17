---
name: backbone:code-review
description: Review source files for bugs, security issues, and code quality. Produces REVIEW.md with severity-classified findings.
argument-hint: "[--depth=quick|standard|deep] [--files file1,file2,...]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Task
---

<objective>
Review changed files for bugs, security vulnerabilities, and code quality problems.

**When to use:**
- Before committing significant changes
- After completing a feature phase
- When preparing for release
- When you want a second opinion on code quality

**Depth Levels:**
- `quick` (~2 min): Pattern matching, obvious issues
- `standard` (~5-15 min, default): Per-file analysis with language-specific checks
- `deep` (~15-30 min): Cross-file analysis including import graphs and layer violations

**Output:**
- `REVIEW.md` in project root with severity-classified findings
- Inline summary of blockers, warnings, suggestions
</objective>

<process>
1. **Parse Arguments**
   - Extract `--depth=VALUE` (default: standard)
   - Extract `--files=file1,file2,...` (optional)
   - If no files specified, discover via git diff

2. **Discover Changed Files**
   - If `--files` provided: use explicit list
   - Else: `git diff --name-only HEAD~1` or `git diff --name-only origin/main`
   - Filter to source files (exclude generated, binary, node_modules)
   - If no files found: exit with "No changed files to review"

3. **Scope Review**
   - Group files by language/framework
   - Determine review depth from argument or default to standard
   - Show file list to user for confirmation

4. **Spawn Code Reviewer Agent**
   - Spawn `backbone-code-reviewer` agent
   - Pass: file list, depth level, project context
   - Agent performs:
     a. Per-file analysis (bugs, security, quality)
     b. Cross-file analysis (imports, dependencies, layer violations)
     c. Architecture compliance check (4-KNOWLEDGE.md constraints)
     d. Security audit (secrets, injection vectors)

5. **Generate REVIEW.md**
   - Agent writes structured review with sections:
     - Summary (blockers/warnings/suggestions counts)
     - Blockers (MUST FIX) — file, line, issue, evidence
     - Warnings (SHOULD FIX) — file, line, issue, rationale
     - Suggestions (CONSIDER) — issue, rationale
     - Architecture Findings — layer violations, boundary issues
     - Security Findings — secrets, injection vectors

6. **Present Results**
   - Display inline summary
   - If blockers found: recommend fixing before proceeding
   - If clean: confirm code is ready for commit
   - Show REVIEW.md location

7. **Follow-up (Optional)**
   - If user wants to address findings:
     - Route to `/backbone:quick` for small fixes
     - Route to `/backbone:debug` for complex issues
</process>

<success_criteria>
- [ ] File discovery works (explicit or git diff)
- [ ] Depth level respected (quick/standard/deep)
- [ ] backbone-code-reviewer agent spawned with proper context
- [ ] REVIEW.md produced with severity classification
- [ ] Blockers clearly distinguished from warnings/suggestions
</success_criteria>
