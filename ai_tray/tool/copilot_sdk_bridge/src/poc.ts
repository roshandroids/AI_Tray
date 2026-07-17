/** One-shot, lifecycle-safe Copilot SDK quota proof of concept. */

import { mapQuotaResponse, PocError, type QuotaResult } from "./quota.js";

/** Minimal SDK surface injected into the POC for deterministic verification. */
export interface CopilotSdkClient {
  readonly rpc: {
    readonly account: {
      getQuota(params: Record<string, never>): Promise<unknown>;
    };
  };
  start(): Promise<void>;
  stop(): Promise<void>;
}

/** Constructs the minimal SDK client used by a one-shot quota request. */
export type CopilotSdkClientFactory = () => CopilotSdkClient;

/**
 * Starts a client, retrieves and validates quota within a deadline, then stops.
 *
 * Errors crossing this boundary are stable codes only; raw SDK errors are
 * never logged or returned because they may contain credentials or paths.
 */
export async function runQuotaPoc(
  createClient: CopilotSdkClientFactory,
  timeoutMs: number,
): Promise<QuotaResult> {
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0) {
    throw new RangeError("timeoutMs must be a positive integer");
  }

  let client: CopilotSdkClient;
  try {
    client = createClient();
  } catch {
    throw new PocError("initialization_failed");
  }

  let result: QuotaResult | undefined;
  let failure: unknown;

  try {
    try {
      await client.start();
    } catch (error) {
      throw classifySdkFailure(error, "initialization_failed");
    }

    let response: unknown;
    try {
      response = await withTimeout(
        client.rpc.account.getQuota({}),
        timeoutMs,
      );
    } catch (error) {
      if (error instanceof PocError) {
        throw error;
      }
      throw classifySdkFailure(error, "initialization_failed");
    }

    result = mapQuotaResponse(response);
  } catch (error) {
    failure = error;
  } finally {
    try {
      await client.stop();
    } catch {
      failure ??= new PocError("shutdown_failed");
    }
  }

  if (failure !== undefined) {
    throw normalizeFailure(failure);
  }
  if (result === undefined) {
    throw new PocError("malformed_quota");
  }
  return result;
}

function withTimeout<T>(operation: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new PocError("quota_timeout")),
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

function classifySdkFailure(
  error: unknown,
  fallback: PocError["code"],
): PocError {
  const message =
    error instanceof Error ? error.message.toLowerCase() : String(error);
  if (
    /\b(auth|authentication|logged[\s-]?out|login|credential|unauthorized)\b/.test(
      message,
    )
  ) {
    return new PocError("authentication_failed");
  }
  return new PocError(fallback);
}

function normalizeFailure(error: unknown): PocError {
  return error instanceof PocError
    ? error
    : new PocError("initialization_failed");
}
