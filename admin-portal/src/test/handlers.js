import { http, HttpResponse } from 'msw';

export const BASE = '/api/v1';

export function json(data, status = 200) {
  return HttpResponse.json(data, { status });
}

function requireAuth(request) {
  const header = request.headers.get('authorization') ?? '';
  if (header === 'Bearer valid-token' || header === 'Bearer refreshed-token') return null;
  return json({ detail: 'Not authenticated' }, 401);
}

const dashboardFixture = {
  overview: {
    total_users: 120,
    active_users_today: 9,
    total_scans: 1500,
    scans_today: 132,
    scans_this_week: 841,
    scans_this_month: 1204,
  },
  risk_distribution: { high: 9, medium: 21, low: 34 },
  reports: { total: 40, pending: 18, reviewing: 6, approved: 10, rejected: 6 },
  category_breakdown: { fake_slip: 12, investment: 8 },
  model: {
    active_version: 'v1.0.4',
    deployed_at: '2026-09-12T09:41:00+07:00',
    total_versions: 5,
    a_acc: 0.94,
    m_iou: 0.87,
    m_acc: null,
    m_dice: 0.89,
  },
  scan_trend: [
    { date: '2026-09-10', count: 80 },
    { date: '2026-09-11', count: 95 },
  ],
};

export const handlers = [
  http.post(`${BASE}/admin/login`, async ({ request }) => {
    const text = await request.text();
    const params = new URLSearchParams(text);
    if (params.get('username') === 'admin@scamguard.local' && params.get('password') === 'secret123') {
      return json({
        access_token: 'valid-token',
        user: { id: 1, email: 'admin@scamguard.local', full_name: 'Admin', role: 'admin', is_superadmin: true },
      });
    }
    return json({ detail: 'Incorrect email or password' }, 401);
  }),

  http.post(`${BASE}/admin/refresh`, ({ cookies }) => {
    if (cookies.admin_refresh_token === 'bad') return json({ detail: 'Invalid' }, 401);
    return json({
      access_token: 'refreshed-token',
      user: { id: 1, email: 'admin@scamguard.local', full_name: 'Admin', role: 'admin', is_superadmin: true },
    });
  }),

  http.post(`${BASE}/admin/logout`, () => json({ message: 'ออกจากระบบแล้ว' })),

  http.get(`${BASE}/admin/me`, ({ request }) => {
    const denied = requireAuth(request);
    if (denied) return denied;
    return json({ id: 1, email: 'admin@scamguard.local', full_name: 'Admin', role: 'admin', is_superadmin: true });
  }),

  http.get(`${BASE}/admin/dashboard`, ({ request }) => {
    const denied = requireAuth(request);
    if (denied) return denied;
    return json(dashboardFixture);
  }),

  http.get(`${BASE}/admin/health`, ({ request }) => {
    const denied = requireAuth(request);
    if (denied) return denied;
    return json({ database: 'ok', storage: 'ok', models: 'ok', queue: 'ok', last_check: '2026-09-16T10:00:00+07:00' });
  }),

  http.get(`${BASE}/admin/reports`, ({ request }) => {
    const denied = requireAuth(request);
    if (denied) return denied;
    return json({ items: [], total: 0, page: 1, limit: 20 });
  }),

  http.post(`${BASE}/admin/reports/:id/review`, async ({ request }) => {
    const denied = requireAuth(request);
    if (denied) return denied;
    const body = await request.json();
    if (body.version === undefined || body.version === null) {
      return json({ detail: 'version is required' }, 400);
    }
    return json({ id: 1, status: 'reviewing', version: 2, message: 'เริ่มตรวจสอบรายงาน' });
  }),
];
