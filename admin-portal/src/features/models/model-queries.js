import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { dryRunSchema, modelListSchema } from '../../schemas/admin.js';
import { dashboardKeys } from '../dashboard/dashboard-queries.js';

export const modelKeys = {
  list: ['admin', 'models'],
};

export function useModels() {
  return useQuery({
    queryKey: modelKeys.list,
    queryFn: ({ signal }) => apiRequest('/admin/models', { schema: modelListSchema, signal }),
  });
}

/** Deploy a version with mandatory reason. Never optimistic, no auto-retry. */
export function useDeployModel() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }) =>
      apiRequest(`/admin/models/${id}/deploy`, { method: 'POST', body: { reason } }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: modelKeys.list });
      queryClient.invalidateQueries({ queryKey: dashboardKeys.summary });
    },
  });
}

export function useDryRunModel() {
  return useMutation({
    mutationFn: ({ id }) => apiRequest(`/admin/models/${id}/dry-run`, { method: 'POST', schema: dryRunSchema }),
  });
}
