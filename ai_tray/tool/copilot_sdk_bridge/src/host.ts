/** Persistent lifecycle owner and NDJSON request dispatcher for the bridge. */

import { createInterface } from "node:readline";
import type { Readable, Writable } from "node:stream";

import type {
  BridgeSdkClient,
  BridgeSdkClientFactory,
} from "./bridge_models.js";
import {
  BridgeProtocolError,
  PROTOCOL_VERSION,
  errorResponse,
  isRecord,
  parseRequest,
  successResponse,
  type BridgeRequest,
} from "./protocol.js";

const REQUEST_TIMEOUT_MS = 15_000;
const SHUTDOWN_TIMEOUT_MS = 5_000;

interface ActiveRequest {
  cancelled: boolean;
}

/** Hosts one SDK client and correlates concurrent protocol requests by ID. */
export class PersistentBridgeHost {
  readonly #activeRequests = new Map<string, ActiveRequest>();
  readonly #createClient: BridgeSdkClientFactory;
  readonly #writeLine: (line: string) => void;
  readonly #requestTimeoutMs: number;
  #client: BridgeSdkClient | undefined;
  #closeInput: (() => void) | undefined;
  #handshakeComplete = false;
  #stopping = false;

  constructor(
    createClient: BridgeSdkClientFactory,
    writeLine: (line: string) => void,
    requestTimeoutMs = REQUEST_TIMEOUT_MS,
  ) {
    if (!Number.isSafeInteger(requestTimeoutMs) || requestTimeoutMs <= 0) {
      throw new RangeError("requestTimeoutMs must be a positive integer");
    }
    this.#createClient = createClient;
    this.#writeLine = writeLine;
    this.#requestTimeoutMs = requestTimeoutMs;
  }

  /** Reads requests until EOF or shutdown, then always releases the SDK client. */
  async run(input: Readable): Promise<void> {
    const lines = createInterface({ input, crlfDelay: Infinity });
    this.#closeInput = () => lines.close();
    try {
      for await (const line of lines) {
        if (this.#stopping) {
          break;
        }
        void this.handleLine(line);
      }
    } finally {
      this.#closeInput = undefined;
      await this.stop();
    }
  }

  /** Validates and dispatches one line while preserving request correlation. */
  async handleLine(line: string): Promise<void> {
    let request: BridgeRequest;
    try {
      request = parseRequest(line);
    } catch (error) {
      this.#writeFailure(null, error);
      return;
    }

    if (this.#activeRequests.has(request.id)) {
      this.#writeFailure(
        request.id,
        new BridgeProtocolError(
          "duplicate_request_id",
          "Request id is already active",
        ),
      );
      return;
    }

    const active: ActiveRequest = { cancelled: false };
    this.#activeRequests.set(request.id, active);
    try {
      const result = await this.#dispatch(request);
      if (!active.cancelled) {
        this.#writeLine(successResponse(request.id, result));
      }
    } catch (error) {
      if (!active.cancelled) {
        this.#writeFailure(request.id, error);
      }
    } finally {
      this.#activeRequests.delete(request.id);
    }
  }

  /** Stops the SDK client once, bounding cleanup if the runtime hangs. */
  async stop(): Promise<void> {
    if (this.#stopping && this.#client === undefined) {
      return;
    }
    this.#stopping = true;
    const client = this.#client;
    this.#client = undefined;
    if (client !== undefined) {
      await withTimeout(client.stop(), SHUTDOWN_TIMEOUT_MS).catch(
        () => undefined,
      );
    }
  }

  async #dispatch(request: BridgeRequest): Promise<unknown> {
    if (request.method === "handshake") {
      return this.#handshake(request);
    }
    if (!this.#handshakeComplete || this.#client === undefined) {
      throw new BridgeProtocolError(
        "handshake_required",
        "Complete handshake before other requests",
      );
    }
    if (request.protocolVersion !== PROTOCOL_VERSION) {
      throw unsupportedProtocol();
    }

    switch (request.method) {
      case "quota.get":
        return withTimeout(
          this.#client.getQuota(),
          this.#requestTimeoutMs,
        );
      case "session.usage":
        return withTimeout(
          this.#client.getSessionUsage(
            requireString(request.params, "sessionId"),
          ),
          this.#requestTimeoutMs,
        );
      case "health.get":
        return withTimeout(
          this.#client.getHealth(),
          this.#requestTimeoutMs,
        );
      case "version.get":
        return withTimeout(
          this.#client.getVersion(),
          this.#requestTimeoutMs,
        );
      case "cancel": {
        const requestId = requireString(request.params, "requestId");
        const target = this.#activeRequests.get(requestId);
        if (target !== undefined) {
          target.cancelled = true;
        }
        return { cancelled: target !== undefined };
      }
      case "shutdown":
        this.#stopping = true;
        await this.stop();
        this.#closeInput?.();
        return { stopped: true };
    }
  }

  async #handshake(request: BridgeRequest): Promise<unknown> {
    if (this.#handshakeComplete) {
      throw new BridgeProtocolError(
        "already_initialized",
        "Handshake has already completed",
      );
    }
    const supported = request.params.supportedVersions;
    if (
      !Array.isArray(supported) ||
      !supported.includes(PROTOCOL_VERSION) ||
      request.protocolVersion !== PROTOCOL_VERSION
    ) {
      throw unsupportedProtocol();
    }

    let client: BridgeSdkClient;
    try {
      client = this.#createClient();
      await withTimeout(client.start(), this.#requestTimeoutMs);
    } catch (error) {
      throw normalizeSdkFailure(error, "initialization_failed");
    }
    try {
      const version = await withTimeout(
        client.getVersion(),
        this.#requestTimeoutMs,
      );
      this.#client = client;
      this.#handshakeComplete = true;
      return {
        negotiatedVersion: PROTOCOL_VERSION,
        version,
      };
    } catch (error) {
      await withTimeout(client.stop(), SHUTDOWN_TIMEOUT_MS).catch(
        () => undefined,
      );
      throw normalizeSdkFailure(error, "initialization_failed");
    }
  }

  #writeFailure(id: string | null, error: unknown): void {
    const normalized =
      error instanceof BridgeProtocolError
        ? error
        : normalizeSdkFailure(error, "operation_failed");
    this.#writeLine(
      errorResponse(id, {
        code: normalized.code,
        message: normalized.safeMessage,
        retryable: normalized.retryable,
      }),
    );
  }
}

