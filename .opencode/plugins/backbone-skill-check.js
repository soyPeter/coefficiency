#!/usr/bin/env node
// backbone-skill-check — Block Write/Edit until required skills are acknowledged
// Hook: tool.execute.before
// Delegates to: scripts/hooks/pre-tool-use-skill-check.sh

const { spawnSync } = require("child_process");

function runHook(toolName, filePath) {
  try {
    const input = JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath } });
    const result = spawnSync("bash", ["scripts/hooks/pre-tool-use-skill-check.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (result.stdout || "").trim();
    if (output.includes("❌ SKILL GATE")) {
      const skill = output.match(/Required skill:\s*(.+)/)?.[1] || "unknown";
      return { status: "block", message: `Skill not acknowledged: ${skill}. Type "acknowledge" to continue.` };
    }
    return { status: "allow" };
  } catch (e) {
    return { status: "allow" };
  }
}

module.exports = {
  BackboneSkillCheck: async () => ({
    tool: {
      Write: {
        description: "Backbone Skill Check — blocks Write until required skills are acknowledged",
        args: { file_path: { type: "string", optional: true }, content: { type: "string", optional: true } },
        async execute(args) {
          const result = runHook("Write", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
      Edit: {
        description: "Backbone Skill Check — blocks Edit until required skills are acknowledged",
        args: { file_path: { type: "string", optional: true }, oldString: { type: "string", optional: true }, newString: { type: "string", optional: true }, replaceAll: { type: "boolean", optional: true } },
        async execute(args) {
          const result = runHook("Edit", args.file_path || "");
          if (result.status === "block") throw new Error(result.message);
        },
      },
    },
  }),
};