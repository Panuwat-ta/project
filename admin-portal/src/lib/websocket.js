const DELAYS = [1000, 2000, 4000, 8000];
const MAX_DELAY = 30000;

/**
 * Resilient admin-dashboard WebSocket client.
 * Calls onEvent({type}) for server messages and onStatus(connected:boolean)
 * for connection state. Reconnects with exponential backoff; stops when
 * closed explicitly (logout/unmount) or the token is rejected.
 */
export function createDashboardSocket({ getUrl, onEvent, onStatus }) {
  let socket = null;
  let stopped = false;
  let attempts = 0;
  let timer = null;

  const setStatus = (connected) => {
    if (onStatus) onStatus(connected);
  };

  function connect() {
    if (stopped) return;
    const url = getUrl();
    if (!url) return;
    try {
      socket = new WebSocket(url);
    } catch {
      scheduleReconnect();
      return;
    }

    socket.onopen = () => {
      attempts = 0;
      setStatus(true);
    };
    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data && typeof data.type === 'string' && onEvent) onEvent(data);
      } catch {
        // Ignore malformed frames.
      }
    };
    socket.onclose = (event) => {
      setStatus(false);
      // Auth rejected: do not reconnect, session is dead.
      if (event.code === 4001 || event.code === 4401 || event.code === 4403) return;
      scheduleReconnect();
    };
    socket.onerror = () => {
      try {
        socket?.close();
      } catch {
        // noop
      }
    };
  }

  function scheduleReconnect() {
    if (stopped) return;
    const delay =
      attempts < DELAYS.length ? DELAYS[attempts] : MAX_DELAY;
    attempts += 1;
    clearTimeout(timer);
    timer = setTimeout(connect, delay);
  }

  function close() {
    stopped = true;
    clearTimeout(timer);
    try {
      socket?.close();
    } catch {
      // noop
    }
    socket = null;
  }

  connect();
  return { close };
}
