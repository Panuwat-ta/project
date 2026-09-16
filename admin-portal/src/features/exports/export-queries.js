import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { exportJobListSchema, exportJobSchema } from '../../schemas/admin.js';
import { getFilenameFromDisposition } from '../../lib/utils.js';

export const exportKeys = {
  lists: ['admin', 'exports', 'list'],
  list: (params) => ['admin', 'exports', 'list', params],
  details: ['admin', 'exports', 'detail'],
  detail: (id) => ['admin', 'exports', 'detail', id],
};

export function useExportJobs({ page, limit }) {
  return useQuery({
    queryKey: exportKeys.list({ page, limit }),
    queryFn: ({ signal }) =>
      apiRequest(`/admin/dataset/export-jobs?page=${page}&limit=${limit}`, {
        schema: exportJobListSchema,
        signal,
      }),
    placeholderData: (prev) => prev,
  });
}

const ACTIVE = new Set(['queued', 'running', 'pending', 'processing']);

/** Polls every 2s only while the job is active; stops at a final state. */
export function useExportJob(id, enabled = true) {
  return useQuery({
    queryKey: exportKeys.detail(id),
    queryFn: ({ signal }) =>
      apiRequest(`/admin/dataset/export-jobs/${id}`, { schema: exportJobSchema, signal }),
    enabled: enabled && id !== null && id !== undefined,
    refetchInterval: (query) => (query.state.data && ACTIVE.has(query.state.data.status) ? 2000 : false),
    refetchIntervalInBackground: false,
  });
}

export function isJobActive(status) {
  return ACTIVE.has(String(status));
}

export function useCreateExportJob() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) =>
      apiRequest('/admin/dataset/export-jobs', { method: 'POST', body: payload, schema: exportJobSchema }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: exportKeys.lists }),
  });
}

export function useCancelExportJob() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id }) => apiRequest(`/admin/dataset/export-jobs/${id}/cancel`, { method: 'POST' }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: exportKeys.lists });
      queryClient.invalidateQueries({ queryKey: exportKeys.detail(variables.id) });
    },
  });
}

export async function downloadExportJob(id) {
  const { blob, headers } = await apiRequest(`/admin/dataset/export-jobs/${id}/download`, { blob: true });
  const filename =
    getFilenameFromDisposition(headers.get('content-disposition')) ?? `export-${id}.zip`;
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
  return filename;
}
