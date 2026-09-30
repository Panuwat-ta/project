export const ADMIN_PAGE_CONTEXT_TOOL = "get_admin_page_context";

export function getAdminPageContext({
  documentRef,
  locationRef,
  navigatorRef,
} = {}) {
  const currentDocument = documentRef ?? (typeof document === "undefined" ? null : document);
  const currentLocation = locationRef ?? (typeof window === "undefined" ? null : window.location);
  const currentNavigator = navigatorRef ?? (typeof navigator === "undefined" ? null : navigator);
  if (!currentDocument || !currentLocation || !currentNavigator) return null;

  const rootClasses = currentDocument.documentElement?.classList;
  const theme = rootClasses?.contains("dark")
    ? "dark"
    : rootClasses?.contains("light")
      ? "light"
      : "unknown";
  const heading = currentDocument.querySelector?.("h1")?.textContent?.trim() || null;

  return {
    title: currentDocument.title || null,
    path: currentLocation.pathname,
    heading,
    theme,
    online: currentNavigator.onLine,
  };
}

export async function registerAdminSiteTools({
  modelContext,
  documentRef,
  locationRef,
  navigatorRef,
} = {}) {
  const currentDocument = documentRef ?? (typeof document === "undefined" ? null : document);
  const currentLocation = locationRef ?? (typeof window === "undefined" ? null : window.location);
  const currentNavigator = navigatorRef ?? (typeof navigator === "undefined" ? null : navigator);
  const currentModelContext = modelContext ?? currentDocument?.modelContext;
  if (
    typeof currentModelContext?.registerTool !== "function" ||
    !currentDocument ||
    !currentLocation ||
    !currentNavigator
  ) {
    return false;
  }

  await currentModelContext.registerTool({
    name: ADMIN_PAGE_CONTEXT_TOOL,
    description:
      "Read the current ScamGuard Admin Portal page context without accessing credentials or changing application state.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
    annotations: { readOnlyHint: true },
    execute: async () =>
      getAdminPageContext({
        documentRef: currentDocument,
        locationRef: currentLocation,
        navigatorRef: currentNavigator,
      }),
  });

  return true;
}
