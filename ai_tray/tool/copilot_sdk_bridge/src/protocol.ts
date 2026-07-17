/** Versioned, app-owned NDJSON protocol shared by bridge host operations. */

export const PROTOCOL_VERSION = 1;
export const BRIDGE_VERSION = "1.0.0";

/** Stable method names accepted by protocol version 1. */
export type BridgeMethod =
  | "handshake"
  | "quota.get"
  | "session.usage"
  | "health.get"
  | "version.get"
  | "cancel"
  | "shutdown";

/** Parsed request with an ID used to correlate exactly one response. */
export interface BridgeRequest {
  readonly protocolVersion: number;
  readonly id: string;
  readonly method: BridgeMethod;
  readonly params: Readonly<Record<string, unknown>>;
}

/** Stable error payload that never includes raw SDK or process output. */
export interface BridgeErrorPayload {
  readonly code: string;
  readonly message: string;
  readonly retryable: boolean;
}

/** Protocol-level failure carrying only allowlisted, secret-safe fields. */
export class BridgeProtocolError extends Error {
  constructor(
    readonly code: string,
    readonly safeMessage: string,
    readonly retryable = false,
  ) {
    super(safeMessage);
    this.name = "BridgeProtocolError";
  }
}

/** Parses and validates one NDJSON request without retaining unknown fields. */
export function parseRequest(line: string): BridgeRequest {
  let value: unknown;
  try {
    value = JSON.parse(line);
  } catch {
    throw new BridgeProtocolError(
      "invalid_json",
      "Request must be valid JSON",
    );
  }
  if (!isRecord(value)) {
    throw new BridgeProtocolError(
      "invalid_request",
      "Request must be a JSON object",
    );
  }
  if (typeof value.id !== "string" || value.id.length === 0) {
    throw new BridgeProtocolError(
      "invalid_request",
      "Request id must be a non-empty string",
    );
  }
  if (
    typeof value.protocolVersion !== "number" ||
    !Number.isSafeInteger(value.protocolVersion)
  ) {
    throw new BridgeProtocolError(
      "invalid_request",
      "protocolVersion must be an integer",
    );
  }
  if (!isMethod(value.method)) {
    throw new BridgeProtocolError(
      "method_not_found",
      "Requested method is not supported",
    );
  }
  if (value.params !== undefined && !isRecord(value.params)) {
    throw new BridgeProtocolError(
      "invalid_params",
      "Request params must be an object",
    );
  }
  return {
    protocolVersion: value.protocolVersion,
    id: value.id,
    method: value.method,
    params: value.params ?? {},
  };
}

/** Serializes a successful response as exactly one NDJSON record. */
export function successResponse(id: string, result: unknown): string {
  return JSON.stringify({
    protocolVersion: PROTOCOL_VERSION,
    id,
    result,
  });
}

/** Serializes a stable failure response as exactly one NDJSON record. */
export function errorResponse(
  id: string | null,
  error: BridgeErrorPayload,
): string {
  return JSON.stringify({
    protocolVersion: PROTOCOL_VERSION,
    id,
    error,
  });
}

function isMethod(value: unknown): value is BridgeMethod {
  return (
    value === "handshake" ||
    value === "quota.get" ||
    value === "session.usage" ||
    value === "health.get" ||
    value === "version.get" ||
    value === "cancel" ||
    value === "shutdown"
  );
}

/** Returns true when a value is a non-null, non-array JSON object. */
export function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
