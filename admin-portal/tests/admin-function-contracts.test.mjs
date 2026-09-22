import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";
import path from "node:path";
import { createServer } from "vite";

let vite;
let api;
let utils;
let display;
let heatmap;
const storage = new Map();
const redirects = [];

globalThis.localStorage = {
  getItem: (key) => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, String(value)),
  removeItem: (key) => storage.delete(key),
};

globalThis.window = {
  location: {
    pathname: "/admin/dashboard",
    protocol: "https:",
    host: "admin.example.test",
    replace: (value) => redirects.push(value),
  },
};
before(async () => {
  vite = await createServer({
    configFile: false,
    logLevel: "error",
    resolve: { alias: { "@": path.resolve(process.cwd(), "src") } },
    server: { middlewareMode: true, hmr: false },
    appType: "custom",
    define: {
      "import.meta.env.VITE_API_BASE_URL": JSON.stringify("/api/v1"),
      "import.meta.env.VITE_REFRESH_LEEWAY_SECONDS": JSON.stringify("10"),
    },
  });
  api = await vite.ssrLoadModule("/src/lib/api.js");
  utils = await vite.ssrLoadModule("/src/lib/utils.js");
  display = await vite.ssrLoadModule("/src/lib/display-state.js");
  heatmap = await vite.ssrLoadModule("/src/lib/heatmap-math.js");
});

after(async () => {
  api?.clearAuth();
  await vite?.close();
});

beforeEach(() => {
  storage.clear();
  redirects.length = 0;
  api?.clearAuth();
  window.location.pathname = "/admin/dashboard";
});
const jsonResponse = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

const makeJwt = (payload) => {
  const encode = (value) =>
    Buffer.from(JSON.stringify(value)).toString("base64url");
  return `${encode({ alg: "none", typ: "JWT" })}.${encode(payload)}.sig`;
};

test("token helpers preserve only current in-memory access token and stored user", () => {
  api.setAuth("access-1", { id: 7, email: "admin@example.test" });
  assert.equal(api.getAccessToken(), "access-1");
  assert.deepEqual(api.getStoredUser(), { id: 7, email: "admin@example.test" });

  storage.set("user", "{broken-json");
  assert.equal(api.getStoredUser(), null);
  api.clearAuth();
  assert.equal(api.getAccessToken(), null);
  assert.equal(storage.has("user"), false);
});

