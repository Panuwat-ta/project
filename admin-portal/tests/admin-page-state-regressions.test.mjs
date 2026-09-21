import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";

const readSource = (relativePath) =>
  readFile(new URL(relativePath, import.meta.url), "utf8");

const [querySource, paletteSource, reportsSource, reportDetailSource, datasetSource, debounceSource] =
  await Promise.all([
    readSource("../src/lib/use-admin-query.js"),
    readSource("../src/components/ui/CommandPalette.jsx"),
    readSource("../src/pages/ReportsList.jsx"),
    readSource("../src/pages/ReportDetail.jsx"),
    readSource("../src/pages/DatasetExport.jsx"),
    readSource("../src/lib/use-debounced-value.js"),
  ]);

function assertOrdered(source, snippets) {
  let previous = -1;
  for (const snippet of snippets) {
    const index = source.indexOf(snippet, previous + 1);
    assert.notEqual(index, -1, `missing snippet: ${snippet}`);
    assert.ok(index > previous, `out-of-order snippet: ${snippet}`);
    previous = index;
  }
}
test("useAdminQuery rejects stale responses before mutating shared state", () => {
  assertOrdered(querySource, [
    "const requestId = ++requestIdRef.current;",
    "const result = await fetcherRef.current();",
    "if (requestId !== requestIdRef.current) return null;",
    "setData(result);",
  ]);
  assert.match(querySource, /if \(requestId !== requestIdRef\.current \|\| quiet\) return null;/);
  assert.match(querySource, /if \(requestId === requestIdRef\.current\) \{\s*setIsLoading\(false\);\s*setIsRefreshing\(false\);/s);
  assert.match(querySource, /requestIdRef\.current \+= 1;/);
});

test("CommandPalette ignores stale search results and invalidates cleanup", () => {
  assertOrdered(paletteSource, [
    "const requestId = ++searchRequestIdRef.current;",
    "const res = await searchGlobal(query.trim());",
    "if (requestId !== searchRequestIdRef.current) return;",
    "setResults(res.items || []);",
  ]);
  assert.match(paletteSource, /searchRequestIdRef\.current \+= 1;/);
  assert.match(paletteSource, /clearTimeout\(focusTimer\)/);
  assert.match(paletteSource, /clearTimeout\(timer\)/);
});
test("ReportsList keeps applied filter/page state in the URL without stale sync", () => {
  assert.match(reportsSource, /const rawPageParam = searchParams\.get\("page"\);/);
  assert.match(reportsSource, /const parsedPage = Number\(rawPageParam \?\? "1"\);/);
  assert.match(
    reportsSource,
    /const pageParam = Number\.isInteger\(parsedPage\) && parsedPage >= 1 \? parsedPage : 1;/
  );
  assert.match(reportsSource, /const page = pageParam;/);
  assert.match(reportsSource, /search: appliedSearch,/);
  assert.match(reportsSource, /deps: \[page, activeTab, category, appliedSearch\]/);
  assert.match(reportsSource, /if \(nextSearch === appliedSearch\) return;/);
  assert.match(reportsSource, /updateUrlParams\("All", "All", 1, ""\);/);
  assert.match(
    reportsSource,
    /onPageChange=\{\(p\) => updateUrlParams\(activeTab, category, p, appliedSearch\)\}/
  );
  assert.match(
    reportsSource,
    /if \(rawPageParam !== null && String\(pageParam\) !== rawPageParam\) \{\s*updateUrlParams\(activeTab, category, pageParam, appliedSearch\);/s
  );
  assert.doesNotMatch(reportsSource, /updateUrlParams\(activeTab, category, page, debouncedSearch\)/);
});

test("reload consumers ignore stale null results before follow-up state", () => {
  const reportGuards = reportDetailSource.match(/if \(updatedReport\) syncNote\(updatedReport\);/g) || [];
  assert.equal(reportGuards.length, 2);
  assert.match(datasetSource, /const updated = await loadJobs\(false, true\);\s*if \(!updated\) return;/s);
});

test("shared debounce is StrictMode-safe and does not reset pagination on mount", () => {
  assert.match(debounceSource, /const debouncedRef = useRef\(initialValue\);/);
  assert.match(
    debounceSource,
    /if \(Object\.is\(normalized, debouncedRef\.current\)\) return undefined;/
  );
  assert.match(debounceSource, /debouncedRef\.current = normalized;/);
  assert.doesNotMatch(debounceSource, /\[value, delay, onDebounced\]/);
});
