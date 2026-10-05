# ADR-008: Local ollama decision provider in shadow mode for commit messages

## Status
Accepted

## Date
2026-10-05

## Context
The harness can ask an advisory decision provider whether a commit message describes its staged diff, whether the diff hides an unmentioned significant change, and whether it adds debugging leftovers (`scripts/harness/decisions.json`, decision `commit-message`). A provider receives staged diffs, which here can include salary and consultant logic, so where that data goes is a design decision. This machine runs Ollama with `nimble`, a local model exposing a Jev-style decision endpoint (`/v1/systemone`).

## Decision
- Use the **ollama** decision provider (model `nimble`, endpoint `http://localhost:11434/v1/systemone`) in **shadow** mode: every commit is judged and logged in `.git/harness/decisions.jsonl`, and nothing is shown or blocked.
- After a trial period, compare the logged answers with our own judgement (`python3 scripts/harness/lib/harness.py decisions`). Then decide whether to switch to `advise` and tune the thresholds in `decisions.json`.
- Accepted on the user's instruction of 2026-10-05 ("go for ... the rest": run the commit-message decision in shadow mode with the local model during the harness trial).

## Alternatives considered
- `claude` provider (Claude API): stronger judgement, but every commit sends the diff to an external API and costs money; not needed for a shadow trial.
- No decision layer: misses message/diff drift, which the old backbone also could not detect.

## Consequences
- Data stays on this machine; there is no per-call cost.
- Commits take a few seconds longer (about 8 s on a cold model, less when warm). A provider that is down is logged and ignored.
- Machines without Ollama and `nimble` simply log the failure. The layer never blocks a commit.
