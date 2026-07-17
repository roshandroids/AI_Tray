/** SDK-free transport models emitted by the persistent bridge. */

import type { QuotaResult } from "./quota.js";

/** Protocol-safe session usage fields allowlisted from the experimental SDK RPC. */
export interface SessionUsageResult {
  readonly sessionId: string;
  readonly totalPremiumRequestCost: number;
  readonly totalUserRequests: number;
  readonly totalApiDurationMs: number;
  readonly sessionStartTime: string;
  readonly currentModel: string | null;
  readonly lastCallInputTokens: number;
  readonly lastCallOutputTokens: number;
}

/** Secret-free SDK and runtime health projection. */
export interface HealthResult {
  readonly healthy: boolean;
  readonly authenticated: boolean;
  readonly message: string;
  readonly checkedAt: string;
}

/** Compatibility metadata returned during handshake and version queries. */
export interface VersionResult {
  readonly protocolVersion: number;
  readonly bridgeVersion: string;
  readonly sdkVersion: string;
  readonly cliVersion: string | null;
}

/** SDK operations consumed by the NDJSON host without exposing SDK DTOs. */
export interface BridgeSdkClient {
  start(): Promise<void>;
  stop(): Promise<void>;
  getQuota(): Promise<QuotaResult>;
  getSessionUsage(sessionId: string): Promise<SessionUsageResult>;
  getHealth(): Promise<HealthResult>;
  getVersion(): Promise<VersionResult>;
}

/** Constructs one lifecycle-owned SDK client for a bridge process. */
export type BridgeSdkClientFactory = () => BridgeSdkClient;
