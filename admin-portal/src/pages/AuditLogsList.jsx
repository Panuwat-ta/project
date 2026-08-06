import { useState, useEffect } from "react";

import { FileText, Clock } from "lucide-react";

export function AuditLogsList() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadLogs = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch("/api/v1/admin/audit-logs", {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setLogs(data.items || []);
      }
    } catch (error) {
      console.error("Failed to fetch audit logs", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, []);

  if (loading) return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded-md w-48 animate-pulse mb-2"></div>
        <div className="h-4 bg-slate-100 dark:bg-slate-800/50 rounded-md w-64 animate-pulse"></div>
      </div>
      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <div className="h-5 bg-slate-200 dark:bg-slate-800 rounded-md w-40 animate-pulse mb-2"></div>
          <div className="h-4 bg-slate-100 dark:bg-slate-800/50 rounded-md w-64 animate-pulse"></div>
        </div>
        <div className="p-4 space-y-4">
          {[1, 2, 3, 4, 5].map((i) => (
            <div key={i} className="h-12 bg-slate-50 dark:bg-slate-800/20 rounded-md w-full animate-pulse"></div>
          ))}
        </div>
      </div>
    </div>
  );

  const getActionColor = (action) => {
    if (action.includes("report_approved")) return "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/50";
    if (action.includes("report_rejected")) return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800/50";
    if (action.includes("user_banned")) return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800/50";
    if (action.includes("user_unbanned")) return "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/50";
    if (action.includes("model_deployed")) return "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-800/50";
    return "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700";
  };

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Audit Logs</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          บันทึกประวัติการทำรายการที่สำคัญโดยผู้ดูแลระบบ
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2 mb-1">
            <FileText className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">System Audit Logs</h3>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">แสดงรายการประวัติการดำเนินการ 50 รายการล่าสุด</p>
        </div>
        
        <div className="flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">Log ID</th>
                <th className="px-4 py-3 font-medium">Admin ID</th>
                <th className="px-4 py-3 font-medium">การดำเนินการ (Action)</th>
                <th className="px-4 py-3 font-medium">รายละเอียด</th>
                <th className="px-4 py-3 font-medium text-right">เวลา</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
              {logs.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบประวัติการทำรายการ
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-xs">#{log.id}</td>
                    <td className="px-4 py-3 text-slate-900 dark:text-slate-100">Admin #{log.admin_id}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getActionColor(log.action)}`}>
                        {log.action}
                      </span>
                    </td>
                    <td className="px-4 py-3 max-w-[300px] truncate text-slate-600 dark:text-slate-400">
                      {log.details}
                    </td>
                    <td className="px-4 py-3 text-right text-slate-500 dark:text-slate-400 text-xs">
                      <div className="flex items-center justify-end gap-1.5">
                        <Clock className="size-3.5" />
                        {new Date(log.created_at).toLocaleString('th-TH')}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
