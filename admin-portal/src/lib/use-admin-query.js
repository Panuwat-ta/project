import { useCallback, useEffect, useRef, useState } from "react";
import { useToast } from "@/components/ui/ToastContext";
import { useAutoRefresh } from "@/lib/use-auto-refresh";
import { useDashboardWebSocket } from "@/lib/use-dashboard-ws";

/**
 * Single data-fetch lifecycle for admin pages.
 *
 * Owns: initial load, manual refresh, quiet polling (30s), WS invalidation,
 * loading/refreshing flags, error + toast policy, last-updated stamp.
 * Pages supply only the fetcher and user-facing messages.
 *
 * @param {() => Promise<any>} fetcher - resolves the page data shape
 * @param {object} opts
 * @param {any[]} opts.deps - re-run a visible load when these change
 * @param {any} opts.initialData - data reset value on visible-load failure
 * @param {number} opts.pollMs - quiet polling interval (0 disables)
 * @param {boolean} opts.watchWS - quiet reload on dashboard WS push
 * @param {function} opts.onStatusChange - WS connection status passthrough
 * @param {string} opts.successMessage - toast on manual reload
 * @param {string} opts.errorMessage - toast prefix on visible-load failure
 * @param {string} opts.logPrefix - console.error prefix
 * @param {boolean} opts.resetOnError - reset data to initialData on
 *   visible-load failure (default true; false keeps stale data like ModelsList)
 */
export function useAdminQuery(
  fetcher,
  {
    deps = [],
    initialData = null,
    pollMs = 30000,
    watchWS = true,
    onStatusChange,
    successMessage,
    errorMessage = "เกิดข้อผิดพลาดในการโหลดข้อมูล",
    logPrefix = "Admin query error:",
    resetOnError = true,
  } = {}
) {
  const [data, setData] = useState(initialData);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  const toast = useToast();
  const fetcherRef = useRef(fetcher);
  const optsRef = useRef({ successMessage, errorMessage, logPrefix, resetOnError });

  useEffect(() => {
    fetcherRef.current = fetcher;
    optsRef.current = { successMessage, errorMessage, logPrefix, resetOnError };
  });

  const reload = useCallback(async (manual = false, quiet = false) => {
    const opts = optsRef.current;
    try {
      if (manual) setIsRefreshing(true);
      else if (!quiet) setIsLoading(true);
      if (!quiet) setError(null);

      const result = await fetcherRef.current();
      setData(result);
      setLastUpdated(new Date());

      if (manual && opts.successMessage) {
        toast.success(opts.successMessage);
      }
      return result;
    } catch (err) {
      if (quiet) return null;
      console.error(opts.logPrefix, err);
      setError(err.message || opts.errorMessage);
      if (opts.resetOnError) setData(initialData);
      toast.error(`${opts.errorMessage}: ` + err.message);
      return null;
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Visible reload when query deps change (filters, page, id).
  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useAutoRefresh(() => reload(false, true), pollMs);

  useDashboardWebSocket({
    onRefresh: watchWS ? () => reload(false, true) : undefined,
    onStatusChange,
  });

  return { data, isLoading, isRefreshing, error, lastUpdated, reload };
}
