/** Focused protocol and lifecycle tests for the persistent bridge host. */

import assert from "node:assert/strict";
import test from "node:test";

import type { BridgeSdkClient } from "../src/bridge_models.js";
import { PersistentBridgeHost } from "../src/host.js";

const VERSION = {
  protocolVersion: 1,
  bridgeVersion: "1.0.0",
  sdkVersion: "1.0.7",
  cliVersion: "1.0.71",
};

test("negotiates protocol and exposes every versioned method", async () => {
  const output: string[] = [];
  const client = fakeClient();
  const host = new PersistentBridgeHost(() => client, output.push.bind(output));

  await host.handleLine(request("h", "handshake", {
    supportedVersions: [1],
  }));
  await host.handleLine(request("q", "quota.get"));
  await host.handleLine(request("u", "session.usage", {
    sessionId: "session-1",
  }));
  await host.handleLine(request("e", "health.get"));
  await host.handleLine(request("v", "version.get"));
  await host.handleLine(request("s", "shutdown"));

  const responses = output.map(parseResponse);
  assert.equal(responses[0]?.id, "h");
  assert.equal(responses[0]?.result.negotiatedVersion, 1);
  assert.equal(responses[1]?.result.premium.available, true);
  assert.equal(responses[2]?.result.sessionId, "session-1");
  assert.equal(responses[3]?.result.authenticated, true);
  assert.equal(responses[4]?.result.sdkVersion, "1.0.7");
  assert.equal(responses[5]?.result.stopped, true);
  assert.equal(client.startCalls(), 1);
  assert.equal(client.stopCalls(), 1);
});

test("requires handshake and rejects incompatible protocol versions", async () => {
  const output: string[] = [];
  const host = new PersistentBridgeHost(
    () => fakeClient(),
    output.push.bind(output),
  );

  await host.handleLine(request("q", "quota.get"));
  await host.handleLine(request("h", "handshake", {
    supportedVersions: [2],
  }, 2));

  assert.equal(parseResponse(output[0]!).error.code, "handshake_required");
  assert.equal(parseResponse(output[1]!).error.code, "unsupported_protocol");
});

test("redacts SDK failures and reports request timeout", async () => {
  const output: string[] = [];
  const secret = "ghu_NEVER_LOG_THIS";
  const client = fakeClient({
    getQuota: async () => {
      throw new Error(`network failed token=${secret}`);
    },
  });
  const host = new PersistentBridgeHost(
    () => client,
    output.push.bind(output),
    10,
  );

  await host.handleLine(request("h", "handshake", {
    supportedVersions: [1],
  }));
  await host.handleLine(request("q", "quota.get"));

  const serialized = output.join("\n");
  assert.equal(serialized.includes(secret), false);
  assert.equal(parseResponse(output[1]!).error.code, "operation_failed");

  const timeoutOutput: string[] = [];
  const timeoutHost = new PersistentBridgeHost(
    () => fakeClient({
      getQuota: () => new Promise(() => undefined),
    }),
    timeoutOutput.push.bind(timeoutOutput),
    5,
  );
  await timeoutHost.handleLine(request("h", "handshake", {
    supportedVersions: [1],
  }));
  await timeoutHost.handleLine(request("q", "quota.get"));
  assert.equal(
    parseResponse(timeoutOutput[1]!).error.code,
    "request_timeout",
  );
  await timeoutHost.stop();
});

test("reports unsupported SDK and CLI combinations without crashing", async () => {
  const output: string[] = [];
  const host = new PersistentBridgeHost(
    () => fakeClient({
      start: async () => {
        throw { code: "unsupported_sdk" };
      },
    }),
    output.push.bind(output),
  );

  await host.handleLine(request("h", "handshake", {
    supportedVersions: [1],
  }));

  assert.equal(parseResponse(output[0]!).error.code, "unsupported_sdk");
  await host.stop();
});

interface FakeOverrides {
  readonly start?: () => Promise<void>;
  readonly getQuota?: () => Promise<unknown>;
}

function fakeClient(overrides: FakeOverrides = {}): BridgeSdkClient & {
  startCalls(): number;
  stopCalls(): number;
} {
  let starts = 0;
  let stops = 0;
  return {
    start: async () => {
      starts += 1;
      await overrides.start?.();
    },
    stop: async () => {
      stops += 1;
    },
    getQuota: async () =>
      overrides.getQuota?.() ?? {
        premium: { available: true },
        chat: { available: true },
        completion: { available: true },
      },
    getSessionUsage: async (sessionId) => ({
      sessionId,
      totalPremiumRequestCost: 1,
      totalUserRequests: 2,
      totalApiDurationMs: 3,
      sessionStartTime: "2026-07-16T00:00:00Z",
      currentModel: "gpt-test",
      lastCallInputTokens: 4,
      lastCallOutputTokens: 5,
    }),
    getHealth: async () => ({
      healthy: true,
      authenticated: true,
      message: "ready",
      checkedAt: "2026-07-16T00:00:00Z",
    }),
    getVersion: async () => VERSION,
    startCalls: () => starts,
    stopCalls: () => stops,
  } as BridgeSdkClient & {
    startCalls(): number;
    stopCalls(): number;
  };
}

function request(
  id: string,
  method: string,
  params: Readonly<Record<string, unknown>> = {},
  protocolVersion = 1,
): string {
  return JSON.stringify({ protocolVersion, id, method, params });
}

function parseResponse(line: string): any {
  return JSON.parse(line);
}
