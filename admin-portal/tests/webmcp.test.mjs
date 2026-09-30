import assert from "node:assert/strict";
import { test } from "node:test";

import {
  ADMIN_PAGE_CONTEXT_TOOL,
  getAdminPageContext,
  registerAdminSiteTools,
} from "../src/lib/webmcp.js";

function pageFixture() {
  return {
    documentRef: {
      title: "ScamGuard Admin",
      documentElement: {
        classList: {
          contains: (value) => value === "dark",
        },
      },
      querySelector: (selector) =>
        selector === "h1" ? { textContent: "  Dashboard  " } : null,
    },
    locationRef: {
      pathname: "/admin/dashboard",
      search: "?token=must-not-be-exposed&range=7d",
    },
    navigatorRef: {
      onLine: true,
    },
  };
}

test("page context exposes only non-sensitive runtime state", () => {
  const context = getAdminPageContext(pageFixture());

  assert.deepEqual(context, {
    title: "ScamGuard Admin",
    path: "/admin/dashboard",
    heading: "Dashboard",
    theme: "dark",
    online: true,
  });
  assert.equal("token" in context, false);
  assert.equal("credential" in context, false);
});

test("site tool is skipped when WebMCP is unavailable", async () => {
  assert.equal(
    await registerAdminSiteTools({
      modelContext: undefined,
      ...pageFixture(),
    }),
    false,
  );
});

test("site tool registers as read-only and returns current page context", async () => {
  let registeredTool;
  const modelContext = {
    registerTool: async (tool) => {
      registeredTool = tool;
    },
  };

  const registered = await registerAdminSiteTools({
    modelContext,
    ...pageFixture(),
  });

  assert.equal(registered, true);
  assert.equal(registeredTool.name, ADMIN_PAGE_CONTEXT_TOOL);
  assert.deepEqual(registeredTool.annotations, { readOnlyHint: true });
  assert.deepEqual(registeredTool.inputSchema, {
    type: "object",
    properties: {},
    additionalProperties: false,
  });
  assert.deepEqual(await registeredTool.execute(), getAdminPageContext(pageFixture()));
});
