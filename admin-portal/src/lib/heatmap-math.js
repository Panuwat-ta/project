/**
 * Pure math for the heatmap comparison viewer.
 * No DOM, no React — testable through this interface alone.
 */

export const ZOOM_MIN = 0.75;
export const ZOOM_MAX = 2.5;
export const ZOOM_STEP = 0.25;

/** Clamp any number to a 0–100 percentage. */
export function clampPct(value) {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(100, value));
}

/** Pointer x-offset within a rect -> slider percentage. */
export function pointerToPct(clientX, rectLeft, rectWidth) {
  if (!rectWidth) return 0;
  return clampPct(((clientX - rectLeft) / rectWidth) * 100);
}

/** clip-path for the foreground (original) image at the slider. */
export function sliderClipStyle(pct) {
  return { clipPath: `inset(0 ${100 - clampPct(pct)}% 0 0)` };
}

/** Left offset of the divider line. */
export function dividerStyle(pct) {
  return { left: `${clampPct(pct)}%` };
}

/** Range-input value -> CSS opacity fraction. */
export function opacityFraction(pct) {
  return clampPct(pct) / 100;
}

export function zoomIn(zoom) {
  return Math.min((zoom ?? 1) + ZOOM_STEP, ZOOM_MAX);
}

export function zoomOut(zoom) {
  return Math.max((zoom ?? 1) - ZOOM_STEP, ZOOM_MIN);
}
