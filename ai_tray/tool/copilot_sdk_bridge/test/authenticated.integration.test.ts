/** Opt-in live verification against the currently logged-in Copilot user. */

import assert from "node:assert/strict";
import test from "node:test";

import { runQuotaPoc } from "../src/poc.js";
import type { QuotaResult } from "../src/quota.js";
import { createLoggedInClient } from "../src/sdk_client.js";

const integrationEnabled = process.env.COPILOT_SDK_INTEGRATION === "1";

test(
  "returns structurally valid quota on two consecutive authenticated calls",
  { skip: !integrationEnabled },
  async () => {
    const first = await runQuotaPoc(createLoggedInClient, 15_000);
    const second = await runQuotaPoc(createLoggedInClient, 15_000);

    assertValidStructure(first);
    assertValidStructure(second);
    assert.deepEqual(availabilityShape(first), availabilityShape(second));
  },
);

function assertValidStructure(result: QuotaResult): void {
  const metrics = [result.premium, result.chat, result.completion];
  assert.ok(metrics.some((metric) => metric.available));

  for (const metric of metrics) {
    if (!metric.available) {
      assert.equal(metric.entitlementRequests, null);
      assert.equal(metric.usedRequests, null);
      assert.equal(metric.remainingPercentage, null);
      continue;
    }

    assert.equal(typeof metric.entitlementRequests, "number");
    assert.equal(typeof metric.usedRequests, "number");
    assert.equal(typeof metric.remainingPercentage, "number");
    assert.ok((metric.remainingPercentage ?? -1) >= 0);
    assert.ok((metric.remainingPercentage ?? 101) <= 100);
  }
}

function availabilityShape(result: QuotaResult): readonly boolean[] {
  return [
    result.premium.available,
    result.chat.available,
    result.completion.available,
  ];
}
