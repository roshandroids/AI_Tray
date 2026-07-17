/** Sole official SDK import and mapping boundary for the bridge package. */

import { createRequire } from "node:module";

import { CopilotClient } from "@github/copilot-sdk";

import type {
  BridgeSdkClient,
  SessionUsageResult,
} from "./bridge_models.js";
import type { CopilotSdkClient } from "./poc.js";
import { mapQuotaResponse } from "./quota.js";
import {
  BRIDGE_VERSION,
  PROTOCOL_VERSION,
} from "./protocol.js";

export const SDK_VERSION = "1.0.7";
export const CLI_VERSION = "1.0.71";
export const KOFFI_VERSION = "3.1.1";

/** Creates an official SDK client using the currently logged-in Copilot user. */
export function createLoggedInClient(): CopilotSdkClient {
  const client = new CopilotClient({ useLoggedInUser: true });
  return {
    rpc: {
      account: {
        getQuota: async () => client.rpc.account.getQuota({}),
      },
    },
    start: async () => client.start(),
    stop: async () => {
      await client.stop();
    },
  };
}

/** Creates the persistent SDK facade used by the versioned bridge host. */
export function createPersistentClient(): BridgeSdkClient {
  const client = new CopilotClient({ useLoggedInUser: true });
  let cliVersion: string | null = null;

  return {
    start: async () => {
      await client.start();
      const status = await client.getStatus();
      cliVersion = status.version;
      if (cliVersion !== CLI_VERSION) {
        await client.stop();
        throw {
          code: "unsupported_sdk",
          message: "Bundled Copilot CLI version is incompatible",
        };
      }
    },
    stop: async () => {
      const errors = await client.stop();
      if (errors.length > 0) {
        throw new Error("Copilot SDK cleanup failed");
      }
    },
    getQuota: async () => mapQuotaResponse(
      await client.rpc.account.getQuota({}),
    ),
    getSessionUsage: async (sessionId) => {
      const session = await client.resumeSession(sessionId, {
        suppressResumeEvent: true,
        continuePendingWork: false,
      });
      try {
        const usage = (
          session.rpc as unknown as {
            usage?: { getMetrics?: () => Promise<unknown> };
          }
        ).usage;
        if (typeof usage?.getMetrics !== "function") {
          throw {
            code: "rpc_unavailable",
            message: "Experimental usage RPC is unavailable",
          };
        }
        return mapSessionUsage(
          sessionId,
          await usage.getMetrics(),
        );
      } finally {
        await session.disconnect();
      }
    },
    getHealth: async () => {
      const [ping, auth] = await Promise.all([
        client.ping("ai-tray-health"),
        client.getAuthStatus(),
      ]);
      return {
        healthy: typeof ping.timestamp === "string",
        authenticated: auth.isAuthenticated,
        message: auth.isAuthenticated
          ? "Copilot SDK is ready"
          : "Copilot authentication is required",
        checkedAt: new Date().toISOString(),
      };
    },
    getVersion: async () => ({
      protocolVersion: PROTOCOL_VERSION,
      bridgeVersion: BRIDGE_VERSION,
      sdkVersion: SDK_VERSION,
      cliVersion,
    }),
  };
}

/** Validates that the packaged runtime can load its native and CLI assets. */
export async function validateBundledRuntime(): Promise<{
  protocolVersion: number;
  bridgeVersion: string;
  nodeVersion: string;
  sdkVersion: string;
  cliVersion: string;
  koffiVersion: string;
  experimentalUsageAvailable: boolean;
  compatible: boolean;
  healthy: boolean;
  status: string;
}> {
  await import("koffi");
  const require = createRequire(import.meta.url);
  const cliPackage = `@github/copilot-${process.platform}-${process.arch}`;
  require.resolve(cliPackage);
  return {
    protocolVersion: PROTOCOL_VERSION,
    bridgeVersion: BRIDGE_VERSION,
    nodeVersion: process.versions.node,
    sdkVersion: SDK_VERSION,
    cliVersion: CLI_VERSION,
    koffiVersion: KOFFI_VERSION,
    experimentalUsageAvailable:
      typeof CopilotClient.prototype.resumeSession === "function",
    compatible: true,
    healthy: true,
    status: "Bundled Copilot runtime assets loaded",
  };
}

function mapSessionUsage(
  sessionId: string,
  value: unknown,
): SessionUsageResult {
  if (!isRecord(value)) {
    throw new Error("Malformed session usage");
  }
  return {
    sessionId,
    totalPremiumRequestCost: requireNumber(
      value.totalPremiumRequestCost,
    ),
    totalUserRequests: requireNumber(value.totalUserRequests),
    totalApiDurationMs: requireNumber(value.totalApiDurationMs),
    sessionStartTime: requireDate(value.sessionStartTime),
    currentModel:
      value.currentModel === undefined
        ? null
        : requireString(value.currentModel),
    lastCallInputTokens: requireNumber(value.lastCallInputTokens),
    lastCallOutputTokens: requireNumber(value.lastCallOutputTokens),
  };
}

function requireNumber(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new Error("Malformed session usage");
  }
  return value;
}

function requireString(value: unknown): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error("Malformed session usage");
  }
  return value;
}

function requireDate(value: unknown): string {
  const date = requireString(value);
  if (Number.isNaN(Date.parse(date))) {
    throw new Error("Malformed session usage");
  }
  return date;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
