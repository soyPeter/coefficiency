#!/usr/bin/env node
// backbone-wip-check — Block Write/Edit when no [WIP] task is marked
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-wip-check.sh

const { spawnSync } = require("child_process");
const path = require("path");

function runHook(toolName, filePath) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-wip-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("BLOCK:") || output.includes("❌ WIP POLICY VIOLATION")) {
      const msg = output.replace(/^.*BLOCK:\s*/s, "").split("\n")[0].trim() || "No [WIP] task marked";
      return { status: "block", message: msg };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneWipCheck: async () => ({
    tool: {
      Write: {
        description: "Backbone WIP Check — blocks Write without active [WIP] task",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
      Edit: {
        description: "Backbone WIP Check — blocks Edit without active [WIP] task",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true }, replaceAll: { type: "boolean", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};