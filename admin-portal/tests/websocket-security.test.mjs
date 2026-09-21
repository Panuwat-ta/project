import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

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

test("dashboard WebSocket sends auth via subprotocol and deduplicates reconnects", () => {
  assert.match(hookSource, /const WS_PROTOCOL = "scamguard-admin"/);
  assert.match(
    hookSource,
    /new WebSocket\(getWebSocketUrl\("\/admin\/dashboard"\), \[WS_PROTOCOL, token\]\)/
  );
  assert.match(hookSource, /if \(closed \|\| timer\) return;/);
  assert.match(hookSource, /timer = setTimeout\(\(\) => \{\s*timer = null;\s*connect\(\);/);
  assert.match(hookSource, /ws\.onclose = down;/);
});
