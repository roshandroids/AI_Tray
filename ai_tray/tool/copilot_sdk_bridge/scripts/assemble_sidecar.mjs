#!/usr/bin/env node

/**
 * Reproducibly assembles one architecture-specific Copilot sidecar payload.
 *
 * Network access is confined to this build-time command. The resulting payload
 * contains Node, production npm dependencies, the official CLI, and Koffi.
 */

import { createHash } from "node:crypto";
import {
  chmod,
  cp,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, dirname, join, relative, resolve } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const manifestPath = join(packageRoot, "distribution", "manifest.json");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
const args = parseArgs(process.argv.slice(2));
const targetName = args.target;
const target = manifest.targets[targetName];

if (target === undefined) {
  fail(`Unsupported target "${targetName ?? ""}". Expected: ${Object.keys(manifest.targets).join(", ")}`);
}
if (process.platform !== target.platform || process.arch !== target.arch) {
  fail(
    `Target ${targetName} must be assembled by ${target.platform}/${target.arch}; ` +
      `current process is ${process.platform}/${process.arch}`,
  );
}

const distSource = join(packageRoot, "dist", "src");
await requirePath(join(distSource, "bridge_cli.js"), "Run npm run build before assembly");

const outputRoot = resolve(
  args.output ?? join(packageRoot, "..", "..", "build", "copilot_sdk", targetName),
);
const outputParent = dirname(outputRoot);
await mkdir(outputParent, { recursive: true });
// Keep staging on the destination volume so the final atomic rename also works
// on Windows runners whose system temp and workspace use different drives.
const workRoot = await mkdtemp(
  join(outputParent, `.ai-tray-sidecar-${targetName}-`),
);

try {
  const archivePath = args.archive === undefined
    ? join(workRoot, target.nodeArchive)
    : resolve(args.archive);
  if (args.archive === undefined) {
    await download(
      `https://nodejs.org/dist/v${manifest.nodeVersion}/${target.nodeArchive}`,
      archivePath,
    );
  }
  await verifySha256(archivePath, target.nodeSha256);

  const extractRoot = join(workRoot, "node-extract");
  await mkdir(extractRoot);
  // The Windows Node distribution ships as .zip, not .tar.gz, and GNU tar
  // (which Windows runners can have ahead of bsdtar on PATH) can't read zip
  // at all. Use PowerShell's Expand-Archive there instead of tar.
  if (target.platform === "win32") {
    await run("powershell", [
      "-NoProfile",
      "-NonInteractive",
      "-Command",
      `Expand-Archive -LiteralPath '${archivePath}' -DestinationPath '${extractRoot}' -Force`,
    ]);
  } else {
    await run("tar", ["-xf", archivePath, "-C", extractRoot]);
  }
  const extractedEntries = await readdir(extractRoot);
  if (extractedEntries.length !== 1) {
    fail(`Node archive must contain one root directory, found ${extractedEntries.length}`);
  }
  const extractedNodeRoot = join(extractRoot, extractedEntries[0]);
  const nodeExecutable = target.platform === "win32"
    ? join(extractedNodeRoot, "node.exe")
    : join(extractedNodeRoot, "bin", "node");
  const npmCli = npmCliPath(extractedNodeRoot, target.platform);
  await requirePath(nodeExecutable, "Pinned Node executable is missing");
  await requirePath(npmCli, "Pinned npm CLI is missing");
  await assertCommandOutput(nodeExecutable, ["--version"], `v${manifest.nodeVersion}`);
  await assertCommandOutput(nodeExecutable, [npmCli, "--version"], manifest.npmVersion);

  const stagingRoot = join(workRoot, "payload");
  const bridgeRoot = join(stagingRoot, "bridge");
  await mkdir(bridgeRoot, { recursive: true });
  await cp(extractedNodeRoot, join(stagingRoot, "node"), {
    recursive: true,
    preserveTimestamps: false,
    verbatimSymlinks: true,
  });
  await cp(distSource, join(bridgeRoot, "dist", "src"), {
    recursive: true,
    preserveTimestamps: false,
  });
  await cp(join(packageRoot, "package.json"), join(bridgeRoot, "package.json"));
  await cp(join(packageRoot, "package-lock.json"), join(bridgeRoot, "package-lock.json"));

  const stagedNode = target.platform === "win32"
    ? join(stagingRoot, "node", "node.exe")
    : join(stagingRoot, "node", "bin", "node");
  const stagedNpmCli = npmCliPath(join(stagingRoot, "node"), target.platform);
  await run(stagedNode, [
    stagedNpmCli,
    "ci",
    "--omit=dev",
    "--no-audit",
    "--no-fund",
  ], bridgeRoot);

  await validateProductionDependencies(bridgeRoot, target);
  await chmod(stagedNode, 0o755);
  const cliExecutable = join(
    bridgeRoot,
    "node_modules",
    ...target.cliPackage.split("/"),
    target.platform === "win32" ? "copilot.exe" : "copilot",
  );
  await chmod(cliExecutable, 0o755);

  const files = await collectChecksums(stagingRoot);
  await writeFile(
    join(stagingRoot, "payload-manifest.json"),
    `${JSON.stringify({
      schemaVersion: manifest.schemaVersion,
      target: targetName,
      protocolVersion: manifest.protocolVersion,
      bridgeVersion: manifest.bridgeVersion,
      nodeVersion: manifest.nodeVersion,
      npmVersion: manifest.npmVersion,
      sdkVersion: manifest.sdkVersion,
      cliVersion: manifest.cliVersion,
      koffiVersion: manifest.koffiVersion,
      files,
    }, null, 2)}\n`,
  );

  await rm(outputRoot, { recursive: true, force: true });
  // Windows can transiently EPERM this rename right after writing/chmod'ing
  // the CLI executable (Defender's real-time scan briefly locks it). Retry
  // rather than fail the build on that lock window.
  await renameWithRetry(stagingRoot, outputRoot);
  process.stdout.write(`Assembled ${targetName} sidecar at ${outputRoot}\n`);
} finally {
  await rm(workRoot, { recursive: true, force: true });
}

