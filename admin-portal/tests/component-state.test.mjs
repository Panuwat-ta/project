import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import path from "node:path";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { createServer } from "vite";
import react from "@vitejs/plugin-react";

let vite;
let RiskBadge;
let OperationalStatusBadge;
let EvidenceState;
let HeatmapComparator;

before(async () => {
  vite = await createServer({
    configFile: false,
    logLevel: "error",
    plugins: [react()],
    resolve: { alias: { "@": path.resolve(process.cwd(), "src") } },
    server: { middlewareMode: true, hmr: false },
    appType: "custom",
  });

  ({ RiskBadge, OperationalStatusBadge, EvidenceState } = await vite.ssrLoadModule(
    "/src/components/ui/Badge.jsx"
  ));
  ({ HeatmapComparator } = await vite.ssrLoadModule(
    "/src/components/ui/HeatmapComparator.jsx"
  ));
});

after(async () => {
  await vite?.close();
});

const render = (component, props) =>
  renderToStaticMarkup(createElement(component, props));

test("missing risk stays unknown while a real zero score stays low", () => {
  const missing = render(RiskBadge, { score: null });
  const zero = render(RiskBadge, { score: 0 });

  assert.match(missing, /ไม่ทราบ/);
  assert.doesNotMatch(missing, /ต่ำ/);
  assert.match(zero, /ต่ำ/);
  assert.match(zero, /\(0\)/);
});

test("operational unknown and degraded remain distinct from healthy", () => {
  const unknown = render(OperationalStatusBadge, { status: null });
  const degraded = render(OperationalStatusBadge, { status: "degraded" });

  assert.match(unknown, /ไม่ทราบ/);
  assert.doesNotMatch(unknown, /ปกติ/);
  assert.match(degraded, /มีข้อจำกัด/);
});

test("evidence states keep source verification outcomes distinct", () => {
  assert.match(render(EvidenceState, { status: "unavailable" }), /ยังไม่พร้อมใช้งาน/);
  assert.match(render(EvidenceState, { status: "not_checked" }), /ยังไม่ได้ตรวจ/);
  assert.match(render(EvidenceState, { status: "error" }), /ตรวจไม่สำเร็จ/);
  assert.match(render(EvidenceState, { status: "available" }), /มีข้อมูล/);
  assert.match(render(EvidenceState, { status: null }), /ไม่ทราบ/);
});

test("missing Heatmap shows unavailable evidence without comparator controls", () => {
  const html = render(HeatmapComparator, {
    originalUrl: "/original.png",
    heatmapUrl: null,
  });

  assert.match(html, /ไม่มี Heatmap จากระบบ/);
  assert.match(html, /ภาพที่แสดงด้านบนเป็นภาพต้นฉบับเท่านั้น/);
  assert.equal((html.match(/src="\/original\.png"/g) || []).length, 1);
  assert.doesNotMatch(html, /role="slider"/);
  assert.doesNotMatch(html, /ผลการวิเคราะห์ฮีตแมป/);
});

test("available Heatmap renders model evidence and accessible comparator", () => {
  const html = render(HeatmapComparator, {
    originalUrl: "/original.png",
    heatmapUrl: "/heatmap.png",
  });

  assert.match(html, /role="slider"/);
  assert.match(html, /src="\/heatmap\.png"/);
  assert.match(html, /ความน่าจะเป็นของความผิดปกติ/);
});
