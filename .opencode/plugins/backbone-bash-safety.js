#!/usr/bin/env node
// backbone-bash-safety — Block dangerous bash commands
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-bash-safety-check.sh

const { spawnSync } = require("child_process");

function runHook(command) {
  try {
    const input = JSON.stringify({ tool_input: { command } });
    const result = spawnSync("bash", ["scripts/hooks/pre-bash-safety-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("🚫 BLOCKED")) {
      const reason = output.match(/Risk\s*:\s*(.+)/)?.[1] || "dangerous command";
      return { status: "block", message: `Bash safety: ${reason}` };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneBashSafety: async () => ({
    tool: {
      Bash: {
        description: "Backbone Bash Safety — blocks destructive git commands and dangerous operations",
        args: { command: { type: "string" }, description: { type: "string", optional: true }, timeout: { type: "number", optional: true }, workdir: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook(args.command || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};