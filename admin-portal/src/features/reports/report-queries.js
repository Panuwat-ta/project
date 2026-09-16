import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { reportDetailSchema, reportListSchema } from '../../schemas/admin.js';
import { dashboardKeys } from '../dashboard/dashboard-queries.js';

export const reportKeys = {
  lists: ['admin', 'reports', 'list'],
  list: (params) => ['admin', 'reports', 'list', params],
  details: ['admin', 'reports', 'detail'],
  detail: (id) => ['admin', 'reports', 'detail', id],
};

export function useReports({ page, limit, status, category, search }) {
  const params = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (status) params.set('status', status);
  if (category) params.set('category', category);
  if (search) params.set('search', search);
  const key = { page, limit, status: status ?? '', category: category ?? '', search: search ?? '' };
  return useQuery({
    queryKey: reportKeys.list(key),
    queryFn: ({ signal }) =>
      apiRequest(`/admin/reports?${params.toString()}`, { schema: reportListSchema, signal }),
    placeholderData: (prev) => prev,
  });
}

export function useReport(id) {
  return useQuery({
    queryKey: reportKeys.detail(id),
    queryFn: ({ signal }) => apiRequest(`/admin/reports/${id}`, { schema: reportDetailSchema, signal }),
    enabled: id !== null && id !== undefined,
  });
}

function invalidateReportScope(queryClient) {
  queryClient.invalidateQueries({ queryKey: dashboardKeys.summary });
  queryClient.invalidateQueries({ queryKey: dashboardKeys.queue });
  queryClient.invalidateQueries({ queryKey: reportKeys.lists });
  queryClient.invalidateQueries({ queryKey: reportKeys.details });
}

/** "รับเคส": pending -> reviewing. Never optimistic, invalidates dashboard + lists + detail. */
export function useStartReview() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, version }) =>
      apiRequest(`/admin/reports/${id}/review`, { method: 'POST', body: { version } }),
    onSuccess: () => invalidateReportScope(queryClient),
  });
}

/** Approve/reject decision with optimistic-lock version. Never optimistic, no auto-retry on 409. */
export function useDecideReport() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, version, admin_note }) =>
      apiRequest(`/admin/reports/${id}`, { method: 'PATCH', body: { status, version, admin_note } }),
    onSuccess: () => invalidateReportScope(queryClient),
  });
}
