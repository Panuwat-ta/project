import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
import { Dashboard } from "@/pages/Dashboard";
import { ReportsList } from "@/pages/ReportsList";
import { Login } from "@/pages/Login";
import { UsersList } from "@/pages/UsersList";
import { ModelsList } from "@/pages/ModelsList";
import { AuditLogsList } from "@/pages/AuditLogsList";

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('token');
  if (!token) {
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
          <Route path="users" element={<UsersList />} />
          <Route path="models" element={<ModelsList />} />
          <Route path="dataset" element={<div className="p-4"><h2>Dataset Export Placeholder</h2></div>} />
          <Route path="audit-log" element={<AuditLogsList />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
