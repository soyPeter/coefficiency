#!/usr/bin/env node
// backbone-qms-check — Advisory QMS check before editing change folders
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-qms-check.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath, content) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath, content } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-qms-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output) {
      return { status: "warn", message: output };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneQmsCheck: async () => ({
    tool: {
      Write: {
        description: "Backbone QMS Check — warns about open NCRs linked to change folder",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "", args.content || "");
          if (result.status === "warn") {
            console.warn(result.message);
          }
        },
      },
      Edit: {
        description: "Backbone QMS Check — warns about open NCRs linked to change folder",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "", args.content || "");
          if (result.status === "warn") {
            console.warn(result.message);
          }
        },
      },
    },
  }),
};
