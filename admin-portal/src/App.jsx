import { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
import { Dashboard } from "@/pages/Dashboard";
import { ReportsList } from "@/pages/ReportsList";
import { ReportDetail } from "@/pages/ReportDetail";
import { UsersList } from "@/pages/UsersList";
import { UserDetail } from "@/pages/UserDetail";
import { ModelsList } from "@/pages/ModelsList";
import { DatasetExport } from "@/pages/DatasetExport";
import { AuditLogsList } from "@/pages/AuditLogsList";
import { ProfileSettings } from "@/pages/ProfileSettings";
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
        <p className="text-xs font-mono text-muted-foreground">กำลังตรวจสอบสิทธิ์ Super Admin...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
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
              <Route path="dashboard" element={<Dashboard />} />
              <Route path="reports" element={<ReportsList />} />
              <Route path="reports/:id" element={<ReportDetail />} />
              <Route path="users" element={<UsersList />} />
              <Route path="users/:id" element={<UserDetail />} />
              <Route path="models" element={<ModelsList />} />
              <Route path="dataset" element={<DatasetExport />} />
              <Route path="audit-log" element={<AuditLogsList />} />
              <Route path="profile" element={<ProfileSettings />} />
            </Route>

            <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </ThemeProvider>
  );
}

export default App;