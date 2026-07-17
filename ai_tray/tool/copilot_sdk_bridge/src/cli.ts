/** Standalone executable for the authenticated Copilot quota POC. */

import { runQuotaPoc } from "./poc.js";
import { PocError } from "./quota.js";
import { createLoggedInClient } from "./sdk_client.js";

const DEFAULT_TIMEOUT_MS = 15_000;

try {
  const quota = await runQuotaPoc(
    createLoggedInClient,
    DEFAULT_TIMEOUT_MS,
  );
  process.stdout.write(`${JSON.stringify({ ok: true, quota })}\n`);
} catch (error) {
  const errorCode =
    error instanceof PocError ? error.code : "initialization_failed";
  process.stderr.write(`${JSON.stringify({ ok: false, errorCode })}\n`);
  process.exitCode = 1;
}
