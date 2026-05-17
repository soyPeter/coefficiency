---
name: backbone:cost-track
description: Log a cost estimate for the current session or task. Call this at the end of significant work to record token proxies and estimated spend.
allowed-tools:
  - Read
  - Edit
  - Write
---

<objective>
Log a cost estimate entry to `backbone/SESSION.md` based on observable proxies (subagents spawned, files read, tool calls, skills loaded).

**When to use:**
- After completing a multi-step task with subagents
- Before committing, as part of the Definition of Done
- When you want to build a habit of awareness about session burn

**Do NOT use for:**
- Exact billing (this is heuristic, not precise)
- Micromanaging every tool call (log once per significant task)
</objective>

<process>
1. **Gather proxies from the current session:**
   - Count how many `Task` (subagent) spawns occurred
   - Count total files read (approximate from session memory)
   - Count skills loaded/acknowledged
   - Estimate conversation turns (tool calls made)

2. **Calculate heuristic token estimate:**
   ```
   base_tokens = 15_000 * subagent_count    # AGENTS.md + 4-KNOWLEDGE.md + skills per spawn
   file_tokens = 500 * files_read           # ~500 tokens per file read
   tool_tokens = 2_000 * tool_calls         # conversation history accumulation
   input_tokens ≈ base_tokens + file_tokens + tool_tokens
   output_tokens ≈ input_tokens * 0.25      # output is typically 20-30% of input
   ```

3. **Estimate cost (Sonnet 4.6 pricing):**
   ```
   input_cost  = (input_tokens / 1_000_000) * $3.00
   output_cost = (output_tokens / 1_000_000) * $15.00
   total_cost_usd = input_cost + output_cost
   ```

4. **Read `backbone/SESSION.md`** and append an entry:
   ```markdown
   ### Cost Log — [timestamp]
   - Task: [brief description, e.g., "Phase 58: Integrate Piotr Minkowski articles"]
   - Subagents spawned: [N]
   - Files read: [N]
   - Skills loaded: [list]
   - Tool calls: [N]
   - **Estimated input tokens: ~[N]k**
   - **Estimated output tokens: ~[N]k**
   - **Estimated cost: ~$[N.NN]** (Sonnet 4.6)
   ```

5. **Update the session running total** in SESSION.md:
   ```markdown
   ## Session Cost Summary
   - Tasks logged: [N]
   - Total estimated tokens: ~[N]k input / ~[N]k output
   - Total estimated cost: ~$[N.NN]
   ```

6. **If the session total exceeds $5.00**, flag it:
   > ⚠️ Session estimated cost exceeds $5. Consider reviewing whether all subagent spawns were necessary.
</process>

<success_criteria>
- [ ] Cost entry appended to SESSION.md with all proxy counts
- [ ] Heuristic calculation shown with formula
- [ ] Session running total updated
- [ ] Flag raised if session exceeds $5.00
</success_criteria>
