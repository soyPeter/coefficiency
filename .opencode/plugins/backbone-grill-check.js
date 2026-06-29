#!/usr/bin/env node
// backbone-grill-check — Block PRD creation until grill evidence exists
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-grill-check.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath, content) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath, content } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-grill-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ GRILL GATE")) {
      return { status: "block", message: "Grill evidence required before creating PRD. Load grill-me skill first." };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneGrillCheck: async () => ({
    tool: {
      Write: {
        description: "Backbone Grill Check — blocks PRD creation without grill evidence",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "", args.content || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};