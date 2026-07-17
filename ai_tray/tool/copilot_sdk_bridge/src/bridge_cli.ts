/** Executable entry point for the persistent AI Tray Copilot SDK sidecar. */

import { runStdioHost } from "./host.js";
import {
  createPersistentClient,
  validateBundledRuntime,
} from "./sdk_client.js";

try {
  if (process.argv[2] === "--package-smoke") {
    process.stdout.write(
      `${JSON.stringify(await validateBundledRuntime())}\n`,
    );
  } else if (process.argv.length > 2) {
    process.stderr.write("Unsupported bridge argument\n");
    process.exitCode = 2;
  } else {
    await runStdioHost(createPersistentClient);
  }
} catch {
  process.stderr.write(
    `${JSON.stringify({
      level: "error",
      code: "bridge_host_failed",
      message: "Copilot SDK bridge stopped unexpectedly",
    })}\n`,
  );
  process.exitCode = 1;
}
