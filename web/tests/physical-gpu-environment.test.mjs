import assert from "node:assert/strict";
import test from "node:test";

import {
  MAX_FOREGROUND_LOSS_MSEC,
  MINIMUM_DISPLAY_REFRESH_HZ,
  physicalGpuEnvironmentIssues,
} from "./physical-gpu-environment.mjs";

test("accepts a continuously foregrounded 60 Hz physical display", () => {
  assert.deepEqual(
    physicalGpuEnvironmentIssues({
      displayRefreshHz: 60,
      visibilityLostMsec: MAX_FOREGROUND_LOSS_MSEC,
      focusLostMsec: MAX_FOREGROUND_LOSS_MSEC,
    }),
    [],
  );
});

test("accepts the standard 59.94 Hz mode reported by Windows as integer 59", () => {
  assert.equal(MINIMUM_DISPLAY_REFRESH_HZ, 59);
  assert.deepEqual(
    physicalGpuEnvironmentIssues({
      displayRefreshHz: 59,
      visibilityLostMsec: 0,
      focusLostMsec: 0,
    }),
    [],
  );
});

test("rejects the prior 30 Hz physical-probe environment", () => {
  assert.deepEqual(
    physicalGpuEnvironmentIssues({
      displayRefreshHz: 30,
      visibilityLostMsec: 0,
      focusLostMsec: 0,
    }),
    [
      "display refresh must be at least 59 Hz measured " +
      "(nominal 60 Hz-class); recorded 30 Hz",
    ],
  );
});

test("rejects visibility throttling before interpreting frame metrics", () => {
  assert.deepEqual(
    physicalGpuEnvironmentIssues({
      displayRefreshHz: 60,
      visibilityLostMsec: MAX_FOREGROUND_LOSS_MSEC + 1,
      focusLostMsec: 0,
    }),
    [`page visibility was lost for ${MAX_FOREGROUND_LOSS_MSEC + 1} ms`],
  );
});

test("rejects an occluded or background-focused browser", () => {
  assert.deepEqual(
    physicalGpuEnvironmentIssues({
      displayRefreshHz: 60,
      visibilityLostMsec: 0,
      focusLostMsec: MAX_FOREGROUND_LOSS_MSEC + 1,
    }),
    [`browser focus was lost for ${MAX_FOREGROUND_LOSS_MSEC + 1} ms`],
  );
});
