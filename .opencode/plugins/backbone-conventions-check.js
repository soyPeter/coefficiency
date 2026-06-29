#!/usr/bin/env node
// backbone-conventions-check — Gate C→W: Block code writes until conventions are read
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-conventions-check.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-conventions-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ CONVENTIONS GATE")) {
      return { status: "block", message: "Read framework conventions before writing code. See backbone/reference/conventions/<framework>.md" };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneConventionsCheck: async () => ({
    tool: {
      Write: {
        description: "Backbone Conventions Check — blocks Write until framework conventions are read",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
      Edit: {
        description: "Backbone Conventions Check — blocks Edit until framework conventions are read",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true }, replaceAll: { type: "boolean", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};