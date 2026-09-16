import { lazy, Suspense } from 'react';
import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom';
import RouteFallback from '../components/ui/RouteFallback.jsx';
import AppShell from '../components/layout/AppShell.jsx';
import RootProviders from './RootProviders.jsx';
import LoginPage from '../features/auth/LoginPage.jsx';
import { RequireAuth, RequireAnonymous } from '../features/auth/RequireAuth.jsx';
import { useAuth } from '../features/auth/AuthContext.jsx';
import { ROUTES } from './route-config.js';

const DashboardPage = lazy(() => import('../features/dashboard/DashboardPage.jsx'));
const ReportsPage = lazy(() => import('../features/reports/ReportsPage.jsx'));
const ReportDetailPage = lazy(() => import('../features/reports/ReportDetailPage.jsx'));
const UsersPage = lazy(() => import('../features/users/UsersPage.jsx'));
const UserDetailPage = lazy(() => import('../features/users/UserDetailPage.jsx'));
const ModelsPage = lazy(() => import('../features/models/ModelsPage.jsx'));
const DatasetPage = lazy(() => import('../features/exports/DatasetPage.jsx'));
const AuditLogPage = lazy(() => import('../features/audit/AuditLogPage.jsx'));
const ProfilePage = lazy(() => import('../features/profile/ProfilePage.jsx'));

function LazyOutlet() {
  return (
    <Suspense fallback={<RouteFallback />}>
      <Outlet />
    </Suspense>
  );
}

/** Unknown route: dashboard when authenticated, login otherwise. */
function UnknownRoute() {
  const { status } = useAuth();
  if (status === 'loading') return <RouteFallback />;
  return <Navigate to={status === 'authenticated' ? ROUTES.dashboard : ROUTES.login} replace />;
}

export const router = createBrowserRouter([
  {
    element: <RootProviders />,
    children: [
      { path: '/', element: <Navigate to={ROUTES.dashboard} replace /> },
      {
        path: ROUTES.login,
        element: (
          <RequireAnonymous>
            <LoginPage />
          </RequireAnonymous>
        ),
      },
      {
        element: (
          <RequireAuth>
            <AppShell />
          </RequireAuth>
        ),
        children: [
          {
            element: <LazyOutlet />,
            children: [
              { path: ROUTES.dashboard, element: <DashboardPage /> },
              { path: ROUTES.reports, element: <ReportsPage /> },
              { path: ROUTES.reportDetail(), element: <ReportDetailPage /> },
              { path: ROUTES.users, element: <UsersPage /> },
              { path: ROUTES.userDetail(), element: <UserDetailPage /> },
              { path: ROUTES.models, element: <ModelsPage /> },
              { path: ROUTES.dataset, element: <DatasetPage /> },
              { path: ROUTES.auditLog, element: <AuditLogPage /> },
              { path: ROUTES.profile, element: <ProfilePage /> },
            ],
          },
        ],
      },
      { path: '*', element: <UnknownRoute /> },
    ],
  },
]);
