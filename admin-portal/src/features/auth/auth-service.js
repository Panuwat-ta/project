import { apiRequest, tokenStore } from '../../lib/api-client.js';
import { adminProfileSchema } from '../../schemas/admin.js';

export async function loginAdmin({ username, password }) {
  const body = new URLSearchParams({ username, password });
  const data = await apiRequest('/admin/login', { method: 'POST', body, auth: false });
  tokenStore.set(data.access_token ?? null);
  return data;
}

export async function fetchMe(signal) {
  return apiRequest('/admin/me', { schema: adminProfileSchema, signal });
}

export async function logoutAdmin() {
  try {
    await apiRequest('/admin/logout', { method: 'POST' });
  } catch {
    // Logout proceeds even when the backend is unreachable.
  }
  tokenStore.clear();
}

export async function refreshSession() {
  const data = await apiRequest('/admin/refresh', { method: 'POST', auth: false });
  tokenStore.set(data.access_token ?? null);
  return data;
}
