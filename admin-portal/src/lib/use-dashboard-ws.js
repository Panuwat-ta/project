import { useEffect, useRef } from "react";
import { getAccessToken, getWebSocketUrl } from "@/lib/api";
import { createDashboardWebSocketConnection } from "@/lib/dashboard-ws-connection";

/**
 * Persistent admin-dashboard WebSocket with exponential-backoff reconnect
 * (1s, 2s, 4s, ... capped at 30s). Handlers ride a ref so the connection
 * is opened once and never torn down by parent re-renders.
 */
export function useDashboardWebSocket({ onRefresh, onStatusChange }) {
  const handlers = useRef({ onRefresh, onStatusChange });

  // Updated in an effect (never during render) so the connection effect below
  // can run once while callbacks always see the latest closures.
  useEffect(() => {
    handlers.current = { onRefresh, onStatusChange };
  });

  useEffect(() => {
    return createDashboardWebSocketConnection({
      getToken: getAccessToken,
      getUrl: () => getWebSocketUrl("/admin/dashboard"),
      onRefresh: () => handlers.current.onRefresh?.(),
      onStatusChange: (connected) => handlers.current.onStatusChange?.(connected),
    });
  }, []);
}
