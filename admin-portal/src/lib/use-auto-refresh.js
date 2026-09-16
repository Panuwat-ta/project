import { useEffect, useRef } from "react";

/**
 * Polling fallback that keeps pages live without backend changes.
 * The callback rides a ref so the interval is armed once and never
 * restarts on re-renders. Skips ticks while the tab is hidden and
 * always cleans up on unmount. Callbacks must support a quiet mode
 * (no skeleton, no error toast, keep old data on failure).
 */
export function useAutoRefresh(callback, intervalMs = 30000) {
  const cb = useRef(callback);

  useEffect(() => {
    cb.current = callback;
  });

  useEffect(() => {
    if (!intervalMs) return undefined;
    const id = setInterval(() => {
      if (!document.hidden) cb.current?.();
    }, intervalMs);
    return () => clearInterval(id);
  }, [intervalMs]);
}
