#!/usr/bin/env node
// backbone-rd-gate — Block design docs if PRD lacks grill evidence
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-rd-gate.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath, content) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath, content } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-rd-gate.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ RD GATE")) {
      return { status: "block", message: "Design doc requires grill-validated PRD. Complete grill process first." };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneRdGate: async () => ({
    tool: {
      Write: {
        description: "Backbone RD Gate — blocks design doc creation without grill-validated PRD",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "", args.content || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
      Edit: {
        description: "Backbone RD Gate — blocks design doc edits without grill-validated PRD",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "", args.newString || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};