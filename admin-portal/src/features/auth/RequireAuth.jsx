import { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import Skeleton from '../../components/ui/Skeleton.jsx';
import { ROUTES } from '../../app/route-config.js';
import { useAuth } from './AuthContext.jsx';

function AuthBootstrapSkeleton() {
  return (
    <div className="flex min-h-screen flex-col bg-app" role="status" aria-label="กำลังตรวจสอบเซสชัน">
      <div className="h-16 border-b border-line bg-surface" />
      <div className="flex flex-1">
        <div className="hidden w-[244px] shrink-0 border-r border-line bg-surface p-4 md:block" />
        <div className="flex-1 p-7">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="mt-4 h-4 w-96" />
          <div className="mt-6 grid grid-cols-4 gap-4">
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
          </div>
          <Skeleton className="mt-6 h-64 w-full" />
        </div>
      </div>
    </div>
  );
}

export function RequireAuth({ children }) {
  const { status, rememberIntended } = useAuth();
  const location = useLocation();
  const fullPath = `${location.pathname}${location.search}`;

  useEffect(() => {
    if (status === 'anonymous' && fullPath !== ROUTES.login) rememberIntended(fullPath);
  }, [status, fullPath, rememberIntended]);

  if (status === 'loading') return <AuthBootstrapSkeleton />;
  if (status === 'anonymous') return <Navigate to={ROUTES.login} replace />;
  return children;
}

export function RequireAnonymous({ children }) {
  const { status } = useAuth();
  if (status === 'loading') return <AuthBootstrapSkeleton />;
  if (status === 'authenticated') return <Navigate to={ROUTES.dashboard} replace />;
  return children;
}
