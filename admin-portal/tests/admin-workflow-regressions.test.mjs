import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { readFile } from "node:fs/promises";
import { createServer } from "vite";
import path from "node:path";

const readSource = (relativePath) =>
  readFile(new URL(relativePath, import.meta.url), "utf8");

const [modelsSource, usersSource, reportSource, datasetSource, reportsListSource, userDetailSource, topBarSource] =
  await Promise.all([
    readSource("../src/pages/ModelsList.jsx"),
    readSource("../src/pages/UsersList.jsx"),
    readSource("../src/pages/ReportDetail.jsx"),
    readSource("../src/pages/DatasetExport.jsx"),
    readSource("../src/pages/ReportsList.jsx"),
    readSource("../src/pages/UserDetail.jsx"),
    readSource("../src/components/TopBar.jsx"),
  ]);

let vite;
let api;

const storage = new Map();
globalThis.localStorage = {
  getItem: (key) => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, String(value)),
  removeItem: (key) => storage.delete(key),
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
});

after(async () => {
  api?.clearAuth();
  await vite?.close();
});

function successSegment(source, actionCall) {
  const start = source.indexOf(actionCall);
  assert.notEqual(start, -1, `missing action call: ${actionCall}`);
  const end = source.indexOf("} catch (err)", start);
  assert.notEqual(end, -1, `missing catch after: ${actionCall}`);
  return source.slice(start, end);
}

test("successful model deploy bypasses the guarded user-close path", () => {
  const segment = successSegment(modelsSource, "await deployModel(");
  assert.match(segment, /resetDeployModal\(\)/);
  assert.doesNotMatch(segment, /closeDeployModal\(\)/);
});

test("successful user status update bypasses the guarded user-close path", () => {
  const segment = successSegment(usersSource, "await updateUserStatus(");
  assert.match(segment, /resetStatusModal\(\)/);
  assert.doesNotMatch(segment, /closeStatusModal\(\)/);
});

test("successful report decision bypasses the guarded user-close path", () => {
  const segment = successSegment(reportSource, "await updateReportStatus(");
  assert.match(segment, /resetDecisionModal\(\)/);
  assert.doesNotMatch(segment, /closeDecisionModal\(\)/);
});
test("export download goes through authenticated API request", async () => {
  const calls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return {
      ok: true,
      status: 200,
      headers: { get: () => "application/zip" },
    };
  };

  try {
    api.setAuth("header.payload.signature", null);
    assert.equal(typeof api.downloadExportJob, "function");
    await api.downloadExportJob("job-123");
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(calls.length, 1);
  assert.equal(
    calls[0].url,
    "/api/v1/admin/dataset/export-jobs/job-123/download"
  );
  assert.equal(
    calls[0].options.headers.Authorization,
    "Bearer header.payload.signature"
  );
});

test("dataset export UI does not navigate directly to protected download URL", () => {
  assert.match(datasetSource, /downloadExportJob/);
  assert.doesNotMatch(datasetSource, /getExportDownloadUrl/);
  assert.doesNotMatch(datasetSource, /href=\{downloadUrl\}/);
});
test("clear-all reports filter resets status, category, page, and search", () => {
  assert.match(
    reportsListSource,
    /updateUrlParams\("All",\s*"All",\s*1,\s*""\)/
  );
});


test("dataset metadata checkbox has explicit browser field identity and label", () => {
  assert.match(datasetSource, /htmlFor="include-metadata"/);
  assert.match(datasetSource, /id="include-metadata"/);
  assert.match(datasetSource, /name="include_metadata"/);
});


test("dataset category controls use a semantic fieldset legend", () => {
  assert.match(datasetSource, /<fieldset className="space-y-2">/);
  assert.match(datasetSource, /<legend className="block text-\[13px\] font-semibold text-foreground">\s*เลือกหมวดหมู่ที่ต้องการส่งออก\s*<\/legend>/);
  assert.doesNotMatch(datasetSource, /<label className="block text-\[13px\] font-semibold text-foreground">\s*เลือกหมวดหมู่ที่ต้องการส่งออก/);
});


test("user detail renders recent scan execution status", () => {
  assert.match(userDetailSource, /<TableHead>สถานะ<\/TableHead>/);
  assert.match(userDetailSource, /<StatusBadge status=\{scan\.status\} \/>/);
});


test("theme selector exposes direct system, light, and dark choices", () => {
  assert.match(topBarSource, /role="group"/);
  assert.match(topBarSource, /aria-label="เลือกธีม"/);
  assert.match(topBarSource, /value: "system"/);
  assert.match(topBarSource, /value: "light"/);
  assert.match(topBarSource, /value: "dark"/);
  assert.match(topBarSource, /onClick=\{\(\) => setTheme\(value\)\}/);
  assert.match(topBarSource, /aria-pressed=\{isActive\}/);
});
