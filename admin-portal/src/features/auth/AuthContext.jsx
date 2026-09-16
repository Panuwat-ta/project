import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ApiError, isAbortError, tokenStore } from '../../lib/api-client.js';
import { queryClient } from '../../lib/query-client.js';
import { ROUTES } from '../../app/route-config.js';
import { fetchMe, loginAdmin, logoutAdmin, refreshSession } from './auth-service.js';

const AuthContext = createContext(null);

// Module-level single-flight bootstrap: duplicate mounts (e.g. StrictMode double
// effects) share one refresh instead of rotating the backend session twice.
let bootstrapPromise = null;

function runBootstrap() {
  if (!bootstrapPromise) {
    bootstrapPromise = (async () => {
      await refreshSession();
      return fetchMe();
    })().finally(() => {
      bootstrapPromise = null;
    });
  }
  return bootstrapPromise;
}

export function AuthProvider({ children }) {
  const [status, setStatus] = useState('loading');
  const [user, setUser] = useState(null);
  const [intendedPath, setIntendedPath] = useState(ROUTES.dashboard);
  const navigate = useNavigate();
  const mounted = useRef(true);

  const doLogout = useCallback(
    async (redirect = true) => {
      await logoutAdmin();
      queryClient.clear();
      if (!mounted.current) return;
      setUser(null);
      setStatus('anonymous');
      if (redirect) navigate(ROUTES.login, { replace: true });
    },
    [navigate],
  );

  useEffect(() => {
    mounted.current = true;
    tokenStore.setUnauthorizedHandler(() => {
      doLogout(true);
    });
    // Bootstrap: attempt cookie refresh so returning admins skip login.
    const controller = new AbortController();
    (async () => {
      try {
        const me = await runBootstrap();
        if (controller.signal.aborted || !mounted.current) return;
        setUser(me);
        setStatus('authenticated');
      } catch (error) {
        if (!mounted.current || isAbortError(error)) return;
        if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
          tokenStore.clear();
          setStatus('anonymous');
          return;
        }
        // Network failure during bootstrap: stay anonymous so the user can log in.
        setStatus('anonymous');
      }
    })();
    return () => {
      mounted.current = false;
      controller.abort();
      tokenStore.setUnauthorizedHandler(null);
    };
  }, [doLogout]);

  const login = useCallback(
    async ({ username, password }) => {
      const data = await loginAdmin({ username, password });
      try {
        const me = await fetchMe();
        setUser(me);
      } catch {
        setUser(data.user ?? null);
      }
      setStatus('authenticated');
      const target = intendedPath && intendedPath !== ROUTES.login ? intendedPath : ROUTES.dashboard;
      setIntendedPath(ROUTES.dashboard);
      navigate(target, { replace: true });
    },
    [navigate, intendedPath],
  );

  const value = useMemo(
    () => ({
      status,
      user,
      isAuthenticated: status === 'authenticated',
      isBootstrapping: status === 'loading',
      login,
      logout: () => doLogout(true),
      intendedPath,
      rememberIntended: (path) => setIntendedPath(path),
    }),
    [status, user, login, doLogout, intendedPath],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