function parseArgs(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 1) {
    const key = values[index];
    const value = values[index + 1];
    if (!["--target", "--output", "--archive"].includes(key) || value === undefined) {
      fail("Usage: assemble_sidecar.mjs --target <target> [--output <path>] [--archive <path>]");
    }
    parsed[key.slice(2)] = value;
    index += 1;
  }
  if (parsed.target === undefined) {
    fail("--target is required");
  }
  return parsed;
}

function npmCliPath(nodeRoot, platform) {
  return platform === "win32"
    ? join(nodeRoot, "node_modules", "npm", "bin", "npm-cli.js")
    : join(nodeRoot, "lib", "node_modules", "npm", "bin", "npm-cli.js");
}

async function renameWithRetry(source, destination, attempts = 5, delayMs = 500) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      await rename(source, destination);
      return;
    } catch (error) {
      const transient = error?.code === "EPERM" || error?.code === "EBUSY";
      if (!transient || attempt === attempts) {
        throw error;
      }
      await new Promise((resolvePromise) => setTimeout(resolvePromise, delayMs));
    }
  }
}

async function download(url, destination) {
  process.stdout.write(`Downloading pinned Node runtime ${basename(destination)}\n`);
  const response = await fetch(url, { redirect: "follow" });
  if (!response.ok || response.body === null) {
    fail(`Node download failed with HTTP ${response.status}`);
  }
  const bytes = new Uint8Array(await response.arrayBuffer());
  await writeFile(destination, bytes);
}

async function verifySha256(path, expected) {
  const actual = createHash("sha256").update(await readFile(path)).digest("hex");
  if (actual !== expected) {
    fail(`SHA-256 mismatch for ${basename(path)}: expected ${expected}, got ${actual}`);
  }
}

async function validateProductionDependencies(bridgeRoot, target) {
  const readVersion = async (packageName) => {
    const value = JSON.parse(
      await readFile(
        join(bridgeRoot, "node_modules", ...packageName.split("/"), "package.json"),
        "utf8",
      ),
    );
    return value.version;
  };
  const versions = [
    ["@github/copilot-sdk", manifest.sdkVersion],
    ["@github/copilot", manifest.cliVersion],
    [target.cliPackage, manifest.cliVersion],
    ["koffi", manifest.koffiVersion],
    [target.koffiPackage, manifest.koffiVersion],
  ];
  for (const [packageName, expected] of versions) {
    const actual = await readVersion(packageName);
    if (actual !== expected) {
      fail(`${packageName} version mismatch: expected ${expected}, got ${actual}`);
    }
  }
  const nativeAsset = join(
    bridgeRoot,
    "node_modules",
    ...target.koffiPackage.split("/"),
    target.platform === "win32" ? "win32_x64" : `${target.platform}_${target.arch}`,
    "koffi.node",
  );
  await requirePath(nativeAsset, `Native Koffi asset is missing for ${target.platform}/${target.arch}`);
  const devDependency = join(bridgeRoot, "node_modules", "typescript");
  try {
    await stat(devDependency);
    fail("Production payload unexpectedly contains TypeScript");
  } catch (error) {
    if (error?.code !== "ENOENT") {
      throw error;
    }
  }
}

async function collectChecksums(root) {
  const entries = [];
  const walk = async (directory) => {
    const names = (await readdir(directory)).sort();
    for (const name of names) {
      const path = join(directory, name);
      const info = await stat(path);
      if (info.isDirectory()) {
        await walk(path);
      } else if (info.isFile()) {
        entries.push({
          path: relative(root, path).split("\\").join("/"),
          sha256: createHash("sha256").update(await readFile(path)).digest("hex"),
          size: info.size,
        });
      }
    }
  };
  await walk(root);
  return entries;
}

async function assertCommandOutput(executable, commandArgs, expected) {
  const output = await run(executable, commandArgs, undefined, true);
  if (output.trim() !== expected) {
    fail(`${basename(executable)} reported ${output.trim()}, expected ${expected}`);
  }
}

async function requirePath(path, message) {
  try {
    await stat(path);
  } catch {
    fail(`${message}: ${path}`);
  }
}

function run(executable, commandArgs, cwd, capture = false) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(executable, commandArgs, {
      cwd,
      stdio: capture ? ["ignore", "pipe", "inherit"] : "inherit",
      windowsHide: true,
    });
    let output = "";
    child.stdout?.on("data", (chunk) => {
      output += chunk.toString();
    });
    child.once("error", reject);
    child.once("exit", (code) => {
      if (code === 0) {
        resolvePromise(output);
      } else {
        reject(new Error(`${executable} exited with code ${code ?? "unknown"}`));
      }
    });
  });
}

function fail(message) {
  throw new Error(message);
}
