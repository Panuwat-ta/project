import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { AbortedRequestError, ApiError, apiRequest, tokenStore } from './api-client.js';
import { dashboardSchema } from '../schemas/admin.js';
import { BASE, json } from '../test/handlers.js';
import { server } from '../test/server.js';

describe('api-client', () => {
  it('login ส่ง form-urlencoded และเก็บ token ใน memory เท่านั้น', async () => {
    let contentType = null;
    server.use(
      http.post(`${BASE}/admin/login`, async ({ request }) => {
        contentType = request.headers.get('content-type');
        return json({ access_token: 'valid-token', user: { id: 1 } });
      }),
    );
    const { loginAdmin } = await import('../features/auth/auth-service.js');
    await loginAdmin({ username: 'admin@scamguard.local', password: 'secret123' });
    expect(contentType).toContain('application/x-www-form-urlencoded');
    expect(tokenStore.get()).toBe('valid-token');
    expect(window.localStorage.length).toBe(0);
    expect(window.sessionStorage.length).toBe(0);
  });

  it('แนบ Authorization หลัง login', async () => {
    tokenStore.set('valid-token');
    const data = await apiRequest('/admin/me');
    expect(data.email).toBe('admin@scamguard.local');
  });

  it('401 พร้อมกันหลาย request ทำ refresh เพียงครั้งเดียวแล้ว retry สำเร็จ', async () => {
    tokenStore.set('expired-token');
    let refreshCount = 0;
    server.use(
      http.get(`${BASE}/admin/dashboard`, ({ request }) => {
        if (request.headers.get('authorization') === 'Bearer refreshed-token') {
          return json({ ok: true });
        }
        return json({ detail: 'expired' }, 401);
      }),
      http.post(`${BASE}/admin/refresh`, () => {
        refreshCount += 1;
        return json({ access_token: 'refreshed-token' });
      }),
    );
    const [a, b] = await Promise.all([apiRequest('/admin/dashboard'), apiRequest('/admin/dashboard')]);
    expect(a).toEqual({ ok: true });
    expect(b).toEqual({ ok: true });
    expect(refreshCount).toBe(1);
    expect(tokenStore.get()).toBe('refreshed-token');
  });

  it('refresh ล้มเหลว (401) ล้าง auth state และเรียก unauthorized handler', async () => {
    tokenStore.set('expired-token');
    const handler = vi.fn();
    tokenStore.setUnauthorizedHandler(handler);
    server.use(http.post(`${BASE}/admin/refresh`, () => json({ detail: 'Invalid' }, 401)));
    await expect(apiRequest('/admin/dashboard')).rejects.toMatchObject({ status: 401 });
    expect(tokenStore.get()).toBeNull();
    expect(handler).toHaveBeenCalledTimes(1);
    tokenStore.setUnauthorizedHandler(null);
  });

  it('abort request โยน AbortedRequestError (ไม่สร้าง toast)', async () => {
    tokenStore.set('valid-token');
    const controller = new AbortController();
    const pending = apiRequest('/admin/dashboard', { signal: controller.signal });
    controller.abort();
    await expect(pending).rejects.toBeInstanceOf(AbortedRequestError);
  });

  it('response ผิดรูปถูก Zod reject เป็น normalized error', async () => {
    tokenStore.set('valid-token');
    server.use(http.get(`${BASE}/admin/dashboard`, () => json({ totally: 'wrong' })));
    const error = await apiRequest('/admin/dashboard', { schema: dashboardSchema }).catch((e) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error.message).toBe('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
  });

  it('422 map validation error ลง field', async () => {
    tokenStore.set('valid-token');
    server.use(
      http.patch(`${BASE}/admin/reports/1`, () =>
        HttpResponse.json({ detail: [{ loc: ['body', 'admin_note'], msg: 'field required', type: 'missing' }] }, { status: 422 }),
      ),
    );
    const error = await apiRequest('/admin/reports/1', { method: 'PATCH', body: {} }).catch((e) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error.status).toBe(422);
    expect(error.fieldErrors).toEqual({ admin_note: 'field required' });
  });
});
