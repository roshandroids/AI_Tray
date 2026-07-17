/** Secret-safe quota domain mapping at the official SDK boundary. */

export const QUOTA_KINDS = [
  "premium_interactions",
  "chat",
  "completions",
] as const;

export type QuotaKind = (typeof QUOTA_KINDS)[number];

/** A validated quota metric containing only non-secret account usage fields. */
export interface QuotaMetric {
  readonly kind: QuotaKind;
  readonly available: boolean;
  readonly entitlementRequests: number | null;
  readonly usedRequests: number | null;
  readonly remainingPercentage: number | null;
  readonly overage: number | null;
  readonly overageAllowedWithExhaustedQuota: boolean | null;
  readonly resetDate: string | null;
}

/** Temporary POC domain model, intentionally independent of SDK DTO types. */
export interface QuotaResult {
  readonly premium: QuotaMetric;
  readonly chat: QuotaMetric;
  readonly completion: QuotaMetric;
}

/** Stable, non-sensitive error emitted by the POC boundary. */
export class PocError extends Error {
  constructor(
    readonly code:
      | "initialization_failed"
      | "authentication_failed"
      | "quota_timeout"
      | "malformed_quota"
      | "shutdown_failed",
  ) {
    super(code);
    this.name = "PocError";
  }
}

/**
 * Maps an unknown SDK response to an allowlisted domain shape.
 *
 * Unknown top-level and snapshot fields are ignored so additive SDK schema
 * drift cannot leak data or break the bridge.
 */
export function mapQuotaResponse(response: unknown): QuotaResult {
  if (!isRecord(response) || !isRecord(response.quotaSnapshots)) {
    throw new PocError("malformed_quota");
  }

  const snapshots = response.quotaSnapshots;
  const recognizedCount = QUOTA_KINDS.filter(
    (kind) => snapshots[kind] !== undefined,
  ).length;
  if (recognizedCount === 0) {
    throw new PocError("malformed_quota");
  }

  return {
    premium: mapMetric("premium_interactions", snapshots.premium_interactions),
    chat: mapMetric("chat", snapshots.chat),
    completion: mapMetric("completions", snapshots.completions),
  };
}

function mapMetric(kind: QuotaKind, value: unknown): QuotaMetric {
  if (value === undefined) {
    return unavailableMetric(kind);
  }
  if (!isRecord(value)) {
    throw new PocError("malformed_quota");
  }

  const entitlementRequests = requireNumber(value.entitlementRequests);
  const usedRequests = requireNumber(value.usedRequests);
  const remainingPercentage = requireNumber(value.remainingPercentage);
  const overage = requireNumber(value.overage);
  const overageAllowed = value.overageAllowedWithExhaustedQuota;

  if (
    entitlementRequests < 0 ||
    usedRequests < 0 ||
    remainingPercentage < 0 ||
    remainingPercentage > 100 ||
    overage < 0 ||
    typeof overageAllowed !== "boolean"
  ) {
    throw new PocError("malformed_quota");
  }

  return {
    kind,
    available: true,
    entitlementRequests,
    usedRequests,
    remainingPercentage,
    overage,
    overageAllowedWithExhaustedQuota: overageAllowed,
    resetDate: mapResetDate(value.resetDate),
  };
}

function unavailableMetric(kind: QuotaKind): QuotaMetric {
  return {
    kind,
    available: false,
    entitlementRequests: null,
    usedRequests: null,
    remainingPercentage: null,
    overage: null,
    overageAllowedWithExhaustedQuota: null,
    resetDate: null,
  };
}

function mapResetDate(value: unknown): string | null {
  if (value === undefined || value === null) {
    return null;
  }
  if (typeof value !== "string" || Number.isNaN(Date.parse(value))) {
    throw new PocError("malformed_quota");
  }
  return value;
}

function requireNumber(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new PocError("malformed_quota");
  }
  return value;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
