import { useQuery } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { auditLogListSchema } from '../../schemas/admin.js';

export function useAuditLogs({ page, limit, search, action, entity_type }) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (search) params.set('search', search);
  if (action) params.set('action', action);
  if (entity_type) params.set('entity_type', entity_type);
  return useQuery({
    queryKey: ['admin', 'audit-logs', { page, limit, search: search ?? '', action: action ?? '', entity_type: entity_type ?? '' }],
    queryFn: ({ signal }) =>
      apiRequest(`/admin/audit-logs?${params.toString()}`, { schema: auditLogListSchema, signal }),
    placeholderData: (prev) => prev,
  });
}
