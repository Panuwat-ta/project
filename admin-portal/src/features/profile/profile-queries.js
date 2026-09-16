import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { adminProfileSchema, adminSessionListSchema } from '../../schemas/admin.js';

export const profileKeys = {
  me: ['admin', 'me'],
  sessions: ['admin', 'sessions'],
};

export function useMe() {
  return useQuery({
    queryKey: profileKeys.me,
    queryFn: ({ signal }) => apiRequest('/admin/me', { schema: adminProfileSchema, signal }),
  });
}

export function useUpdateProfile() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => apiRequest('/admin/me', { method: 'PATCH', body: payload, schema: adminProfileSchema }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: profileKeys.me }),
  });
}

export function useSessions() {
  return useQuery({
    queryKey: profileKeys.sessions,
    queryFn: ({ signal }) => apiRequest('/admin/sessions', { schema: adminSessionListSchema, signal }),
  });
}

export function useRevokeSession() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id }) => apiRequest(`/admin/sessions/${id}/revoke`, { method: 'POST' }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: profileKeys.sessions }),
  });
}
