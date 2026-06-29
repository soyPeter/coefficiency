#!/usr/bin/env node
// backbone-subagent-conflict — Block Task spawns with conflicting file declarations
// Hook: tool.execute.before (Task tool)
// Delegates to: scripts/hooks/pre-tool-use-subagent-conflict-check.sh

const { spawnSync } = require("child_process");

function runHook(prompt, description, subagentType) {
  try {
    const input = JSON.stringify({ tool_name: "Task", tool_input: { prompt, description, subagent_type: subagentType } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-subagent-conflict-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ SUBAGENT CONFLICT")) {
      return { status: "block", message: "Subagent file conflict. Run sequentially instead of parallel." };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneSubagentConflict: async () => ({
    tool: {
      Task: {
        description: "Backbone Subagent Conflict — blocks Task spawn when file targets conflict with running subagent",
        args: { command: { type: "string", optional: true }, description: { type: "string", optional: true }, prompt: { type: "string" }, subagent_type: { type: "string", optional: true }, task_id: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook(args.prompt || "", args.description || "", args.subagent_type || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};