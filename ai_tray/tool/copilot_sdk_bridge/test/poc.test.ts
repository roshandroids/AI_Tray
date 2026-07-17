/** Deterministic unit coverage for the one-shot SDK POC gate. */

import assert from "node:assert/strict";
import test from "node:test";

import {
  runQuotaPoc,
  type CopilotSdkClient,
} from "../src/poc.js";
import { mapQuotaResponse, PocError } from "../src/quota.js";

const VALID_RESPONSE = {
  quotaSnapshots: {
    premium_interactions: {
      entitlementRequests: 300,
      usedRequests: 12,
      remainingPercentage: 96,
      overage: 0,
      overageAllowedWithExhaustedQuota: false,
      resetDate: "2026-08-01T00:00:00Z",
    },
    chat: {
      entitlementRequests: 0,
      usedRequests: 5,
      remainingPercentage: 100,
      overage: 0,
      overageAllowedWithExhaustedQuota: true,
    },
    completions: {
      entitlementRequests: 0,
      usedRequests: 9,
      remainingPercentage: 100,
      overage: 0,
      overageAllowedWithExhaustedQuota: true,
    },
  },
};

test("maps the three quota snapshots to the temporary domain model", () => {
  const result = mapQuotaResponse(VALID_RESPONSE);

  assert.equal(result.premium.entitlementRequests, 300);
  assert.equal(result.chat.usedRequests, 5);
  assert.equal(result.completion.usedRequests, 9);
  assert.equal(result.chat.resetDate, null);
});

test("maps absent optional snapshot categories as unavailable", () => {
  const result = mapQuotaResponse({
    quotaSnapshots: {
      premium_interactions: VALID_RESPONSE.quotaSnapshots.premium_interactions,
    },
  });

  assert.equal(result.premium.available, true);
  assert.equal(result.chat.available, false);
  assert.equal(result.completion.available, false);
});

test("reports initialization failure with a secret-safe stable code", async () => {
  const secret = "ghu_NEVER_LOG_THIS";
  const client = fakeClient({
    start: async () => {
      throw new Error(`startup failed with ${secret}`);
    },
  });

  await assert.rejects(
    runQuotaPoc(() => client, 100),
    (error: unknown) => {
      assertPocError(error, "initialization_failed");
      assert.equal(String(error).includes(secret), false);
      return true;
    },
  );
  assert.equal(client.stopCalls(), 1);
});

test("reports client construction failure without attempting lifecycle calls", async () => {
  await assert.rejects(
    runQuotaPoc(() => {
      throw new Error("constructor secret=NEVER_LOG_THIS");
    }, 100),
    (error: unknown) => {
      assertPocError(error, "initialization_failed");
      assert.equal(String(error).includes("NEVER_LOG_THIS"), false);
      return true;
    },
  );
});

test("reports logged-out authentication failure without raw details", async () => {
  const secret = "token=NEVER_LOG_THIS";
  const client = fakeClient({
    getQuota: async () => {
      throw new Error(`unauthorized credential ${secret}`);
    },
  });

  await assert.rejects(
    runQuotaPoc(() => client, 100),
    (error: unknown) => {
      assertPocError(error, "authentication_failed");
      assert.equal(String(error).includes(secret), false);
      return true;
    },
  );
  assert.equal(client.stopCalls(), 1);
});

test("times out a hanging quota request and still stops the client", async () => {
  const client = fakeClient({
    getQuota: () => new Promise<unknown>(() => undefined),
  });

  await assert.rejects(
    runQuotaPoc(() => client, 10),
    (error: unknown) => {
      assertPocError(error, "quota_timeout");
      return true;
    },
  );
  assert.equal(client.stopCalls(), 1);
});

test("rejects null and malformed SDK responses and still cleans up", async () => {
  const malformedResponses: readonly unknown[] = [
    null,
    {},
    { quotaSnapshots: null },
    { quotaSnapshots: {} },
    { quotaSnapshots: { premium_interactions: null } },
    {
      quotaSnapshots: {
        premium_interactions: {
          ...VALID_RESPONSE.quotaSnapshots.premium_interactions,
          entitlementRequests: "300",
        },
      },
    },
    {
      quotaSnapshots: {
        premium_interactions: {
          ...VALID_RESPONSE.quotaSnapshots.premium_interactions,
          remainingPercentage: 101,
        },
      },
    },
    {
      quotaSnapshots: {
        premium_interactions: {
          ...VALID_RESPONSE.quotaSnapshots.premium_interactions,
          resetDate: "not-a-date",
        },
      },
    },
  ];

  for (const response of malformedResponses) {
    const client = fakeClient({
      getQuota: async () => response,
    });
    await assert.rejects(
      runQuotaPoc(() => client, 100),
      (error: unknown) => {
        assertPocError(error, "malformed_quota");
        return true;
      },
    );
    assert.equal(client.stopCalls(), 1);
  }
});

test("tolerates additive SDK schema drift while allowlisting output", async () => {
  const client = fakeClient({
    getQuota: async () => ({
    accountToken: "must-not-cross-boundary",
    quotaSnapshots: {
      ...VALID_RESPONSE.quotaSnapshots,
      future_quota: {
        token: "must-not-cross-boundary",
      },
      premium_interactions: {
        ...VALID_RESPONSE.quotaSnapshots.premium_interactions,
        futureField: "ignored",
        token: "must-not-cross-boundary",
      },
    },
    }),
  });

  const result = await runQuotaPoc(() => client, 100);
  const serialized = JSON.stringify(result);

  assert.equal(result.premium.available, true);
  assert.equal(serialized.includes("must-not-cross-boundary"), false);
  assert.equal(serialized.includes("future"), false);
  assert.equal(serialized.includes("token"), false);
  assert.equal(client.stopCalls(), 1);
});

test("stops exactly once after a successful request", async () => {
  const client = fakeClient();

  const result = await runQuotaPoc(() => client, 100);

  assert.equal(result.premium.available, true);
  assert.equal(client.stopCalls(), 1);
});

test("surfaces shutdown failure after an otherwise successful request", async () => {
  const client = fakeClient({
    stop: async () => {
      throw new Error("shutdown included secret=NEVER_LOG_THIS");
    },
  });

  await assert.rejects(
    runQuotaPoc(() => client, 100),
    (error: unknown) => {
      assertPocError(error, "shutdown_failed");
      assert.equal(String(error).includes("NEVER_LOG_THIS"), false);
      return true;
    },
  );
  assert.equal(client.stopCalls(), 1);
});

interface FakeOverrides {
  readonly start?: () => Promise<void>;
  readonly getQuota?: () => Promise<unknown>;
  readonly stop?: () => Promise<void>;
}

function fakeClient(overrides: FakeOverrides = {}): CopilotSdkClient & {
  stopCalls(): number;
} {
  let stops = 0;
  return {
    rpc: {
      account: {
        getQuota: async () =>
          overrides.getQuota?.() ?? Promise.resolve(VALID_RESPONSE),
      },
    },
    start: overrides.start ?? (async () => undefined),
    stop: async () => {
      stops += 1;
      await overrides.stop?.();
    },
    stopCalls: () => stops,
  };
}

function assertPocError(
  error: unknown,
  expectedCode: PocError["code"],
): asserts error is PocError {
  assert.ok(error instanceof PocError);
  assert.equal(error.code, expectedCode);
  assert.equal(error.message, expectedCode);
}
