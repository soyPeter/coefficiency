---
name: backbone:cost
description: Log heuristic cost estimate to SESSION.md
allowed-tools:
  - Read
  - Edit
  - Write
required-skills: []
---

<objective>
Log a cost estimate entry to [`backbone/SESSION.md`](backbone/SESSION.md) based on observable
proxies (subagents spawned, files read, skills loaded, tool calls).

**Renamed from:** `cost-track` (now deprecated)

**When to use:**
- After completing a multi-step task with subagents
- Before committing, as part of the Definition of Done
- When you want to build awareness about session burn

**Do NOT use for:**
- Exact billing (this is heuristic, not precise)
- Micromanaging every tool call (log once per significant task)
</objective>

<process>
## Step 1: Gather Proxies

Count from the current session:
- Subagent spawns
- Files read (approximate from session memory)
- Skills loaded/acknowledged
- Tool calls made

## Step 2: Calculate Heuristic Token Estimate

```
base_tokens = 15_000 * subagent_count
file_tokens = 500 * files_read
tool_tokens = 2_000 * tool_calls
input_tokens ≈ base_tokens + file_tokens + tool_tokens
output_tokens ≈ input_tokens * 0.25
```

## Step 3: Estimate Cost (Sonnet 4.6 pricing)

```
input_cost  = (input_tokens / 1_000_000) * $3.00
output_cost = (output_tokens / 1_000_000) * $15.00
total_cost_usd = input_cost + output_cost
```

## Step 4: Append to SESSION.md

```markdown
### Cost Log — [timestamp]
- Task: [brief description]
- Subagents spawned: [N]
- Files read: [N]
- Skills loaded: [list]
- Tool calls: [N]
- **Estimated input tokens: ~[N]k**
- **Estimated output tokens: ~[N]k**
- **Estimated cost: ~$[N.NN]** (Sonnet 4.6)
```

## Step 5: Update Session Running Total

```markdown
## Session Cost Summary
- Tasks logged: [N]
- Total estimated tokens: ~[N]k input / ~[N]k output
- Total estimated cost: ~$[N.NN]
```

## Step 6: Flag if Exceeds $5.00

If session total exceeds $5.00:
> ⚠️ Session estimated cost exceeds $5. Consider reviewing whether all subagent spawns were necessary.
</process>

<success_criteria>
- [ ] Cost entry appended to SESSION.md with all proxy counts
- [ ] Heuristic calculation shown with formula
- [ ] Session running total updated
- [ ] Flag raised if session exceeds $5.00
</success_criteria>