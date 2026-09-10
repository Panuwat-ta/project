// Unified API layer - จุดศูนย์กลางของ API calls + Token management + Global error handling

const API_BASE = import.meta.env.VITE_API_BASE_URL;
if (!API_BASE) {
  throw new Error("VITE_API_BASE_URL is required and must be defined in .env");
}
const DEFAULT_LEEWAY = Number(import.meta.env.VITE_REFRESH_LEEWAY_SECONDS) || 10;

const USER_KEY = "user";

let memoryAccessToken = null;

// --- Token helpers ---

export function getAccessToken() {
  return memoryAccessToken;
}

export function getStoredUser() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function setAuth(accessToken, user) {
  memoryAccessToken = accessToken;
  if (user) {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
}

export function clearAuth() {
  memoryAccessToken = null;
  localStorage.removeItem(USER_KEY);
}

export function decodeJwt(token) {
  if (!token) return null;
  try {
    const base64Url = token.split(".")[1];
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), "=");
    const jsonPayload = decodeURIComponent(
      atob(padded)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join("")
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

export function isTokenExpired(token, leewaySeconds = DEFAULT_LEEWAY) {
  if (!token) return true;
  const payload = decodeJwt(token);
  if (!payload || !payload.exp) return true;
  return Date.now() >= (payload.exp - leewaySeconds) * 1000;
}

// --- Global error handling / redirect ---

let refreshPromise = null;

export async function refreshAccessToken() {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    const res = await fetch(`${API_BASE}/admin/refresh`, {
      method: "POST",
      credentials: "include",
    });
    if (!res.ok) throw new Error("Refresh token failed");

    const data = await res.json();
    setAuth(data.access_token, data.user || getStoredUser());
    return data.access_token;
  })();
  try {
    return await refreshPromise;
  } finally {
    refreshPromise = null;
  }
}

export function redirectToLogin() {
  clearAuth();
  if (window.location.pathname !== "/login") {
    window.location.replace("/login");
  }
}

// --- Core request wrapper ---

