# Copilot SDK bridge

This package is AI Tray's persistent, versioned boundary around the official
`@github/copilot-sdk` package pinned exactly to `1.0.7`. Only
`src/sdk_client.ts` imports the SDK; Flutter exchanges SDK-free NDJSON with the
bridge.

The Phase 1 one-shot quota POC remains available for authenticated verification.

## Requirements

- Node.js `^20.19.0` or `>=22.12.0`
- A locally logged-in GitHub Copilot CLI user for authenticated checks

## Deterministic verification

```sh
npm ci
npm run check
```

The package-local npm `allowScripts` policy approves only the lockfile-pinned
`koffi@3.1.1` native install step required by the official SDK. It does not
change user or repository-wide npm policy. Every build first loads Koffi's
installed native artifact and the SDK, so a missing packaged dependency fails
before compilation or authentication. Runtime downloads are not used.

The unit suite injects the SDK client and covers startup failure,
authentication failure, timeout, null/malformed responses, additive schema
drift, and shutdown cleanup.

## Authenticated gate

Run the one-shot command twice:

```sh
npm run poc
npm run poc
```

Or run the repeated-call integration test:

```sh
npm run test:integration
```

Output is an allowlisted JSON domain shape containing only quota names,
availability, entitlement, usage, remaining percentage, overage policy, and
reset date. Raw SDK errors, credentials, account identity, and unknown response
fields are never printed. Failure output contains only a stable error code.

## Persistent protocol

Build the bridge, then start its stdio host:

```sh
npm run build
npm start
```

Protocol version 1 uses one JSON object per line. Every request and response
contains `protocolVersion` and a caller-generated `id`. Clients first call
`handshake` with `supportedVersions: [1]`, then may call `quota.get`,
`session.usage` (with `sessionId`), `health.get`, `version.get`, `cancel`, or
`shutdown`. Error responses contain only stable codes, safe messages, and a
retryable flag.

## Release payloads

`distribution/manifest.json` pins Node `22.17.0`, npm `10.9.2`, SDK `1.0.7`,
CLI `1.0.71`, Koffi `3.1.1`, target package names, and official Node archive
SHA-256 values. Assembly must run on the matching architecture so npm selects
the correct official CLI and native Koffi optional dependencies:

```sh
node scripts/assemble_sidecar.mjs --target macos-arm64
node scripts/verify_payload.mjs ../../build/copilot_sdk/macos-arm64
node scripts/smoke_protocol.mjs ../../build/copilot_sdk/macos-arm64
```

Supported targets are `macos-arm64`, `macos-x64`, and `windows-x64`. The x64
macOS commands run under Rosetta in release CI. Assembly downloads only the
checksum-verified, pinned Node archive at build time and uses that archive's
pinned npm for a production-only `npm ci`. It emits a per-file checksum
manifest. The packaged app never invokes npm, npx, or a network downloader.

Payloads are generated under `build/copilot_sdk/` and are not committed.
Xcode copies and signs the matching payload into
`Contents/Resources/copilot_sdk`; Windows CMake copies it beside the release
executable. `verify_payload.mjs` validates every checksum and runs an offline
SDK/CLI/Koffi version and health smoke check using bundled Node.
`smoke_protocol.mjs` is the opt-in authenticated package check for handshake,
version, health, and graceful shutdown.
