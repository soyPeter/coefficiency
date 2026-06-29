#!/usr/bin/env node
// backbone-worktrunk — Auto-create feature worktrees for OpenCode sessions
// Hook: session.created
// When [WIP] tasks exist and we're not already in a worktree,
// creates one and writes the path to .backbone/session/worktree.
// The agent should read that file on startup and cd into the worktree.

const { spawnSync } = require("child_process");
const path = require("path");
const fs = require("fs");

function isInWorktree(dir) {
  const r = spawnSync("git", ["rev-parse", "--git-dir"], { cwd: dir, encoding: "utf8" });
  return r.status === 0 && r.stdout.trim().includes("worktrees");
}

function findWipTask(dir) {
  const p = path.join(dir, "backbone", "3-TASKS.md");
  if (!fs.existsSync(p)) return null;
  const content = fs.readFileSync(p, "utf8");
  const m = content.match(/-\s*\[WIP\]\s*(.+)/);
  return m ? m[1].trim() : null;
}

function createWorktree(dir, taskName) {
  // Try scripts/worktrunk.sh first
  const r = spawnSync("bash", ["scripts/worktrunk.sh", "create", "--", taskName], {
    cwd: dir, encoding: "utf8", timeout: 30000,
  });
  if (r.status === 0) {
    const out = r.stdout || r.stderr;
    // Extract path — worktrunk prints it somewhere in output
    const repoName = path.basename(dir);
    const branchName = "feat/" + taskName
      .toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").replace(/-+/g, "-");
    const guess = path.join(dir, "..", repoName + "-" + branchName.replace(/\//g, "-"));
    if (fs.existsSync(guess)) return guess;
    return out.trim();
  }

  // Fallback: raw git
  const branchName = "feat/" + taskName
    .toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").replace(/-+/g, "-");
  const repoName = path.basename(dir);
  const worktreePath = path.join(dir, "..", `${repoName}-${branchName.replace(/\//g, "-")}`);

  const base = spawnSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { cwd: dir, encoding: "utf8" });
  const baseBranch = base.status === 0 ? base.stdout.trim() : "dev";

  spawnSync("git", ["branch", branchName, baseBranch], { cwd: dir, encoding: "utf8" });
  spawnSync("git", ["worktree", "add", worktreePath, branchName], { cwd: dir, encoding: "utf8" });

  return worktreePath;
}

module.exports = {
  BackboneWorktrunk: async ({ directory }) => {
    return {
      "session.created": async () => {
        const projectDir = directory || process.cwd();
        if (isInWorktree(projectDir)) return;
        const taskName = findWipTask(projectDir);
        if (!taskName) return;

        const worktreePath = createWorktree(projectDir, taskName);
        if (!worktreePath || worktreePath === "") return;

        const sessionDir = path.join(projectDir, ".backbone", "session");
        fs.mkdirSync(sessionDir, { recursive: true });
        fs.writeFileSync(path.join(sessionDir, "worktree"), worktreePath + "\n");
      },
    };
  },
};