test("JWT decode and expiry helpers distinguish malformed, expired, and valid tokens", () => {
  const now = Math.floor(Date.now() / 1000);
  assert.equal(api.decodeJwt("broken"), null);
  assert.equal(api.isTokenExpired(null), true);
  assert.equal(api.isTokenExpired(makeJwt({ exp: now - 30 })), true);
  assert.equal(api.isTokenExpired(makeJwt({ exp: now + 3600 }), 0), false);
  assert.deepEqual(api.decodeJwt(makeJwt({ sub: "9", exp: now + 60 })).sub, "9");
});
test("apiRequest retries one 401 through refresh and uses the rotated access token", async () => {
  const calls = [];
  const originalFetch = globalThis.fetch;
  api.setAuth("old-token", { id: 1 });
  globalThis.fetch = async (url, options = {}) => {
    calls.push({ url: String(url), options });
    if (String(url).endsWith("/admin/refresh")) {
      return jsonResponse({ access_token: "new-token", user: { id: 1 } });
    }
    const dashboardCalls = calls.filter((call) => call.url.endsWith("/admin/dashboard"));
    return dashboardCalls.length === 1
      ? jsonResponse({ detail: "expired" }, 401)
      : jsonResponse({ ok: true });
  };

  try {
    assert.deepEqual(await api.fetchDashboard(), { ok: true });
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(calls.length, 3);
  assert.equal(calls[0].options.headers.Authorization, "Bearer old-token");
  assert.equal(calls[1].url, "/api/v1/admin/refresh");
  assert.equal(calls[1].options.credentials, "include");
  assert.equal(calls[2].options.headers.Authorization, "Bearer new-token");
  assert.equal(api.getAccessToken(), "new-token");
});
test("concurrent 401 responses share one refresh request", async () => {
  const originalFetch = globalThis.fetch;
  let refreshCount = 0;
  let protectedCount = 0;
  api.setAuth("old-token", { id: 1 });
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.endsWith("/admin/refresh")) {
      refreshCount += 1;
      await new Promise((resolve) => setTimeout(resolve, 10));
      return jsonResponse({ access_token: "shared-token", user: { id: 1 } });
    }
    protectedCount += 1;
    return protectedCount <= 2
      ? jsonResponse({ detail: "expired" }, 401)
      : jsonResponse({ ok: true });
  };

  try {
    const [dashboard, health] = await Promise.all([
      api.fetchDashboard(),
      api.fetchHealth(),
    ]);
    assert.deepEqual(dashboard, { ok: true });
    assert.deepEqual(health, { ok: true });
  } finally {
    globalThis.fetch = originalFetch;
  }
  assert.equal(refreshCount, 1);
});
test("Admin API wrapper functions target the expected method, URL, and JSON body", async () => {
  const calls = [];
  const originalFetch = globalThis.fetch;
  api.setAuth("contract-token", { id: 1 });
  globalThis.fetch = async (url, options = {}) => {
    calls.push({ url: String(url), options });
    return jsonResponse({ ok: true });
  };

  try {
    await api.fetchHealth();
    await api.searchGlobal("a+b test");
    await api.fetchReports({ page: 2, limit: 15, status: "Pending", category: "fake_slip", search: "needle" });
    await api.fetchReportDetail(7);
    await api.startReviewReport(7, 3);
    await api.updateReportStatus(7, 3, "approved", "verified");
    await api.fetchUsers(4, 25, "user@example.test");
    await api.getUser(11);
    await api.updateUserStatus(11, false, "abuse");
    await api.fetchModels();
    await api.deployModel(5, "promote");
    await api.dryRunModel(5);
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(calls.length, 12);
  assert.equal(calls[0].url, "/api/v1/admin/health");
  assert.equal(calls[1].url, "/api/v1/admin/search?q=a%2Bb%20test");
  assert.equal(
    calls[2].url,
    "/api/v1/admin/reports?page=2&limit=15&status=pending&category=fake_slip&search=needle"
  );
  assert.equal(calls[3].url, "/api/v1/admin/reports/7");
  assert.equal(calls[4].options.method, "POST");
  assert.deepEqual(JSON.parse(calls[4].options.body), { version: 3 });
  assert.equal(calls[5].options.method, "PATCH");
  assert.deepEqual(JSON.parse(calls[5].options.body), {
    version: 3,
    status: "approved",
    admin_note: "verified",
  });
  assert.equal(calls[6].url, "/api/v1/admin/users?page=4&limit=25&search=user%40example.test");
  assert.equal(calls[7].url, "/api/v1/admin/users/11");
  assert.equal(calls[8].options.method, "PATCH");
  assert.deepEqual(JSON.parse(calls[8].options.body), {
    is_active: false,
    reason: "abuse",
  });
  assert.equal(calls[9].url, "/api/v1/admin/models");
  assert.equal(calls[10].options.method, "POST");
  assert.deepEqual(JSON.parse(calls[10].options.body), { reason: "promote" });
  assert.equal(calls[11].url, "/api/v1/admin/models/5/dry-run");
});
test("audit, export, profile, and session wrappers preserve endpoint contracts", async () => {
  const calls = [];
  const originalFetch = globalThis.fetch;
  api.setAuth("contract-token", { id: 1 });
  globalThis.fetch = async (url, options = {}) => {
    calls.push({ url: String(url), options });
    return String(url).endsWith("/download")
      ? new Response("zip", { status: 200, headers: { "content-type": "application/zip" } })
      : jsonResponse({ ok: true });
  };

  try {
    await api.fetchAuditLogs({ page: 3, limit: 25, search: "abc", action: "login", entity_type: "user" });
    await api.createExportJob({ status: "approved" });
    await api.fetchExportJobs({ page: 2, limit: 10 });
    await api.getExportJob("job-1");
    await api.cancelExportJob("job-1");
    const raw = await api.downloadExportJob("job-1");
    assert.equal(raw.status, 200);
    await api.fetchAdminProfile();
    await api.updateAdminProfile({ full_name: "Admin Two" });
    await api.fetchAdminSessions();
    await api.revokeAdminSession("session-1");
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(calls.length, 10);
  assert.equal(
    calls[0].url,
    "/api/v1/admin/audit-logs?page=3&limit=25&search=abc&action=login&entity_type=user"
  );
  assert.equal(calls[1].url, "/api/v1/admin/dataset/export-jobs");
  assert.equal(calls[1].options.method, "POST");
  assert.deepEqual(JSON.parse(calls[1].options.body), { status: "approved" });
  assert.equal(calls[2].url, "/api/v1/admin/dataset/export-jobs?page=2&limit=10");
  assert.equal(calls[3].url, "/api/v1/admin/dataset/export-jobs/job-1");
  assert.equal(calls[4].url, "/api/v1/admin/dataset/export-jobs/job-1/cancel");
  assert.equal(calls[4].options.method, "POST");
  assert.equal(calls[5].url, "/api/v1/admin/dataset/export-jobs/job-1/download");
  assert.equal(calls[6].url, "/api/v1/admin/me");
  assert.equal(calls[7].options.method, "PATCH");
  assert.deepEqual(JSON.parse(calls[7].options.body), { full_name: "Admin Two" });
  assert.equal(calls[8].url, "/api/v1/admin/sessions");
  assert.equal(calls[9].url, "/api/v1/admin/sessions/session-1/revoke");
  assert.equal(calls[9].options.method, "POST");
  for (const call of calls) {
    assert.equal(call.options.headers.Authorization, "Bearer contract-token");
    assert.equal(call.options.credentials, "include");
  }
});
test("login stores returned auth and logout always clears local auth then redirects", async () => {
  const calls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options = {}) => {
    calls.push({ url: String(url), options });
    if (String(url).endsWith("/admin/login")) {
      return jsonResponse({ access_token: "login-token", user: { id: 9 } });
    }
    return new Response(null, { status: 204 });
  };

  try {
    const result = await api.adminLogin("admin@example.test", "secret-pass");
    assert.equal(result.access_token, "login-token");
    assert.equal(api.getAccessToken(), "login-token");
    await api.logoutAdmin();
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(calls[0].url, "/api/v1/admin/login");
  assert.equal(calls[0].options.method, "POST");
  assert.match(calls[0].options.body, /username=admin%40example.test/);
  assert.match(calls[0].options.body, /password=secret-pass/);
  assert.equal(calls[1].url, "/api/v1/admin/logout");
  assert.equal(api.getAccessToken(), null);
  assert.deepEqual(redirects, ["/login"]);
});

test("WebSocket URL uses current secure origin and never adds auth query data", () => {
  assert.equal(api.getWebSocketUrl(), "wss://admin.example.test/api/v1/ws/admin/dashboard");
  assert.equal(api.getWebSocketUrl("admin/dashboard"), "wss://admin.example.test/api/v1/ws/admin/dashboard");
  assert.doesNotMatch(api.getWebSocketUrl(), /[?&]token=/);
});
test("formatting helpers handle empty, invalid, Thai timezone, and scaled values deterministically", () => {
  assert.equal(utils.formatDate(null), "-");
  assert.equal(utils.formatDate("not-a-date"), "not-a-date");
  const originalTz = process.env.TZ;
  process.env.TZ = "UTC";
  try {
    assert.equal(utils.formatDate("2026-09-22T00:29:54Z"), "22 ก.ย. 2569 07:29:54");
  } finally {
    if (originalTz === undefined) delete process.env.TZ;
    else process.env.TZ = originalTz;
  }
  assert.equal(utils.formatNumber(null), "0");
  assert.equal(utils.formatFileSize(null), "-");
  assert.equal(utils.formatFileSize("not-a-number"), "-");
  assert.equal(utils.formatFileSize(0), "0 B");
  assert.equal(utils.formatFileSize(1024), "1.0 KB");
  assert.equal(utils.formatFileSize(1024 * 1024), "1.0 MB");
  assert.equal(utils.cn("px-2", false && "hidden", "px-4"), "px-4");
});

test("display-state helpers preserve unknown, boundary risk, operational, and evidence states", () => {
  assert.equal(display.hasDisplayValue(0), true);
  assert.equal(display.hasDisplayValue(""), false);
  assert.equal(display.toFiniteNumber("42"), 42);
  assert.equal(display.toFiniteNumber(Infinity), null);
  assert.equal(display.formatOptionalMetric(null), "ไม่ได้รายงาน");
  assert.equal(display.formatOptionalMetric(12.345, { digits: 1, suffix: "%" }), "12.3%");
  assert.deepEqual(display.getRiskState(null), { available: false, score: null, label: "ไม่ทราบ", variant: "default" });
  assert.equal(display.getRiskState(39).label, "ต่ำ");
  assert.equal(display.getRiskState(40).label, "กลาง");
  assert.equal(display.getRiskState(69).label, "กลาง");
  assert.equal(display.getRiskState(70).label, "สูง");
  assert.equal(display.getOperationalStatus("DEGRADED").variant, "warning");
  assert.equal(display.getEvidenceState("checked-no-match").label, "ตรวจแล้ว: ไม่พบภาพตรงกัน");
});
test("heatmap math clamps pointer, opacity, divider, and zoom boundaries", () => {
  assert.equal(heatmap.clampPct(-10), 0);
  assert.equal(heatmap.clampPct(120), 100);
  assert.equal(heatmap.clampPct(Number.NaN), 0);
  assert.equal(heatmap.pointerToPct(150, 100, 200), 25);
  assert.equal(heatmap.pointerToPct(50, 100, 0), 0);
  assert.deepEqual(heatmap.sliderClipStyle(25), { clipPath: "inset(0 75% 0 0)" });
  assert.deepEqual(heatmap.dividerStyle(110), { left: "100%" });
  assert.equal(heatmap.opacityFraction(40), 0.4);
  assert.equal(heatmap.zoomIn(2.5), 2.5);
  assert.equal(heatmap.zoomIn(null), 1.25);
  assert.equal(heatmap.zoomOut(0.75), 0.75);
  assert.equal(heatmap.zoomOut(null), 0.75);
});
