import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
import { Dashboard } from "@/pages/Dashboard";
import { ReportsList } from "@/pages/ReportsList";
import { ReportDetail } from "@/pages/ReportDetail";
import { DatasetExport } from "@/pages/DatasetExport";
import { Login } from "@/pages/Login";
import { UsersList } from "@/pages/UsersList";
import { UserDetail } from "@/pages/UserDetail";
import { ModelsList } from "@/pages/ModelsList";
import { AuditLogsList } from "@/pages/AuditLogsList";
import { ProfileSettings } from "@/pages/ProfileSettings";
import { useState, useEffect } from "react";
import { getAccessToken, isTokenExpired, clearAuth, refreshAccessToken } from "@/lib/api";

const ProtectedRoute = ({ children }) => {
  const [isReady, setIsReady] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      let token = getAccessToken();
      
      // If no token or expired, try silent refresh
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
    return <div className="min-h-screen flex items-center justify-center bg-gray-900 text-white">กำลังตรวจสอบสิทธิ์...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />
        
        <Route path="/admin" element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }>
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
      </Routes>
    </BrowserRouter>
  );
}

export default App;