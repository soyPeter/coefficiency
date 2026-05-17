---
name: backbone:progress
description: Check project progress, show context, and intelligently route to next action.
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

<objective>
Show project progress and intelligently route to the next action.

**When to use:**
- Starting a new session ("What should I do next?")
- After completing a task ("What's next?")
- When lost in context ("Where are we?")
- Before committing ("Did I forget anything?")

**Output:**
- Milestone progress summary
- Active/WIP tasks
- Blockers and warnings
- Recommended next action with rationale
</objective>

<process>
1. **Parse 3-TASKS.md**
   - Read `backbone/3-TASKS.md`
   - Extract milestone table (M1-M7 status)
   - Count completed vs pending tasks
   - Identify WIP tasks (marked [WIP])

2. **Parse STATE.md**
   - Read `backbone/planning/STATE.md` if exists
   - Extract current blockers
   - Check session alerts (context monitor)

3. **Git Status**
   - Run: `git status --short`
   - Check uncommitted changes
   - Check branch name
   - Check if ahead of origin

4. **Recent Activity**
   - Run: `git log --oneline -5`
   - Show last 5 commits for context

5. **Generate Progress Report**
   ```
   📊 Project Progress
   ═══════════════════════════════════════════
   
   Milestones:
     M1 Bootstrap      ✅ 100%
     M2 Dev Portal     ✅ 100%
     M3 Release Mgmt   ✅ 100%
     M4 Observability   ⬜ 0%
     M5 More Templates  ⬜ 0%
     M6 AI Workflows   🔄 90%
     M7 Runtime        🔄 30%
   
   Active Tasks:
     [WIP] Phase B2: Slash commands (6 new commands)
   
   Blockers:
     None
   
   Git Status:
     On branch dev, ahead of origin by 20 commits
     Working tree clean
   
   Recent Commits:
     feat(security): add read-guard, boundary-check...
     docs: update PRD index...
     feat(gsd): make GSD security layer default...
   ```

6. **Recommend Next Action**
   - If WIP task exists: "Continue with [WIP task]"
   - If uncommitted changes: "Commit changes first"
   - If all tasks complete: "All tasks done! Consider /backbone:ship"
   - If on main/dev with feature work: "Create worktree with worktrunk"
   - Otherwise: "Pick a pending task from the list"

7. **Route**
   - Ask user if they want to proceed with recommendation
   - If yes: execute the recommended action
   - If no: list top 3 pending tasks for user to choose
</process>

<success_criteria>
- [ ] Parses 3-TASKS.md accurately
- [ ] Shows milestone progress percentages
- [ ] Identifies WIP tasks and blockers
- [ ] Includes git status and recent commits
- [ ] Provides actionable recommendation
- [ ] Routes to appropriate next action
</success_criteria>
