import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
import { Dashboard } from "@/pages/Dashboard";
import { ReportsList } from "@/pages/ReportsList";
import { ReportDetail } from "@/pages/ReportDetail";
import { DatasetExport } from "@/pages/DatasetExport";
import { Login } from "@/pages/Login";
import { UsersList } from "@/pages/UsersList";
import { ModelsList } from "@/pages/ModelsList";
import { AuditLogsList } from "@/pages/AuditLogsList";
import { getAccessToken, isTokenExpired, clearAuth } from "@/lib/api";

const ProtectedRoute = ({ children }) => {
  const token = getAccessToken();

  // เช็คว่า Token หมดอายุหรือยัง ถ้าหมดอายุให้กลับไปหน้า Login
  if (!token || isTokenExpired(token)) {
    clearAuth();
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
          <Route path="models" element={<ModelsList />} />
          <Route path="dataset" element={<DatasetExport />} />
          <Route path="audit-log" element={<AuditLogsList />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;