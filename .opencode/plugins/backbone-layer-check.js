#!/usr/bin/env node
// backbone-layer-check — Post-edit layer boundary violation detection
// Hook: tool.execute.after
// Delegates to: scripts/hooks/post-edit-layer-check.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath } });
    const result = spawnSync("bash", ["scripts/hooks/post-edit-layer-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("⚠️  LAYER BOUNDARY VIOLATION")) {
      return { status: "violation", message: "Layer boundary violation detected. Domain must not import from app/infra." };
    }
    return { status: "ok" };
  } catch (e) {
    return { status: "ok" };
  }
}

module.exports = {
  BackboneLayerCheck: async () => ({
    tool: {
      Edit: {
        description: "Backbone Layer Check — detects layer boundary violations in Java files",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true }, replaceAll: { type: "boolean", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "");
          if (result.status === "violation") console.warn("⚠️  " + result.message);
        },
      },
      Write: {
        description: "Backbone Layer Check — detects layer boundary violations in Java files",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "");
          if (result.status === "violation") console.warn("⚠️  " + result.message);
        },
      },
    },
  }),
};