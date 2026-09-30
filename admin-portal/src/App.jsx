import { lazy, Suspense, useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
const Dashboard = lazy(() => import("@/pages/Dashboard").then((m) => ({ default: m.Dashboard })));
const ReportsList = lazy(() => import("@/pages/ReportsList").then((m) => ({ default: m.ReportsList })));
const ReportDetail = lazy(() => import("@/pages/ReportDetail").then((m) => ({ default: m.ReportDetail })));
const UsersList = lazy(() => import("@/pages/UsersList").then((m) => ({ default: m.UsersList })));
const UserDetail = lazy(() => import("@/pages/UserDetail").then((m) => ({ default: m.UserDetail })));
const ModelsList = lazy(() => import("@/pages/ModelsList").then((m) => ({ default: m.ModelsList })));
const DatasetExport = lazy(() => import("@/pages/DatasetExport").then((m) => ({ default: m.DatasetExport })));
const AuditLogsList = lazy(() => import("@/pages/AuditLogsList").then((m) => ({ default: m.AuditLogsList })));
const ProfileSettings = lazy(() => import("@/pages/ProfileSettings").then((m) => ({ default: m.ProfileSettings })));
import { Login } from "@/pages/Login";
import { ThemeProvider } from "@/components/theme-provider";
import { ToastProvider } from "@/components/ui/ToastContext";
import { getAccessToken, isTokenExpired, clearAuth, refreshAccessToken } from "@/lib/api";
import { Shield } from "lucide-react";

function ProtectedRoute({ children }) {
  const [isReady, setIsReady] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      let token = getAccessToken();

      // If no token in memory or expired, try silent refresh
      if (!token || isTokenExpired(token)) {
        try {
          token = await refreshAccessToken();
        } catch {
          clearAuth();
          setIsAuthenticated(false);
          setIsReady(true);
          return;
        }
      }

      setIsAuthenticated(true);
      setIsReady(true);
    };
    checkAuth();
  }, []);

  if (!isReady) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-background text-foreground gap-3">
        <div className="size-10 rounded-xl bg-primary-subtle border border-primary-border flex items-center justify-center text-primary animate-pulse">
          <Shield className="size-5" />
        </div>
        <p className="text-sm text-muted-foreground">กำลังตรวจสอบสิทธิ์ผู้ดูแลระบบ...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
}

function PageLoading() {
  return (
    <div className="min-h-[40vh] flex items-center justify-center text-foreground">
      <div className="flex items-center gap-3 text-sm text-muted-foreground">
        <div className="size-2 rounded-full bg-primary animate-pulse" />
        <span>กำลังโหลด...</span>
      </div>
    </div>
  );
}

function LazyRoute({ children }) {
  return <Suspense fallback={<PageLoading />}>{children}</Suspense>;
}

function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="scamguard-admin-theme">
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />

            <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />

            <Route
              path="/admin"
              element={
                <ProtectedRoute>
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route path="dashboard" element={<LazyRoute><Dashboard /></LazyRoute>} />
              <Route path="reports" element={<LazyRoute><ReportsList /></LazyRoute>} />
              <Route path="reports/:id" element={<LazyRoute><ReportDetail /></LazyRoute>} />
              <Route path="users" element={<LazyRoute><UsersList /></LazyRoute>} />
              <Route path="users/:id" element={<LazyRoute><UserDetail /></LazyRoute>} />
              <Route path="models" element={<LazyRoute><ModelsList /></LazyRoute>} />
              <Route path="dataset" element={<LazyRoute><DatasetExport /></LazyRoute>} />
              <Route path="audit-log" element={<LazyRoute><AuditLogsList /></LazyRoute>} />
              <Route path="profile" element={<LazyRoute><ProfileSettings /></LazyRoute>} />
            </Route>

            <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </ThemeProvider>
  );
}

export default App;