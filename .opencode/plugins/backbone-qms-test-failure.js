#!/usr/bin/env node
// backbone-qms-test-failure — Detect test/build failures and suggest NCR registration
// Hook: tool.execute.after
// Delegates to: scripts/hooks/post-tool-use-qms-auto-register.sh

const { spawnSync } = require("child_process");

function runHook(result) {
  try {
    const input = JSON.stringify(result);
    const proc = spawnSync("bash", ["scripts/hooks/post-tool-use-qms-auto-register.sh"], {
      cwd: process.cwd(),
      input,
      encoding: "utf8",
    });
    const output = (proc.stdout || "").trim();
    if (output) {
      console.warn(output);
    }
  } catch (e) {
    // Silently fail — advisory only
  }
}

module.exports = {
  BackboneQmsTestFailure: async () => ({
    tool: {
      Bash: {
        description: "Backbone QMS Test Failure — suggests NCR registration on test failures",
        args: { command: { type: "string" } },
        async execute(args, context) {
          // context.result contains the Bash execution result
          if (context && context.result) {
            const resultData = {
              tool_input: { command: args.command || "" },
              result_text: typeof context.result === "string" ? context.result : JSON.stringify(context.result),
            };
            runHook(resultData);
          }
        },
      },
    },
  }),
};
