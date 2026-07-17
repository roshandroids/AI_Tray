#!/usr/bin/env node

/** Verifies an assembled payload without contacting npm or Node downloads. */

import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { basename, join, resolve } from "node:path";
import { spawn } from "node:child_process";

const payloadRoot = resolve(process.argv[2] ?? "");
if (process.argv.length !== 3) {
  throw new Error("Usage: verify_payload.mjs <payload-directory>");
}

const payloadManifest = JSON.parse(
  await readFile(join(payloadRoot, "payload-manifest.json"), "utf8"),
);
for (const entry of payloadManifest.files) {
  const path = join(payloadRoot, ...entry.path.split("/"));
  const info = await stat(path);
  if (info.size !== entry.size) {
    throw new Error(`Size mismatch for ${entry.path}`);
  }
  const checksum = createHash("sha256").update(await readFile(path)).digest("hex");
  if (checksum !== entry.sha256) {
    throw new Error(`SHA-256 mismatch for ${entry.path}`);
  }
}

const isWindows = payloadManifest.target === "windows-x64";
const nodeExecutable = isWindows
  ? join(payloadRoot, "node", "node.exe")
  : join(payloadRoot, "node", "bin", "node");
const bridgeEntry = join(payloadRoot, "bridge", "dist", "src", "bridge_cli.js");
const output = await run(nodeExecutable, [bridgeEntry, "--package-smoke"], join(payloadRoot, "bridge"));
const result = JSON.parse(output);

for (const [key, expected] of Object.entries({
  protocolVersion: payloadManifest.protocolVersion,
  bridgeVersion: payloadManifest.bridgeVersion,
  nodeVersion: payloadManifest.nodeVersion,
  sdkVersion: payloadManifest.sdkVersion,
  cliVersion: payloadManifest.cliVersion,
  koffiVersion: payloadManifest.koffiVersion,
})) {
  if (result[key] !== expected) {
    throw new Error(`${key} mismatch: expected ${expected}, got ${result[key]}`);
  }
}
if (result.healthy !== true || result.compatible !== true) {
  throw new Error(`Packaged sidecar is not healthy: ${result.status ?? "unknown"}`);
}

process.stdout.write(
  `Verified ${payloadManifest.target} payload (${payloadManifest.files.length} checksums)\n`,
);

function run(executable, args, cwd) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(executable, args, {
      cwd,
      stdio: ["ignore", "pipe", "inherit"],
      windowsHide: true,
    });
    let output = "";
    child.stdout.on("data", (chunk) => {
      output += chunk.toString();
    });
    child.once("error", reject);
    child.once("exit", (code) => {
      if (code === 0) {
        resolvePromise(output.trim());
      } else {
        reject(new Error(`${basename(executable)} exited with code ${code ?? "unknown"}`));
      }
    });
  });
}