export async function apiRequest(path, { method = "GET", body, needsAuth = true, parse = "json" } = {}) {
  const finalize = async (token) => {
    const headers = {};
    if (needsAuth && token) {
      headers["Authorization"] = `Bearer ${token}`;
    }
    if (body !== undefined) {
      headers["Content-Type"] = "application/json";
    }
    return fetch(`${API_BASE}${path}`, {
      method,
      headers,
      credentials: "include",
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  };

  let res = await finalize(getAccessToken());

  // 401 -> try to refresh token once, then retry
  if (res.status === 401 && needsAuth) {
    try {
      const newToken = await refreshAccessToken();
      res = await finalize(newToken);
    } catch {
      redirectToLogin();
      throw new Error("เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่");
    }
  }

  if (!res.ok) {
    let detail = `ทำรายการไม่สำเร็จ (HTTP ${res.status})`;
    try {
      const json = await res.json();
      if (json.detail) {
        detail = typeof json.detail === "string" ? json.detail : JSON.stringify(json.detail);
      } else if (json.message) {
        detail = json.message;
      }
    } catch {
      // ignore parse errors
    }
    const error = new Error(detail);
    error.status = res.status;
    // Access token is still invalid even after refresh attempt -> force logout
    if (res.status === 401 && needsAuth) {
      redirectToLogin();
    }
    throw error;
  }

  if (parse === "raw" || res.status === 204) {
    return res;
  }

  const contentType = res.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return res.json();
  }
  return res;
}

// --- Admin API functions ---

export async function adminLogin(username, password) {
  const body = new URLSearchParams({ username, password });
  const res = await fetch(`${API_BASE}/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });

  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const error = new Error(data?.detail || "เข้าสู่ระบบล้มเหลว");
    error.status = res.status;
    throw error;
  }
  setAuth(data.access_token, data.user);
  return data;
}

export function fetchDashboard() {
  return apiRequest("/admin/dashboard");
}

export function fetchHealth() {
  return apiRequest("/admin/health");
}

export function searchGlobal(query) {
  return apiRequest(`/admin/search?q=${encodeURIComponent(query)}`);
}

export function fetchReports({ page = 1, limit = 20, status, category, search } = {}) {
  const params = new URLSearchParams({ page, limit });
  if (status && status !== "All") params.append("status", status.toLowerCase());
  if (category && category !== "All") params.append("category", category);
  if (search) params.append("search", search);
  return apiRequest(`/admin/reports?${params.toString()}`);
}

export function fetchReportDetail(reportId) {
  return apiRequest(`/admin/reports/${reportId}`);
}

export function startReviewReport(reportId, version) {
  return apiRequest(`/admin/reports/${reportId}/review`, {
    method: "POST",
    body: { version },
  });
}

export function updateReportStatus(reportId, version, status, adminNote) {
  return apiRequest(`/admin/reports/${reportId}`, {
    method: "PATCH",
    body: { version, status, admin_note: adminNote },
  });
}

export function fetchUsers(page = 1, limit = 20, search = "") {
  const params = new URLSearchParams({ page, limit });
  if (search) params.append("search", search);
  return apiRequest(`/admin/users?${params.toString()}`);
}

export function getUser(userId) {
  return apiRequest(`/admin/users/${userId}`);
}

export function updateUserStatus(userId, isActive, reason) {
  return apiRequest(`/admin/users/${userId}`, {
    method: "PATCH",
    body: { is_active: isActive, reason },
  });
}

export function fetchModels() {
  return apiRequest("/admin/models");
}

export function deployModel(modelId, reason) {
  return apiRequest(`/admin/models/${modelId}/deploy`, { 
    method: "POST",
    body: { reason }
  });
}

export function dryRunModel(modelId) {
  return apiRequest(`/admin/models/${modelId}/dry-run`, { method: "POST" });
}

export function fetchAuditLogs({ page = 1, limit = 50, search, action, entity_type } = {}) {
  const params = new URLSearchParams({ page, limit });
  if (search) params.append("search", search);
  if (action && action !== "All") params.append("action", action);
  if (entity_type && entity_type !== "All") params.append("entity_type", entity_type);
  
  return apiRequest(`/admin/audit-logs?${params.toString()}`);
}

export function createExportJob(payload) {
  return apiRequest("/admin/dataset/export-jobs", {
    method: "POST",
    body: payload,
  });
}

export function fetchExportJobs({ page = 1, limit = 20 } = {}) {
  return apiRequest(`/admin/dataset/export-jobs?page=${page}&limit=${limit}`);
}

export function getExportJob(jobId) {
  return apiRequest(`/admin/dataset/export-jobs/${jobId}`);
}

export function cancelExportJob(jobId) {
  return apiRequest(`/admin/dataset/export-jobs/${jobId}/cancel`, { method: "POST" });
}

export function getExportDownloadUrl(jobId) {
  return `${API_BASE}/admin/dataset/export-jobs/${jobId}/download`;
}

export function getWebSocketUrl(path = "/admin/dashboard", token = "") {
  const customWsUrl = import.meta.env.VITE_WS_URL;
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  const queryParam = token ? `?token=${encodeURIComponent(token)}` : "";

  if (customWsUrl) {
    const base = customWsUrl.replace(/\/$/, "");
    return `${base}${cleanPath}${queryParam}`;
  }

  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${window.location.host}/api/v1/ws${cleanPath}${queryParam}`;
}

// Add these for profile logic
export function logoutAdmin() {
  return apiRequest("/admin/logout", { method: "POST", parse: "raw" }).finally(() => {
    clearAuth();
    window.location.replace("/login");
  });
}

export function fetchAdminProfile() {
  return apiRequest("/admin/me");
}

export function updateAdminProfile(data) {
  return apiRequest("/admin/me", { method: "PATCH", body: data });
}

export function fetchAdminSessions() {
  return apiRequest("/admin/sessions");
}

export function revokeAdminSession(sessionId) {
  return apiRequest(`/admin/sessions/${sessionId}/revoke`, { method: "POST" });
}