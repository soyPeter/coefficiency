---
name: backbone:debug
description: Systematic debugging with persistent session state. Creates structured debug sessions in backbone/debug/{slug}.md.
argument-hint: "[issue description] | list | status <slug> | continue <slug> | --diagnose"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

<objective>
Debug issues using scientific method with session persistence across context resets.

**When to use:**
- Application bug or unexpected behavior
- Test failures that need root cause analysis
- Performance issues requiring systematic investigation
- Intermittent failures that need tracking over time

**Subcommands:**
- `list` — Show all active debug sessions
- `status <slug>` — Print summary of a session without spawning agent
- `continue <slug>` — Resume an existing debug session
- `--diagnose` — Find root cause only, don't apply fix

**Session Persistence:**
Each session creates `backbone/debug/{slug}.md` with:
- Frontmatter (status, trigger, created, updated)
- Current Focus (hypothesis, next_action)
- Evidence (timestamped findings)
- Eliminated (disproven hypotheses)
- Resolution (root_cause, fix, verification)
</objective>

<process>
1. **Parse Arguments**
   - If `$ARGUMENTS` starts with "list": SUBCMD=list
   - If `$ARGUMENTS` starts with "status ": SUBCMD=status, SLUG=remainder
   - If `$ARGUMENTS` starts with "continue ": SUBCMD=continue, SLUG=remainder
   - If `$ARGUMENTS` contains `--diagnose`: diagnose_only=true
   - Otherwise: SUBCMD=debug, description=$ARGUMENTS

2. **LIST Subcommand**
   - Run: `ls backbone/debug/*.md 2>/dev/null | grep -v resolved | head -10`
   - For each file, parse frontmatter and Current Focus
   - Display formatted table with slug, status, hypothesis, next_action
   - STOP after displaying

3. **STATUS Subcommand**
   - Check `backbone/debug/{SLUG}.md` exists
   - Parse and print: frontmatter, Current Focus, evidence count, eliminated count
   - STOP after printing

4. **CONTINUE Subcommand**
   - Check `backbone/debug/{SLUG}.md` exists
   - Read Current Focus block
   - Print summary to console
   - Spawn `backbone-debugger` agent with `continue` mode
   - Display compact summary after agent returns

5. **DEBUG Subcommand (New Issue)**
   a. **Gather Symptoms** (AskUserQuestion):
      - Expected behavior?
      - Actual behavior?
      - Error messages?
      - When did this start?
      - How to reproduce?
   
   b. **Generate Slug**
      - Lowercase, replace spaces/non-alphanumeric with hyphens
      - Strip path traversal chars (., /, \, :)
      - Max 30 chars
      - Example: "Login fails on mobile" → "login-fails-on-mobile"
   
   c. **Create Session File**
      - Ensure `backbone/debug/` directory exists
      - Write initial state to `backbone/debug/{slug}.md`
      - status: investigating
      - trigger: verbatim user description
      - symptoms: all gathered values
      - Current Focus: next_action = "gather initial evidence"
   
   d. **Spawn Debugger Agent**
      - Spawn `backbone-debugger` agent with session_params
      - Pass: slug, file_path, symptoms, diagnose_only flag
      - Agent handles scientific method loop in isolated context
   
   e. **Display Results**
      - Show compact summary from agent
      - If DEBUG SESSION COMPLETE: done
      - If ABANDONED: note file location for later continue
</process>

<success_criteria>
- [ ] Subcommands (list/status/continue) handled before agent spawn
- [ ] New sessions create structured debug files
- [ ] Symptoms gathered via AskUserQuestion
- [ ] backbone-debugger agent spawned with proper context
- [ ] Session state persists in backbone/debug/{slug}.md
</success_criteria>
