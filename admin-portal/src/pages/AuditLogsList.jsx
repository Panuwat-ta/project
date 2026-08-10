import React, { useState, useEffect } from "react";

import { FileText, Clock, Search, ChevronLeft, ChevronRight, ChevronDown, ChevronUp } from "lucide-react";

import { fetchAuditLogs } from "@/lib/api";

export function AuditLogsList() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [entityTypeFilter, setEntityTypeFilter] = useState("All");
  const [expandedLogId, setExpandedLogId] = useState(null);

  const loadLogs = async () => {
    setLoading(true);
    try {
      const data = await fetchAuditLogs({ page, limit: 50, search, action: "All", entity_type: entityTypeFilter });
      setLogs(data.items || []);
      setTotalPages(data.total_pages || 1);
    } catch (error) {
      console.error("Failed to fetch audit logs", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search, entityTypeFilter]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    setPage(1);
    setSearch(searchInput);
  };

  const getActionColor = (action) => {
    if (action.includes("report_approved")) return "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/50";
    if (action.includes("report_rejected")) return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800/50";
    if (action.includes("user_banned")) return "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800/50";
    if (action.includes("user_unbanned")) return "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/50";
    if (action.includes("model_deployed")) return "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-800/50";
    if (action.includes("dataset_exported")) return "bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-400 border-violet-200 dark:border-violet-800/50";
    return "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700";
  };

  const renderActionBadge = (log) => (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getActionColor(log.action)}`}>
      {log.action}
    </span>
  );

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Audit Logs</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          บันทึกประวัติการทำรายการที่สำคัญโดยผู้ดูแลระบบ
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <FileText className="size-5 text-indigo-600 dark:text-indigo-400" />
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">System Audit Logs</h3>
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400">แสดงรายการประวัติการดำเนินการ (50 รายการ/หน้า)</p>
          </div>
          
          <form onSubmit={handleSearchSubmit} className="flex flex-col sm:flex-row items-center gap-3">
            <select
              value={entityTypeFilter}
              onChange={(e) => { setEntityTypeFilter(e.target.value); setPage(1); }}
              className="w-full sm:w-auto px-3 py-2 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            >
              <option value="All">All Types</option>
              <option value="report">Report</option>
              <option value="user">User</option>
              <option value="model">Model</option>
            </select>
            <div className="relative w-full sm:w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-slate-400" />
              <input
                type="text"
                placeholder="ค้นหารายละเอียด..."
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              />
            </div>
          </form>
        </div>

        {/* Desktop table */}
        <div className="hidden md:block flex-1 overflow-x-auto">
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
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <td colSpan="5" className="px-4 py-3">
                      <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบข้อมูล Audit Logs
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <React.Fragment key={log.id}>
                    <tr className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                      <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-xs">#{log.id}</td>
                      <td className="px-4 py-3 text-slate-900 dark:text-slate-100">Admin #{log.admin_id}</td>
                      <td className="px-4 py-3">{renderActionBadge(log)}</td>
                      <td className="px-4 py-3 max-w-[300px] truncate text-slate-600 dark:text-slate-400 flex items-center justify-between">
                        <span className="truncate">{log.details}</span>
                        {(log.before_state || log.after_state || log.reason) && (
                          <button 
                            onClick={() => setExpandedLogId(expandedLogId === log.id ? null : log.id)}
                            className="ml-2 p-1 text-slate-400 hover:text-indigo-600 bg-slate-100 dark:bg-slate-800 rounded"
                          >
                            {expandedLogId === log.id ? <ChevronUp className="size-4" /> : <ChevronDown className="size-4" />}
                          </button>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right text-slate-500 dark:text-slate-400 text-xs">
                        <div className="flex items-center justify-end gap-1.5">
                          <Clock className="size-3.5" />
                          {new Date(log.created_at).toLocaleString('th-TH')}
                        </div>
                      </td>
                    </tr>
                    {expandedLogId === log.id && (
                      <tr className="bg-slate-50/50 dark:bg-slate-800/30 border-b border-slate-100 dark:border-slate-800">
                        <td colSpan="5" className="px-4 py-3">
                          <div className="grid grid-cols-2 gap-4 text-xs font-mono">
                            {log.before_state && (
                              <div className="bg-red-50/50 dark:bg-red-900/10 p-3 rounded-md border border-red-100 dark:border-red-900/30">
                                <span className="font-semibold text-slate-500 block mb-1">Before:</span>
                                <pre className="whitespace-pre-wrap text-slate-700 dark:text-slate-300">
                                  {JSON.stringify(log.before_state, null, 2)}
                                </pre>
                              </div>
                            )}
                            {log.after_state && (
                              <div className="bg-emerald-50/50 dark:bg-emerald-900/10 p-3 rounded-md border border-emerald-100 dark:border-emerald-900/30">
                                <span className="font-semibold text-slate-500 block mb-1">After:</span>
                                <pre className="whitespace-pre-wrap text-slate-700 dark:text-slate-300">
                                  {JSON.stringify(log.after_state, null, 2)}
                                </pre>
                              </div>
                            )}
                            {log.reason && (
                              <div className="col-span-2 mt-2">
                                <span className="font-semibold text-slate-500">Reason: </span>
                                <span className="text-slate-700 dark:text-slate-300 font-sans">{log.reason}</span>
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Mobile card layout */}
        <div className="md:hidden flex flex-col divide-y divide-slate-200 dark:divide-slate-800">
          {loading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div key={`skeleton-m-${i}`} className="p-4">
                <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
              </div>
            ))
          ) : logs.length === 0 ? (
            <div className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">ไม่พบข้อมูล Audit Logs</div>
          ) : (
            logs.map((log) => (
              <div key={log.id} className="flex flex-col">
                <div className="p-4 flex flex-col gap-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-2 min-w-0">
                      <span className="font-mono text-slate-500 dark:text-slate-400 text-xs shrink-0">#{log.id}</span>
                      <span className="text-slate-900 dark:text-slate-100 text-sm">Admin #{log.admin_id}</span>
                    </div>
                    {renderActionBadge(log)}
                  </div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm text-slate-600 dark:text-slate-400 break-words flex-1">{log.details}</p>
                    {(log.before_state || log.after_state || log.reason) && (
                      <button 
                        onClick={() => setExpandedLogId(expandedLogId === log.id ? null : log.id)}
                        className="ml-2 p-1.5 text-slate-400 hover:text-indigo-600 bg-slate-100 dark:bg-slate-800 rounded-md shrink-0 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        aria-expanded={expandedLogId === log.id}
                        aria-label="Toggle details"
                      >
                        {expandedLogId === log.id ? <ChevronUp className="size-4" /> : <ChevronDown className="size-4" />}
                      </button>
                    )}
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 mt-1">
                    <Clock className="size-3.5" />
                    {new Date(log.created_at).toLocaleString('th-TH')}
                  </div>
                </div>

                {expandedLogId === log.id && (
                  <div className="px-4 pb-4 pt-1 bg-slate-50/50 dark:bg-slate-800/30">
                    <div className="flex flex-col gap-3 text-xs font-mono">
                      {log.before_state && (
                        <div className="bg-red-50/50 dark:bg-red-900/10 p-3 rounded-md border border-red-100 dark:border-red-900/30 overflow-x-auto">
                          <span className="font-semibold text-slate-500 block mb-1">Before:</span>
                          <pre className="text-slate-700 dark:text-slate-300">
                            {JSON.stringify(log.before_state, null, 2)}
                          </pre>
                        </div>
                      )}
                      {log.after_state && (
                        <div className="bg-emerald-50/50 dark:bg-emerald-900/10 p-3 rounded-md border border-emerald-100 dark:border-emerald-900/30 overflow-x-auto">
                          <span className="font-semibold text-slate-500 block mb-1">After:</span>
                          <pre className="text-slate-700 dark:text-slate-300">
                            {JSON.stringify(log.after_state, null, 2)}
                          </pre>
                        </div>
                      )}
                      {log.reason && (
                        <div className="mt-1">
                          <span className="font-semibold text-slate-500">Reason: </span>
                          <span className="text-slate-700 dark:text-slate-300 font-sans">{log.reason}</span>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
        
        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-5 py-3 flex items-center justify-between border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">
            <span className="text-sm text-slate-500 dark:text-slate-400">
              หน้า {page} จาก {totalPages}
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1 rounded-md text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
              >
                <ChevronLeft className="size-5" />
              </button>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1 rounded-md text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
              >
                <ChevronRight className="size-5" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}