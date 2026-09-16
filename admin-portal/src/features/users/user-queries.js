import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '../../lib/api-client.js';
import { userDetailSchema, userListSchema } from '../../schemas/admin.js';

export const userKeys = {
  lists: ['admin', 'users', 'list'],
  list: (params) => ['admin', 'users', 'list', params],
  details: ['admin', 'users', 'detail'],
  detail: (id) => ['admin', 'users', 'detail', id],
};

export function useUsers({ page, limit, search }) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (search) params.set('search', search);
  return useQuery({
    queryKey: userKeys.list({ page, limit, search: search ?? '' }),
    queryFn: ({ signal }) =>
      apiRequest(`/admin/users?${params.toString()}`, { schema: userListSchema, signal }),
    placeholderData: (prev) => prev,
  });
}

export function useUser(id) {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: ({ signal }) => apiRequest(`/admin/users/${id}`, { schema: userDetailSchema, signal }),
    enabled: id !== null && id !== undefined,
  });
}

/** Ban/unban with mandatory reason. Never optimistic. */
export function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, is_active, reason }) =>
      apiRequest(`/admin/users/${id}`, { method: 'PATCH', body: { is_active, reason } }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: userKeys.lists });
      queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) });
    },
  });
}
