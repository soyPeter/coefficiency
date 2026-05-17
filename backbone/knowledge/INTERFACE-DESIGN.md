# Interface Design

When exploring alternative interfaces for a chosen deepening candidate, use this parallel sub-agent pattern. Based on "Design It Twice" (Ousterhout) — your first idea is unlikely to be the best.

## Process

### 1. Frame the Problem Space

Before spawning sub-agents, write a user-facing explanation of the problem space:

- Constraints any new interface would need to satisfy
- Dependencies it would rely on
- A rough illustrative code sketch to ground the constraints — not a proposal

Show this to the user, then immediately proceed to Step 2.

### 2. Spawn Sub-agents

Spawn 3+ sub-agents in parallel. Each must produce a **radically different** interface for the deepened module.

Give each agent a different design constraint:

- **Agent 1:** "Minimize the interface — aim for 1–3 entry points max. Maximise leverage per entry point."
- **Agent 2:** "Maximise flexibility — support many use cases and extension."
- **Agent 3:** "Optimise for the most common caller — make the default case trivial."
- **Agent 4 (if applicable):** "Design around ports & adapters for cross-seam dependencies."

Include both LANGUAGE.md vocabulary and CONTEXT.md vocabulary in the brief.

Each sub-agent outputs:
1. Interface (types, methods, params — plus invariants, ordering, error modes)
2. Usage example showing how callers use it
3. What the implementation hides behind the seam
4. Dependency strategy and adapters
5. Trade-offs — where leverage is high, where it's thin

### 3. Present and Compare

Present designs sequentially so the user can absorb each one, then compare by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**.

After comparing, give your own recommendation: which design is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated.
