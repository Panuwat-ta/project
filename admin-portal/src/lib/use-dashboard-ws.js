import { useEffect, useRef } from "react";
import { getAccessToken, getWebSocketUrl } from "@/lib/api";

const MAX_DELAY = 30000;

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
    let ws = null;
    let timer = null;
    let attempt = 0;
    let closed = false;

    const schedule = () => {
      if (closed) return;
      attempt += 1;
      const delay = Math.min(1000 * 2 ** (attempt - 1), MAX_DELAY);
      timer = setTimeout(connect, delay);
    };

    const connect = () => {
      if (closed) return;
      const token = getAccessToken();
      if (!token) {
        // Not logged in (or session expired) — retry, don't spin.
        timer = setTimeout(connect, 2000);
        return;
      }
      try {
        ws = new WebSocket(getWebSocketUrl("/admin/dashboard", token));
      } catch {
        schedule();
        return;
      }
      ws.onopen = () => {
        attempt = 0;
        handlers.current.onStatusChange?.(true);
      };
      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          if (msg.type === "refresh_dashboard") {
            handlers.current.onRefresh?.();
          }
        } catch {
          // ignore malformed pushes
        }
      };
      const down = () => {
        handlers.current.onStatusChange?.(false);
        schedule();
      };
      ws.onerror = down;
      ws.onclose = down;
    };

    connect();
    return () => {
      closed = true;
      if (timer) clearTimeout(timer);
      if (ws) ws.close();
    };
  }, []);
}
