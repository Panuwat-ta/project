import { describe, expect, it } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import { createElement } from 'react';
import { http } from 'msw';
import { ApiError, apiRequest, tokenStore } from '../../lib/api-client.js';
import { decisionSchema, userUpdateSchema } from '../../schemas/admin.js';
import { BASE, json } from '../../test/handlers.js';
import { server } from '../../test/server.js';
import { useDecideReport, useStartReview } from './report-queries.js';

function wrapper() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return function Wrapper({ children }) {
    return createElement(QueryClientProvider, { client }, children);
  };
}

describe('report flows', () => {
  it('รับเคสส่ง version ปัจจุบัน', async () => {
    tokenStore.set('valid-token');
    const { result } = renderHook(() => useStartReview(), { wrapper: wrapper() });
    const response = await result.current.mutateAsync({ id: 7, version: 3 });
    expect(response.status).toBe('reviewing');
  });

  it('review ไม่มี version ถูก backend ปฏิเสธ (400)', async () => {
    tokenStore.set('valid-token');
    await expect(apiRequest('/admin/reports/7/review', { method: 'POST', body: {} })).rejects.toMatchObject({
      status: 400,
    });
  });

  it('decision 409 เป็น ApiError (ให้ caller refetch + แสดง conflict, ห้าม retry อัตโนมัติ)', async () => {
    tokenStore.set('valid-token');
    server.use(
      http.patch(`${BASE}/admin/reports/7`, () => json({ detail: 'Version conflict' }, 409)),
    );
    const { result } = renderHook(() => useDecideReport(), { wrapper: wrapper() });
    const error = await result.current.mutateAsync({ id: 7, status: 'approved', version: 1, admin_note: 'ยืนยัน' }).catch((e) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error.status).toBe(409);
  });

  it('decision schema บังคับ audit note; ban schema บังคับ reason', () => {
    expect(decisionSchema.safeParse({ status: 'approved', admin_note: '' }).success).toBe(false);
    expect(decisionSchema.safeParse({ status: 'rejected', admin_note: 'ซ้ำซ้อน' }).success).toBe(true);
    expect(userUpdateSchema.safeParse({ is_active: false, reason: '' }).success).toBe(false);
    expect(userUpdateSchema.safeParse({ is_active: false, reason: 'สแปม' }).success).toBe(true);
  });

  it('waitFor sanity: mutation เสร็จภายใน timeout', async () => {
    tokenStore.set('valid-token');
    const { result } = renderHook(() => useStartReview(), { wrapper: wrapper() });
    result.current.mutate({ id: 7, version: 1 });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
  });
});
