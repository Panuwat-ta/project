import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { http } from 'msw';
import { AuthProvider } from './AuthContext.jsx';
import LoginPage from './LoginPage.jsx';
import { RequireAuth } from './RequireAuth.jsx';
import { BASE, json } from '../../test/handlers.js';
import { server } from '../../test/server.js';

function renderAt(path, element) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <AuthProvider>
        <Routes>
          <Route path="/admin/dashboard" element={element} />
          <Route path="/login" element={<LoginPage />} />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe('auth routing', () => {
  it('ผู้ใช้ที่ยังไม่ login ถูกส่งไป /login (ไม่ render หน้าป้องกันก่อน bootstrap จบ)', async () => {
    server.use(http.post(`${BASE}/admin/refresh`, () => json({ detail: 'missing' }, 401)));
    renderAt('/admin/dashboard', <RequireAuth><div>secret-content</div></RequireAuth>);
    // ระหว่าง bootstrap ต้องไม่เห็นทั้ง login และเนื้อหา
    expect(screen.queryByText('secret-content')).not.toBeInTheDocument();
    expect(await screen.findByText('เข้าสู่ระบบผู้ดูแล')).toBeInTheDocument();
  });

  it('login สำเร็จกลับไป route เดิม', async () => {
    server.use(http.post(`${BASE}/admin/refresh`, () => json({ detail: 'missing' }, 401)));
    const user = userEvent.setup();
    renderAt('/login', <RequireAuth><div>secret-content</div></RequireAuth>);
    await screen.findByText('เข้าสู่ระบบผู้ดูแล');
    // Dev prefill (.env) อาจเติมค่าไว้ก่อน: ล้างแล้วพิมพ์ค่าเทส
    await user.clear(screen.getByLabelText('อีเมลผู้ดูแล'));
    await user.clear(screen.getByLabelText('รหัสผ่าน'));
    await user.type(screen.getByLabelText('อีเมลผู้ดูแล'), 'admin@scamguard.local');
    await user.type(screen.getByLabelText('รหัสผ่าน'), 'secret123');
    await user.click(screen.getByRole('button', { name: 'เข้าสู่ระบบ' }));
    expect(await screen.findByText('secret-content')).toBeInTheDocument();
  });

  it('ฟอร์ม login ว่างแสดง validation error และไม่ยิง request', async () => {
    let calls = 0;
    server.use(
      http.post(`${BASE}/admin/refresh`, () => json({ detail: 'missing' }, 401)),
      http.post(`${BASE}/admin/login`, () => {
        calls += 1;
        return json({ access_token: 'x' });
      }),
    );
    const user = userEvent.setup();
    render(
      <MemoryRouter initialEntries={['/login']}>
        <AuthProvider>
          <LoginPage />
        </AuthProvider>
      </MemoryRouter>,
    );
    await screen.findByText('เข้าสู่ระบบผู้ดูแล');
    await user.clear(screen.getByLabelText('อีเมลผู้ดูแล'));
    await user.clear(screen.getByLabelText('รหัสผ่าน'));
    await user.click(screen.getByRole('button', { name: 'เข้าสู่ระบบ' }));
    expect(await screen.findByText('กรุณากรอกอีเมลผู้ดูแล')).toBeInTheDocument();
    expect(calls).toBe(0);
  });
});
