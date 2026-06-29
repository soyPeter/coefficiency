#!/usr/bin/env node
// backbone-task-granularity — Block [WIP] tasks that fail size/syntax rules
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-task-granularity-check.sh

const { spawnSync } = require("child_process");

function runHook(oldStr, newStr) {
  try {
    if (!newStr.includes("[WIP]")) return { status: "allow" };
    const input = JSON.stringify({ tool_input: { oldString: oldStr, newString: newStr } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-task-granularity-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ TASK GRANULARITY")) {
      return { status: "block", message: "Task size/format violation. Size tag [XS/S/M/L] required. See 3-TASKS.md syntax rules." };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneTaskGranularity: async () => ({
    tool: {
      Edit: {
        description: "Backbone Task Granularity — validates [WIP] task syntax before editing 3-TASKS.md",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true }, replaceAll: { type: "boolean", optional: true } },
        async execute(args) {
          if (args.file_path && args.file_path.includes("3-TASKS.md")) {
            const result = runHook(args.oldString || "", args.newString || "");
            if (result.status === "block") throw new Error(result.message);
          }
        },
      },
      Write: {
        description: "Backbone Task Granularity — validates task syntax",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          if (args.file_path && args.file_path.includes("3-TASKS.md")) {
            const result = runHook("", args.content || "");
            if (result.status === "block") throw new Error(result.message);
          }
        },
      },
    },
  }),
};