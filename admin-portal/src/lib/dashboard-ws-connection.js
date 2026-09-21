export const DASHBOARD_WS_PROTOCOL = "scamguard-admin";

const MAX_RECONNECT_DELAY = 30000;
const MISSING_TOKEN_RETRY_DELAY = 2000;

export function createDashboardWebSocketConnection({
  getToken,
  getUrl,
  onRefresh,
  onStatusChange,
  WebSocketImpl = WebSocket,
  setTimeoutImpl = setTimeout,
  clearTimeoutImpl = clearTimeout,
}) {
  let ws = null;
  let timer = null;
  let attempt = 0;
  let stopped = false;

  function schedule(delay) {
    if (stopped || timer) return;
    const reconnectDelay = delay ?? Math.min(1000 * 2 ** attempt++, MAX_RECONNECT_DELAY);
    timer = setTimeoutImpl(() => {
      timer = null;
      connect();
    }, reconnectDelay);
  }

  function connect() {
    if (stopped) return;
    const token = getToken();
    if (!token) {
      schedule(MISSING_TOKEN_RETRY_DELAY);
      return;
    }

    let socket;
    try {
      socket = new WebSocketImpl(getUrl(), [DASHBOARD_WS_PROTOCOL, token]);
      ws = socket;
    } catch {
      schedule();
      return;
    }

    socket.onopen = () => {
      if (ws !== socket || stopped) return;
      attempt = 0;
      onStatusChange?.(true);
    };
    socket.onmessage = (event) => {
      if (ws !== socket || stopped) return;
      try {
        const message = JSON.parse(event.data);
        if (message.type === "refresh_dashboard") onRefresh?.();
      } catch {
        // Ignore malformed pushes.
      }
    };
    socket.onerror = () => {
      if (ws === socket && socket.readyState !== WebSocketImpl.CLOSED) socket.close();
    };
    socket.onclose = () => {
      if (ws !== socket) return;
      ws = null;
      onStatusChange?.(false);
      schedule();
    };
  }

  connect();

  return () => {
    stopped = true;
    if (timer) {
      clearTimeoutImpl(timer);
      timer = null;
    }
    const socket = ws;
    ws = null;
    if (socket) socket.close();
  };
}
