import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Filter, Eye, ChevronLeft, ChevronRight } from "lucide-react";

import { fetchReports } from "@/lib/api";

const LIMIT = 10;

const STATUS_TABS = ["All", "Pending", "Reviewing", "Approved", "Rejected"];

const CATEGORIES = [
  { key: "All", label: "ทั้งหมด" },
  { key: "romance_scam", label: "หลอกลวงความรัก" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์" },
  { key: "fake_slip", label: "สลิปปลอม" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ" },
];

export function ReportsList() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("All");
  const [category, setCategory] = useState("All");
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [page, setPage] = useState(1);
  const [isLoading, setIsLoading] = useState(true);
  const [reportsData, setReportsData] = useState([]);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState("");
  const searchTimer = useRef(null);

  useEffect(() => {
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      setDebouncedSearch(search.trim());
      setPage(1);
    }, 350);
    return () => clearTimeout(searchTimer.current);
  }, [search]);

  useEffect(() => {
    async function loadReports() {
      setIsLoading(true);
      setError("");
      try {
        const data = await fetchReports({
          page,
          limit: LIMIT,
          status: activeTab,
          category,
          search: debouncedSearch,
        });
        setReportsData(data.items);
        setTotal(data.total);
      } catch (err) {
        setError(err.message);
        setReportsData([]);
        setTotal(0);
      } finally {
        setIsLoading(false);
      }
    }
    loadReports();
  }, [activeTab, category, debouncedSearch, page]);

  const totalPages = Math.max(1, Math.ceil(total / LIMIT));
  const rangeStart = total === 0 ? 0 : (page - 1) * LIMIT + 1;
  const rangeEnd = Math.min(page * LIMIT, total);

  const PAGE_WINDOW = 5;
  let startPage = Math.max(1, page - Math.floor(PAGE_WINDOW / 2));
  let endPage = Math.min(totalPages, startPage + PAGE_WINDOW - 1);
  startPage = Math.max(1, endPage - PAGE_WINDOW + 1);
  const visiblePages = [];
  for (let p = startPage; p <= endPage; p += 1) visiblePages.push(p);

  const changePage = (newPage) => {
    if (newPage < 1 || newPage > totalPages || newPage === page) return;
    setPage(newPage);
  };

  const resetPage = () => setPage(1);

  const handleTabChange = (tab) => { setActiveTab(tab); resetPage(); };
  const handleCategoryChange = (e) => { setCategory(e.target.value); resetPage(); };

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Scam Reports</h2>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-4 border-b border-slate-200 dark:border-slate-800 flex flex-col lg:flex-row justify-between gap-4">
          <div className="flex p-1 bg-slate-100 dark:bg-slate-800 rounded-lg w-max">
            {STATUS_TABS.map(tab => (
              <button
                key={tab}
                onClick={() => handleTabChange(tab)}
                className={`px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                  activeTab === tab 
                    ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm" 
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/50"
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
          
          <div className="flex items-center gap-2 flex-wrap">
            <div className="flex items-center gap-1.5">
              <Filter className="size-4 text-slate-400 dark:text-slate-500 shrink-0" />
              <select
                value={category}
                onChange={handleCategoryChange}
                className="h-9 px-3 text-sm bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-md outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
              >
                {CATEGORIES.map((c) => (
                  <option key={c.key} value={c.key}>{c.label}</option>
                ))}
              </select>
            </div>
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-slate-400 dark:text-slate-500" />
              <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search..."
                className="h-9 w-[200px] pl-9 pr-3 text-sm bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-md outline-none focus:bg-white dark:focus:bg-slate-900 focus:border-indigo-500 dark:focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
              />
            </div>
          </div>
        </div>
        
        <div className="hidden md:block flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium text-center w-[60px]">#</th>
                <th className="px-4 py-3 font-medium w-[80px]">ภาพ</th>
                <th className="px-4 py-3 font-medium">หมวดหมู่</th>
                <th className="px-4 py-3 font-medium">ผู้รายงาน</th>
                <th className="px-4 py-3 font-medium">คะแนนเสี่ยง</th>
                <th className="px-4 py-3 font-medium">สถานะ</th>
                <th className="px-4 py-3 font-medium">วันที่</th>
                <th className="px-4 py-3 font-medium text-right">แอคชัน</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
              {isLoading ? (
                Array.from({ length: LIMIT }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <td colSpan="8" className="px-4 py-3">
                      <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : error ? (
                <tr>
                  <td colSpan="8" className="px-4 py-12 text-center text-red-600 dark:text-red-400">{error}</td>
                </tr>
              ) : reportsData.length > 0 ? (
                reportsData.map((report) => (
                  <tr 
                    key={report.id} 
                    onClick={() => navigate(`/admin/reports/${report.id}`)}
                    className={`cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors ${report.status === 'pending' ? 'border-l-2 border-l-blue-500' : 'border-l-2 border-l-transparent'}`}
                  >
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-center text-xs">{report.id}</td>
                    <td className="px-4 py-3">
                      {report.scan?.thumbnail_url ? (
                        <img src={report.scan.thumbnail_url} alt="thumbnail" className="size-10 object-cover rounded-md border border-slate-200 dark:border-slate-800" />
                      ) : (
                        <div className="size-10 flex items-center justify-center bg-slate-100 dark:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-800 text-slate-300 dark:text-slate-600 text-[10px]">
                          N/A
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
                        {report.category}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col">
                        <span className="font-medium text-slate-900 dark:text-slate-100">{report.user?.full_name || "Unknown"}</span>
                        <span className="text-xs text-slate-500 dark:text-slate-400">{report.user?.email || "No Email"}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold ${
                        (report.scan?.total_risk_score || 0) >= 80 ? "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400" :
                        (report.scan?.total_risk_score || 0) >= 50 ? "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400" :
                        "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
                      }`}>
                        {report.scan?.total_risk_score || 0}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${
                        report.status === 'pending' ? "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400" :
                        report.status === 'reviewing' ? "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400" :
                        report.status === 'approved' ? "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400" :
                        "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
                      }`}>
                        {report.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400 text-xs">
                      {new Date(report.created_at).toLocaleDateString('th-TH')}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={(e) => { e.stopPropagation(); navigate(`/admin/reports/${report.id}`); }}
                        className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 bg-transparent rounded-md hover:bg-indigo-50 dark:hover:bg-indigo-500/10 transition-colors outline-none focus:bg-indigo-50 dark:focus:bg-indigo-500/10 focus:ring-2 focus:ring-indigo-500"
                      >
                        <Eye className="size-4" />
                        ดู
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="8" className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบข้อมูลรายการสแกม
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Mobile card layout */}
        <div className="md:hidden flex flex-col divide-y divide-slate-200 dark:divide-slate-800">
          {isLoading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div key={`skeleton-m-${i}`} className="p-4">
                <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
              </div>
            ))
          ) : error ? (
            <div className="px-4 py-12 text-center text-red-600 dark:text-red-400">{error}</div>
          ) : reportsData.length > 0 ? (
            reportsData.map((report) => (
              <div
                key={report.id}
                onClick={() => navigate(`/admin/reports/${report.id}`)}
                className={`p-4 flex flex-col gap-3 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors ${report.status === 'pending' ? 'border-l-2 border-l-blue-500' : 'border-l-2 border-l-transparent'}`}
              >
                <div className="flex items-start gap-3">
                  {report.scan?.thumbnail_url ? (
                    <img src={report.scan.thumbnail_url} alt="thumbnail" className="size-12 object-cover rounded-md border border-slate-200 dark:border-slate-800 shrink-0" />
                  ) : (
                    <div className="size-12 flex items-center justify-center bg-slate-100 dark:bg-slate-800 rounded-md border border-slate-200 dark:border-slate-800 text-slate-300 dark:text-slate-600 text-[10px] shrink-0">
                      N/A
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-medium text-slate-900 dark:text-slate-100 truncate">#{report.id} · {report.category}</span>
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold shrink-0 ${
                        (report.scan?.total_risk_score || 0) >= 80 ? "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400" :
                        (report.scan?.total_risk_score || 0) >= 50 ? "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400" :
                        "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
                      }`}>
                        {report.scan?.total_risk_score || 0}
                      </span>
                    </div>
                    <p className="text-sm text-slate-500 dark:text-slate-400 truncate mt-0.5">
                      {report.user?.full_name || "Unknown"} ({report.user?.email || "No Email"})
                    </p>
                    <div className="flex items-center justify-between gap-2 mt-2">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${
                        report.status === 'pending' ? "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400" :
                        report.status === 'reviewing' ? "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400" :
                        report.status === 'approved' ? "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400" :
                        "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
                      }`}>
                        {report.status}
                      </span>
                      <span className="text-xs text-slate-500 dark:text-slate-400">
                        {new Date(report.created_at).toLocaleDateString('th-TH')}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="flex justify-end">
                  <button
                    onClick={(e) => { e.stopPropagation(); navigate(`/admin/reports/${report.id}`); }}
                    className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 bg-transparent rounded-md hover:bg-indigo-50 dark:hover:bg-indigo-500/10 transition-colors outline-none"
                  >
                    <Eye className="size-4" />
                    ดูรายละเอียด
                  </button>
                </div>
              </div>
            ))
          ) : (
            <div className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
              ไม่พบข้อมูลรายการสแกม
            </div>
          )}
        </div>

        <div className="px-4 py-3 border-t border-slate-200 dark:border-slate-800 flex flex-col sm:flex-row justify-between items-center gap-3 text-sm text-slate-500 dark:text-slate-400 bg-white dark:bg-slate-900">
            <span>Showing {rangeStart}-{rangeEnd} of {total}</span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => changePage(page - 1)}
                disabled={page <= 1}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="size-4" />
                Previous
              </button>
              {startPage > 1 && (
                <span className="px-1 text-slate-400">...</span>
              )}
              {visiblePages.map((p) => (
                <button
                  key={p}
                  onClick={() => changePage(p)}
                  className={`size-8 rounded-md text-sm font-medium transition-colors outline-none focus:ring-2 focus:ring-indigo-500 ${
                    p === page
                      ? "bg-indigo-600 text-white"
                      : "text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800"
                  }`}
                >
                  {p}
                </button>
              ))}
              {endPage < totalPages && (
                <span className="px-1 text-slate-400">...</span>
              )}
              <button
                onClick={() => changePage(page + 1)}
                disabled={page >= totalPages}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Next
                <ChevronRight className="size-4" />
              </button>
            </div>
          </div>
      </div>
    </div>
  );
}