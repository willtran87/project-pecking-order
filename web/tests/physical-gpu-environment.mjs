export const MAX_FOREGROUND_LOSS_MSEC = 5_000;
export const MINIMUM_DISPLAY_REFRESH_HZ = 59;

export function physicalGpuEnvironmentIssues({
  displayRefreshHz,
  visibilityLostMsec = 0,
  focusLostMsec = 0,
  maximumForegroundLossMsec = MAX_FOREGROUND_LOSS_MSEC,
} = {}) {
  const issues = [];
  if (
    !Number.isFinite(displayRefreshHz) ||
    displayRefreshHz < MINIMUM_DISPLAY_REFRESH_HZ
  ) {
    issues.push(
      "display refresh must be at least 59 Hz measured " +
      `(nominal 60 Hz-class); recorded ${displayRefreshHz || 0} Hz`,
    );
  }
  if (visibilityLostMsec > maximumForegroundLossMsec) {
    issues.push(
      `page visibility was lost for ${Math.round(visibilityLostMsec)} ms`,
    );
  }
  if (focusLostMsec > maximumForegroundLossMsec) {
    issues.push(
      `browser focus was lost for ${Math.round(focusLostMsec)} ms`,
    );
  }
  return issues;
}
