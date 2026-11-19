/** Keep the canvas sharp enough to read without multiplying GPU work by DPR. */
export function gameRenderSize(stageWidth: number, devicePixelRatio: number, quality: string) {
  const width = Number.isFinite(stageWidth) ? Math.max(1, stageWidth) : 1280;
  const ratio = Number.isFinite(devicePixelRatio) ? Math.max(1, devicePixelRatio) : 1;
  const maximum = quality === "high" ? 2560 : quality === "low" ? 1280 : 1600;
  const minimum = quality === "low" ? 960 : 1280;
  const renderWidth = Math.min(maximum, Math.max(minimum, Math.round(width * (quality === "high" ? ratio : 1))));
  return { width: renderWidth, height: Math.round(renderWidth * 9 / 16) };
}
