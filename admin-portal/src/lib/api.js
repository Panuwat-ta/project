// Unified API layer - จุดศูนย์กลางของ API calls + Token management + Global error handling

const API_BASE = "/api/v1";

const TOKEN_KEY = "token";
const REFRESH_KEY = "refresh_token";
const USER_KEY = "user";

// --- Token helpers ---

export function getAccessToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_KEY);
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

export function setAuth(accessToken, refreshToken, user) {
  localStorage.setItem(TOKEN_KEY, accessToken);
  if (refreshToken) {
    localStorage.setItem(REFRESH_KEY, refreshToken);
  }
  if (user) {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
}

export function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
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

export function isTokenExpired(token, leewaySeconds = 10) {
  if (!token) return true;
  const payload = decodeJwt(token);
  if (!payload || !payload.exp) return true;
  return Date.now() >= (payload.exp - leewaySeconds) * 1000;
}

// --- Global error handling / redirect ---

let refreshPromise = null;

async function refreshAccessToken() {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    const refreshToken = getRefreshToken();
    if (!refreshToken) throw new Error("No refresh token available");

    const res = await fetch(`${API_BASE}/admin/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
    if (!res.ok) throw new Error("Refresh token failed");

    const data = await res.json();
    setAuth(data.access_token, data.refresh_token || refreshToken, data.user || getStoredUser());
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
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  };

  let res = await finalize(getAccessToken());

  // 401 -> try to refresh token once, then retry
  if (res.status === 401 && needsAuth && getRefreshToken()) {
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
  setAuth(data.access_token, data.refresh_token, data.user);
  return data;
}

export function fetchDashboard() {
  return apiRequest("/admin/dashboard");
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

export function updateReportStatus(reportId, decision) {
  return apiRequest(`/admin/reports/${reportId}`, {
    method: "PATCH",
    body: decision,
  });
}

export function fetchUsers(page = 1, limit = 20) {
  return apiRequest(`/admin/users?${new URLSearchParams({ page, limit })}`);
}

export function updateUserStatus(userId, isActive) {
  return apiRequest(`/admin/users/${userId}`, {
    method: "PATCH",
    body: { is_active: isActive },
  });
}

export function fetchModels() {
  return apiRequest("/admin/models");
}

export function deployModel(modelId) {
  return apiRequest(`/admin/models/${modelId}/deploy`, { method: "POST" });
}

export function fetchAuditLogs(page = 1, limit = 50) {
  return apiRequest(`/admin/audit-logs?${new URLSearchParams({ page, limit })}`);
}

export function exportDataset(payload) {
  return apiRequest("/admin/dataset/export", {
    method: "POST",
    body: payload,
    parse: "blob",
  });
}