---
description: Show help — list all available commands with flags
---

Show all available backbone commands with their flags.

```text
DESIGN & PLANNING:
  /backbone:design      Full design pipeline with domain-aware grilling (REQ-GRL-005)
    --plan              Lightweight (skip grill + C4)
    --amend CHNG-XXX    Delta from existing feature
    --skip-grill        Skip grilling step
    --light / --deep    Override current mode
    --framework <fw>    Specify framework
    --epic <M#>         Assign to milestone
    --c4                Generate C4 diagrams
    --type <type>       Override domain classifier (api|layout|backend|config|workflow)
  /backbone:decide      Record important decision
    --adr               Create formal ADR
    --supersedes D5,D8  Mark older decisions superseded
    --impl              Create implementation CHNG folder
  /backbone:map         Generate architecture map
    --reverse           Reverse-engineer existing project
    --reverse --apply   Write drafts to live backbone/ files
    --deep-arch         Subagent for module thickness / layer violations
  /backbone:status      Show project progress and stats
    --stats             Project analytics view
    --progress          Task completion view
    --wide              Wide output format

IMPLEMENTATION:
  /backbone:task        Execute tasks with TDD — single, parallel, wave, interactive, or unattended loop mode
    --quick             Atomic commit, no TDD, no skill loading
    --light / --deep    Override current mode
    --changelog <msg>   Custom commit message
    --parallel          Wave-based parallel subagent execution (REQ-PAR-001)
    --wave N            Execute only wave N of the dependency DAG (REQ-PAR-001.1)
    --interactive       Sequential execution with user checkpoints (REQ-PAR-001.2)

QUALITY & VERIFICATION:
  /backbone:review      Run verification suite
    --depth quick       Fast check (tests + git status)
    --depth standard    Full verification suite
    --depth deep        Verify + code review subagent + architecture audit
    --depth full-audit  Full-spectrum audit (DDD, SOLID, security, tests)
    --no-subagent       Skip subagent spawn — run gates inline
  /backbone:qms         Quality management (register NCR, compact, CAPA)
    --severity <lvl>    minor | major | critical
    --category <type>   code | process | documentation | security
    --change CHNG-XXX   Link to change folder
    --compact           Scan stale decisions/memory
    --compact --dry-run Preview without modifications
  /backbone:compact     Scan stale decisions and memory entries
    --dry-run           Preview only — no changes applied
  /backbone:uat         Conversational UAT — one scenario at a time (REQ-UAT-003)
    --resume            Continue from last unanswered scenario

RELEASE & CLOSE:
  /backbone:close       Close feature, audit REQ-IDs, run verification
    --ship / --release  Version bump + tag + changelog + push
    --no-tag            Skip git tagging
    --skip-review       Skip code review step
  /backbone:push-clean  Export clean copy without AI scaffolding
    --remote URL        Target remote
    --branch NAME       Target branch (default: main)
    --dry-run           Preview what would be pushed

UTILITIES:
  /backbone:sync        Sync skills from generator — no flags
  /backbone:cost        Log cost estimate to SESSION.md — no flags
  /backbone:debug       Systematic debugging with session state
    list                List active debug sessions
    status <slug>       Show session status
    continue <slug>     Resume session
    --diagnose          Auto-diagnose issue from description
  /backbone:simplify    Run 4-agent simplification on current diff — no flags
  /backbone:onboard     Initialize existing project with backbone
    --project-dir /path Project to onboard
    --dry-run           Preview without modifying
  /backbone:help        Show this help — no flags
```

Deprecated commands and their replacements:

| Deprecated | Replacement |
|------------|------------|
| /backbone:health | /backbone:review --depth quick |
| /backbone:verify | /backbone:review --depth standard |
| /backbone:quick | /backbone:task --quick |
| /backbone:progress | /backbone:status --progress |
| /backbone:stats | /backbone:status --stats |
| /backbone:decision | /backbone:decide |
| /backbone:design-feature | /backbone:design |
| /backbone:amend-feature | /backbone:design --amend |
| /backbone:generate-c4 | /backbone:design --c4 |
| /backbone:map-codebase | /backbone:map |
| /backbone:reverse-engineer | /backbone:map --reverse |
| /backbone:close-feature | /backbone:close |
| /backbone:ship | /backbone:close --ship |
| /backbone:register-issue | /backbone:qms |
| /backbone:compact | /backbone:qms --compact |
| /backbone:sync-skills | /backbone:sync |
| /backbone:cost-track | /backbone:cost |
| /backbone:deep-review | /backbone:review --depth full-audit |
| /backbone:code-review | /backbone:review --depth deep |

Full reference: [`backbone/9-AGENT-SKILLS.md`](backbone/9-AGENT-SKILLS.md)
