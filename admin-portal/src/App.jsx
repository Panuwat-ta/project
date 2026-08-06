import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminLayout } from "@/layouts/AdminLayout";
import { Dashboard } from "@/pages/Dashboard";
import { ReportsList } from "@/pages/ReportsList";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />
        
        <Route path="/admin" element={<AdminLayout />}>
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="reports" element={<ReportsList />} />
          <Route path="users" element={<div className="p-4"><h2>User Management Placeholder</h2></div>} />
          <Route path="models" element={<div className="p-4"><h2>AI Models Placeholder</h2></div>} />
          <Route path="dataset" element={<div className="p-4"><h2>Dataset Export Placeholder</h2></div>} />
          <Route path="audit-log" element={<div className="p-4"><h2>Audit Log Placeholder</h2></div>} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
