import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { dashboardSchema, healthSchema, reportListSchema } from '../../schemas/admin.js';

export const dashboardKeys = {
  summary: ['admin', 'dashboard'],
  health: ['admin', 'health'],
  queue: ['admin', 'reports', 'pending-queue'],
};

export function useDashboardSummary() {
  return useQuery({
    queryKey: dashboardKeys.summary,
    queryFn: ({ signal }) => apiRequest('/admin/dashboard', { schema: dashboardSchema, signal }),
    refetchOnWindowFocus: true,
  });
}

export function useDashboardHealth() {
  return useQuery({
    queryKey: dashboardKeys.health,
    queryFn: ({ signal }) => apiRequest('/admin/health', { schema: healthSchema, signal }),
    refetchOnWindowFocus: false,
  });
}

export function usePendingQueue() {
  return useQuery({
    queryKey: dashboardKeys.queue,
    queryFn: ({ signal }) =>
      apiRequest('/admin/reports?status=pending&limit=100', { schema: reportListSchema, signal }),
    refetchOnWindowFocus: true,
  });
}

/**
 * Sort the pending queue: risk score desc, then oldest created first.
 * Reports without scan data go last. Placeholder retained for query-shape symmetry.
 */
export function sortQueue(items) {
  return [...items].sort((a, b) => {
    const scoreA = a.scan?.total_risk_score;
    const scoreB = b.scan?.total_risk_score;
    if (scoreA == null && scoreB == null) return compareTime(a.created_at, b.created_at);
    if (scoreA == null) return 1;
    if (scoreB == null) return -1;
    if (scoreB !== scoreA) return scoreB - scoreA;
    return compareTime(a.created_at, b.created_at);
  });
}

function compareTime(a, b) {
  return new Date(a).getTime() - new Date(b).getTime();
}

export function useReportCounts() {
  return useQuery({
    queryKey: ['admin', 'reports', 'counts'],
    queryFn: ({ signal }) =>
      apiRequest('/admin/reports?limit=1', { schema: reportListSchema, signal }),
    refetchOnWindowFocus: false,
    placeholderData: keepPreviousData,
  });
}