/** Runs a bridge host over process stdio without writing secrets to stdout. */
export async function runStdioHost(
  createClient: BridgeSdkClientFactory,
  input: Readable = process.stdin,
  output: Writable = process.stdout,
): Promise<void> {
  const host = new PersistentBridgeHost(createClient, (line) => {
    output.write(`${line}\n`);
  });
  await host.run(input);
}

function requireString(
  params: Readonly<Record<string, unknown>>,
  key: string,
): string {
  const value = params[key];
  if (typeof value !== "string" || value.length === 0) {
    throw new BridgeProtocolError(
      "invalid_params",
      `${key} must be a non-empty string`,
    );
  }
  return value;
}

function withTimeout<T>(operation: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(
      () =>
        reject(
          new BridgeProtocolError(
            "request_timeout",
            "Bridge operation timed out",
            true,
          ),
        ),
      timeoutMs,
    );
    operation.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error: unknown) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
}

function unsupportedProtocol(): BridgeProtocolError {
  return new BridgeProtocolError(
    "unsupported_protocol",
    `Bridge supports protocol version ${PROTOCOL_VERSION}`,
  );
}

function normalizeSdkFailure(
  error: unknown,
  fallbackCode: string,
): BridgeProtocolError {
  if (error instanceof BridgeProtocolError) {
    return error;
  }
  const message =
    error instanceof Error ? error.message.toLowerCase() : String(error);
  if (/\b(auth|login|logged[\s-]?out|credential|unauthorized)\b/.test(message)) {
    return new BridgeProtocolError(
      "authentication_failed",
      "Copilot authentication is required",
    );
  }
  if (/\b(session).*(not found|missing|unknown)\b/.test(message)) {
    return new BridgeProtocolError(
      "session_not_found",
      "Copilot session was not found",
    );
  }
  if (isRecord(error) && error.code === "unsupported_capability") {
    return new BridgeProtocolError(
      "unsupported_capability",
      "Copilot runtime does not support this operation",
    );
  }
  if (isRecord(error) && error.code === "unsupported_sdk") {
    return new BridgeProtocolError(
      "unsupported_sdk",
      "Bundled Copilot SDK and CLI versions are incompatible",
    );
  }
  if (isRecord(error) && error.code === "rpc_unavailable") {
    return new BridgeProtocolError(
      "rpc_unavailable",
      "Experimental Copilot usage RPC is unavailable",
    );
  }
  if (isRecord(error) && error.code === "malformed_quota") {
    return new BridgeProtocolError(
      "malformed_response",
      "Copilot SDK returned malformed quota data",
    );
  }
  if (isRecord(error) && error.code === "quota_timeout") {
    return new BridgeProtocolError(
      "request_timeout",
      "Copilot SDK operation timed out",
      true,
    );
  }
  return new BridgeProtocolError(
    fallbackCode,
    "Copilot SDK operation failed",
    true,
  );
}
