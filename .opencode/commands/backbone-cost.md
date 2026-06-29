---
description: Log an estimated cost entry to SESSION.md
---

Append a heuristic cost estimate entry to [`backbone/SESSION.md`](backbone/SESSION.md) for the work done in this session.

Use the formula:
- base_tokens = 15,000 × subagent_spawns
- file_tokens = 500 × files_read
- tool_tokens = 2,000 × tool_calls
- input_tokens ≈ base + file + tool
- output_tokens ≈ input × 0.25
- cost_usd = (input/1M × $3) + (output/1M × $15)

Append as a new row and update the session total.
