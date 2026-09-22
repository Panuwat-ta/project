import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

import {
  createDashboardWebSocketConnection,
  DASHBOARD_WS_PROTOCOL,
} from "../src/lib/dashboard-ws-connection.js";

const apiSource = await readFile(new URL("../src/lib/api.js", import.meta.url), "utf8");
const hookSource = await readFile(
  new URL("../src/lib/use-dashboard-ws.js", import.meta.url),
  "utf8"
);

test("WebSocket URL never carries an access token query parameter", () => {
  assert.match(apiSource, /getWebSocketUrl\(path = "\/admin\/dashboard"\)/);
  assert.doesNotMatch(apiSource, /\?token=/);
  assert.doesNotMatch(apiSource, /getWebSocketUrl\([^)]*token/);
});

test("dashboard hook delegates connection lifecycle to the tested controller", () => {
  assert.match(hookSource, /createDashboardWebSocketConnection/);
  assert.doesNotMatch(hookSource, /new WebSocket/);
});

test("dashboard WebSocket authenticates, reconnects once, and ignores stale events", () => {
  const sockets = [];
  const timers = new Map();
  const statuses = [];
  let nextTimerId = 1;
  let refreshes = 0;

  class FakeWebSocket {
    static CLOSED = 3;

    constructor(url, protocols) {
      this.url = url;
      this.protocols = protocols;
      this.readyState = 0;
      this.closeCalls = 0;
      sockets.push(this);
    }

    close() {
      this.closeCalls += 1;
      this.readyState = FakeWebSocket.CLOSED;
      this.onclose?.();
    }
  }

  const stop = createDashboardWebSocketConnection({
    getToken: () => "header.payload.signature",
    getUrl: () => "ws://localhost/api/v1/ws/admin/dashboard",
    onRefresh: () => {
      refreshes += 1;
    },
    onStatusChange: (connected) => statuses.push(connected),
    WebSocketImpl: FakeWebSocket,
    setTimeoutImpl: (callback, delay) => {
      const id = nextTimerId++;
      timers.set(id, { callback, delay });
      return id;
    },
    clearTimeoutImpl: (id) => timers.delete(id),
  });

  assert.equal(sockets.length, 1);
  assert.deepEqual(sockets[0].protocols, [DASHBOARD_WS_PROTOCOL, "header.payload.signature"]);

  sockets[0].onopen();
  sockets[0].onmessage({ data: JSON.stringify({ type: "refresh_dashboard" }) });
  sockets[0].onerror();
  sockets[0].onclose();

  assert.deepEqual(statuses, [true, false]);
  assert.equal(refreshes, 1);
  assert.equal(timers.size, 1);
  assert.equal([...timers.values()][0].delay, 1000);

  const reconnect = [...timers.values()][0].callback;
  timers.clear();
  reconnect();
  assert.equal(sockets.length, 2);

  sockets[0].onerror();
  assert.equal(sockets[1].closeCalls, 0);
  assert.equal(timers.size, 0);

  stop();
  assert.equal(sockets[1].closeCalls, 1);
  assert.equal(timers.size, 0);
});

test("missing access token keeps only one retry timer and cleanup cancels it", () => {
  const timers = new Map();
  let nextTimerId = 1;

  const stop = createDashboardWebSocketConnection({
    getToken: () => "",
    getUrl: () => "ws://unused",
    WebSocketImpl: class {
      static CLOSED = 3;
    },
    setTimeoutImpl: (callback, delay) => {
      const id = nextTimerId++;
      timers.set(id, { callback, delay });
      return id;
    },
    clearTimeoutImpl: (id) => timers.delete(id),
  });

  assert.equal(timers.size, 1);
  assert.equal([...timers.values()][0].delay, 2000);
  stop();
  assert.equal(timers.size, 0);
});
