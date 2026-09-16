import { API_BASE_URL } from './env.js';

/**
 * Normalized API error shared by every feature module.
 * @typedef {{status:number, message:string, detail?:unknown, requestId?:string|null, fieldErrors?:Record<string,string>, cause?:unknown}} NormalizedError
 */

export class ApiError extends Error {
  constructor({ status, message, detail, requestId, fieldErrors, cause }) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.detail = detail;
    this.requestId = requestId ?? null;
    this.fieldErrors = fieldErrors ?? null;
    this.cause = cause;
  }
}

export class AbortedRequestError extends Error {
  constructor() {
    super('Request aborted');
    this.name = 'AbortedRequestError';
  }
}

export function isAbortError(error) {
  return (
    error instanceof AbortedRequestError ||
    error?.name === 'AbortError' ||
    error?.code === 'ERR_CANCELED'
  );
}

// ---- In-memory access token. Never persisted to localStorage/sessionStorage. ----
let accessToken = null;
let onUnauthorized = null;

export const tokenStore = {
  get: () => accessToken,
  set: (token) => {
    accessToken = token;
  },
  clear: () => {
    accessToken = null;
  },
  /** Register a callback fired when the session is proven dead (refresh 401/403). */
  setUnauthorizedHandler: (fn) => {
    onUnauthorized = fn;
  },
};

// Single-flight refresh: concurrent 401s share exactly one refresh request.
let refreshPromise = null;

async function refreshAccessToken() {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      let response;
      try {
        response = await fetch(`${API_BASE_URL}/admin/refresh`, {
          method: 'POST',
          credentials: 'include',
        });
      } catch (cause) {
        // Network failure during refresh: surface as reconnect state, not logout.
        throw new ApiError({ status: 0, message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้', cause });
      }
      if (response.status === 401 || response.status === 403) {
        tokenStore.clear();
        if (onUnauthorized) onUnauthorized();
        const detail = await readBody(response).catch(() => null);
        throw new ApiError({ status: response.status, message: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง', detail });
      }
      if (!response.ok) {
        const detail = await readBody(response).catch(() => null);
        throw new ApiError({
          status: response.status,
          message: 'ต่ออายุเซสชันไม่สำเร็จ',
          detail,
        });
      }
      const data = await response.json();
      tokenStore.set(data.access_token ?? null);
      return data;
    })().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

async function readBody(response) {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function extractFieldErrors(detail) {
  // FastAPI 422 shape: { detail: [{ loc: [...], msg, type }] }
  if (!detail || typeof detail !== 'object' || !Array.isArray(detail.detail)) return null;
  const fieldErrors = {};
  for (const item of detail.detail) {
    if (item && Array.isArray(item.loc) && typeof item.msg === 'string') {
      const field = String(item.loc[item.loc.length - 1]);
      if (!(field in fieldErrors)) fieldErrors[field] = item.msg;
    }
  }
  return Object.keys(fieldErrors).length > 0 ? fieldErrors : null;
}

function errorMessageFor(status, body, fallback) {
  if (status === 0) return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
  if (status === 400) {
    if (typeof body?.detail === 'string') return body.detail;
    return 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบแล้วลองอีกครั้ง';
  }
  if (status === 403) {
    if (typeof body?.detail === 'string') return body.detail;
    return 'ไม่มีสิทธิ์ดำเนินการ หรือบัญชีถูกปิดใช้งาน';
  }
  if (status === 404) return 'ไม่พบข้อมูลที่ร้องขอ';
  if (status === 409) {
    if (typeof body?.detail === 'string') return body.detail;
    return 'ข้อมูลถูกแก้ไขโดยผู้อื่น กรุณาโหลดใหม่แล้วลองอีกครั้ง';
  }
  if (status === 429) return 'คำขอถี่เกินไป กรุณารอสักครู่แล้วลองอีกครั้ง';
  if (status >= 500) return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองอีกครั้ง';
  if (typeof body?.detail === 'string') return body.detail;
  return fallback;
}

/**
 * Core request helper. Every feature service uses this; page components never call fetch directly.
 *
 * @param {string} path path relative to API_BASE_URL (e.g. "/admin/dashboard")
 * @param {object} options
 * @param {string} [options.method] HTTP method
 * @param {unknown} [options.body] JSON-serializable body, URLSearchParams, or FormData
 * @param {import('zod').ZodTypeAny} [options.schema] Zod schema to validate a JSON response
 * @param {boolean} [options.auth] attach bearer token + 401 refresh flow (default true)
 * @param {boolean} [options.blob] return a Blob instead of parsing JSON
 * @param {AbortSignal} [options.signal]
 */
export async function apiRequest(path, options = {}) {
  const { method = 'GET', body, schema, auth = true, blob = false, signal } = options;

  const headers = {};
  let payload;
  if (body instanceof URLSearchParams) {
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    payload = body;
  } else if (body instanceof FormData) {
    payload = body;
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }

  const send = async (retryAllowed) => {
    if (auth && accessToken) headers.Authorization = `Bearer ${accessToken}`;
    else delete headers.Authorization;

    let response;
    try {
      response = await fetch(`${API_BASE_URL}${path}`, {
        method,
        headers,
        body: payload,
        credentials: 'include',
        signal,
      });
    } catch (error) {
      if (error?.name === 'AbortError') throw new AbortedRequestError();
      throw new ApiError({ status: 0, message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้', cause: error });
    }

    if (response.status === 401 && auth && retryAllowed) {
      await refreshAccessToken();
      return send(false);
    }

    const requestId =
      response.headers.get('x-request-id') ?? response.headers.get('x-requestid');

    if (blob) {
      if (!response.ok) {
        const detail = await readBody(response).catch(() => null);
        throw new ApiError({
          status: response.status,
          message: errorMessageFor(response.status, detail, 'ดาวน์โหลดไม่สำเร็จ'),
          detail,
          requestId,
        });
      }
      return { blob: await response.blob(), headers: response.headers };
    }

    const parsed = await readBody(response);
    if (!response.ok) {
      throw new ApiError({
        status: response.status,
        message: errorMessageFor(response.status, parsed, 'เกิดข้อผิดพลาด'),
        detail: parsed,
        requestId,
        fieldErrors: response.status === 422 ? extractFieldErrors(parsed) : null,
      });
    }

    if (schema) {
      const result = schema.safeParse(parsed);
      if (!result.success) {
        throw new ApiError({
          status: response.status,
          message: 'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง',
          detail: result.error.flatten(),
          requestId,
          cause: result.error,
        });
      }
      return result.data;
    }
    return parsed;
  };

  return send(true);
}

export function buildAdminWsUrl(token) {
  const explicit = import.meta.env?.VITE_WS_URL;
  if (explicit) return `${explicit.replace(/\/$/, '')}/admin/dashboard?token=${encodeURIComponent(token)}`;
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${protocol}//${window.location.host}/api/v1/ws/admin/dashboard?token=${encodeURIComponent(token)}`;
}
