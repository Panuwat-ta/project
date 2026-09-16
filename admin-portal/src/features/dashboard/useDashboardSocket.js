import { useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { buildAdminWsUrl, tokenStore } from '../../lib/api-client.js';
import { createDashboardSocket } from '../../lib/websocket.js';
import { dashboardKeys } from './dashboard-queries.js';

/**
 * Opens the admin dashboard socket while the shell is mounted.
 * On `refresh_dashboard` invalidates dashboard/health/queue/count queries
 * without touching scroll, focus, or filter state.
 * Returns 'live' | 'reconnecting' | 'offline'.
 */
export function useDashboardSocket() {
  const queryClient = useQueryClient();
  const [liveState, setLiveState] = useState('offline');

  useEffect(() => {
    const token = tokenStore.get();
    if (!token) {
      setLiveState('offline');
      return undefined;
    }
    setLiveState('reconnecting');
    const socket = createDashboardSocket({
      getUrl: () => {
        const current = tokenStore.get();
        return current ? buildAdminWsUrl(current) : null;
      },
      onEvent: (data) => {
        if (data.type !== 'refresh_dashboard') return;
        queryClient.invalidateQueries({ queryKey: dashboardKeys.summary });
        queryClient.invalidateQueries({ queryKey: dashboardKeys.health });
        queryClient.invalidateQueries({ queryKey: dashboardKeys.queue });
      },
      onStatus: (connected) => setLiveState(connected ? 'live' : 'reconnecting'),
    });
    return () => socket.close();
  }, [queryClient]);

  return liveState;
}
