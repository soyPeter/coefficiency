---
name: backbone:push-clean
description: Export a clean project copy without AI agent scaffolding. Strips backbone/, .claude/, AGENTS.md, templates/, hooks/ and pushes only runtime code to a repo.
argument-hint: "[--remote URL] [--branch NAME] [--dry-run]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<objective>
Export a production-ready copy of the project — strips all AI agent scaffolding
(`backbone/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`, `COMMANDS.md`, `templates/`,
`scripts/hooks/`, etc.) and pushes only the runtime code.

**When to use:**
- You want to push the application code to a production repository
- You need a clean copy without AI agent infrastructure
- You're handing off the project to a team that doesn't use the backbone

**What stays:**
`src/`, `build files`, `Dockerfile`, `docker-compose.yml`, `k8s/`, `argocd/`,
`scripts/` (minus hooks), `tests/`, `docs/`, `frontend/`, `services/`,
`README.md`, `.gitignore`, `.env.example`, `.github/workflows/`

**What gets stripped:**
`backbone/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`, `COMMANDS.md`, `.backbone/`,
`.worktrunk.toml`, `scripts/hooks/`, `templates/`
</objective>

<process>
1. **Parse Arguments**
   - `--remote URL` — git remote to push to (optional)
   - `--branch NAME` — target branch (default: main)
   - `--dry-run` — show what would happen without executing

2. **Confirmation**
   - Show the exclude list and file counts
   - Ask user to confirm before proceeding
   - `--dry-run` skips confirmation

3. **Execute `scripts/push-clean.sh`**
   - Delegates to the bash script for all file operations
   - The script: creates tempdir → rsync with exclusions → secret scan →
     git init → git commit → git bundle → (optional) git push → report
</process>

<critical_rules>
- ALWAYS run `--dry-run` first to verify excludes
- NEVER commit the export to the current project (it goes to a temp dir)
- NEVER include secrets — the script runs `secret-scan.py` on the output
- NEVER modify the source project — export is a read-only operation
- ALWAYS clean up the temp dir after confirming export success
</critical_rules>

<success_criteria>
- [ ] Clean copy created in temp directory
- [ ] Secret scan passed on exported files
- [ ] Fresh git repo initialized on clean copy
- [ ] Git bundle created at `/tmp/<project>-clean.bundle`
- [ ] (Optional) Pushed to remote repository
- [ ] Source project untouched
</success_criteria>
