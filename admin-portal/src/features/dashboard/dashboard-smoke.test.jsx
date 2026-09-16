import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { createElement } from 'react';
import { MemoryRouter } from 'react-router-dom';
import { tokenStore } from '../../lib/api-client.js';
import { ToastProvider } from '../../components/ui/Toast.jsx';
import DashboardPage from './DashboardPage.jsx';

function renderDashboard() {
  tokenStore.set('valid-token');
  const client = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    createElement(
      QueryClientProvider,
      { client },
      createElement(
        ToastProvider,
        null,
        createElement(MemoryRouter, null, createElement(DashboardPage)),
      ),
    ),
  );
}

describe('dashboard smoke', () => {
  it('แสดง header, KPI, signal map, คิว และ rail ครบจากข้อมูลจริงรูป', async () => {
    renderDashboard();
    expect(await screen.findByRole('heading', { name: 'คิวตรวจสอบความเสี่ยง' })).toBeInTheDocument();
    expect(await screen.findByText('รอตรวจสอบ')).toBeInTheDocument();
    expect(await screen.findByText('แผนที่สัญญาณการสแกน')).toBeInTheDocument();
    expect(await screen.findByText('คิวรอดำเนินการ')).toBeInTheDocument();
    expect(await screen.findByText('การกระจายความเสี่ยง')).toBeInTheDocument();
    expect(await screen.findByText('สุขภาพระบบ')).toBeInTheDocument();
    expect(await screen.findByText('โมเดลที่ใช้งาน')).toBeInTheDocument();
  });

  it('คิวว่างแสดง empty state แทนตาราง', async () => {
    renderDashboard();
    expect(await screen.findByText('ยังไม่มีรายงานรอตรวจ')).toBeInTheDocument();
  });
});
