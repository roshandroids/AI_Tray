#!/usr/bin/env node

/** Exercises handshake, version, health, and shutdown in an assembled payload. */

import { createInterface } from "node:readline";
import { join, resolve } from "node:path";
import { spawn } from "node:child_process";

if (process.argv.length !== 3) {
  throw new Error("Usage: smoke_protocol.mjs <payload-directory>");
}

const payloadRoot = resolve(process.argv[2]);
const isWindows = process.platform === "win32";
const executable = isWindows
  ? join(payloadRoot, "node", "node.exe")
  : join(payloadRoot, "node", "bin", "node");
const entrypoint = join(
  payloadRoot,
  "bridge",
  "dist",
  "src",
  "bridge_cli.js",
);
const child = spawn(executable, [entrypoint], {
  cwd: join(payloadRoot, "bridge"),
  stdio: ["pipe", "pipe", "pipe"],
  windowsHide: true,
});
const lines = createInterface({ input: child.stdout, crlfDelay: Infinity });
const iterator = lines[Symbol.asyncIterator]();

try {
  const handshake = await request("handshake", {
    supportedVersions: [1],
  });
  if (handshake.negotiatedVersion !== 1) {
    throw new Error("Bridge negotiated an unsupported protocol");
  }
  const version = await request("version.get");
  const health = await request("health.get");
  await request("shutdown");
  process.stdout.write(
    `${JSON.stringify({
      protocolVersion: version.protocolVersion,
      bridgeVersion: version.bridgeVersion,
      sdkVersion: version.sdkVersion,
      cliVersion: version.cliVersion,
      healthy: health.healthy,
      authenticated: health.authenticated,
      status: health.message,
    })}\n`,
  );
} finally {
  lines.close();
  child.stdin.end();
  child.kill();
}

async function request(method, params = {}) {
  const id = `smoke-${method}`;
  child.stdin.write(`${JSON.stringify({
    protocolVersion: 1,
    id,
    method,
    params,
  })}\n`);
  const response = await withTimeout(iterator.next(), 20_000);
  if (response.done || response.value === undefined) {
    throw new Error(`Bridge exited before ${method} responded`);
  }
  const value = JSON.parse(response.value);
  if (value.id !== id) {
    throw new Error(`Unexpected response id for ${method}`);
  }
  if (value.error !== undefined) {
    throw new Error(`${value.error.code}: ${value.error.message}`);
  }
  return value.result;
}

function withTimeout(operation, timeoutMs) {
  return new Promise((resolvePromise, reject) => {
    const timer = setTimeout(
      () => reject(new Error("Packaged bridge smoke test timed out")),
      timeoutMs,
    );
    operation.then(
      (value) => {
        clearTimeout(timer);
        resolvePromise(value);
      },
      (error) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
}
