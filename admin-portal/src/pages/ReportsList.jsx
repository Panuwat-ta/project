import { useState, useEffect } from "react";
import { Search, Filter, Eye } from "lucide-react";

import { fetchReports } from "@/lib/api";

export function ReportsList() {
  const [activeTab, setActiveTab] = useState("All");
  const [isLoading, setIsLoading] = useState(true);
  const [reportsData, setReportsData] = useState([]);
  const [total, setTotal] = useState(0);

  useEffect(() => {
    async function loadReports() {
      setIsLoading(true);
      try {
        const data = await fetchReports(1, 20, activeTab);
        setReportsData(data.items);
        setTotal(data.total);
      } catch (err) {
        console.error("Failed to load reports", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadReports();
  }, [activeTab]);

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Scam Reports</h2>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-4 border-b border-slate-200 dark:border-slate-800 flex flex-col md:flex-row justify-between gap-4">
          <div className="flex p-1 bg-slate-100 dark:bg-slate-800 rounded-lg w-max">
            {['All', 'Pending', 'Reviewing', 'Approved', 'Rejected'].map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
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
          
          <div className="flex items-center gap-2">
            <button className="flex items-center gap-2 h-9 px-3 text-sm font-medium text-slate-600 dark:text-slate-400 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-500/50 focus:border-indigo-500 dark:focus:border-indigo-500">
              <Filter className="size-4" />
              <span>Filter</span>
            </button>
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-slate-400 dark:text-slate-500" />
              <input
                type="search"
                placeholder="Search..."
                className="h-9 w-[200px] pl-9 pr-3 text-sm bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-md outline-none focus:bg-white dark:focus:bg-slate-900 focus:border-indigo-500 dark:focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
              />
            </div>
          </div>
        </div>
        
        <div className="flex-1 overflow-x-auto">
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
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <td colSpan="8" className="px-4 py-3">
                      <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : reportsData.length > 0 ? (
                reportsData.map((report) => (
                  <tr 
                    key={report.id} 
                    className={`hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors ${report.status === 'pending' ? 'border-l-2 border-l-blue-500' : 'border-l-2 border-l-transparent'}`}
                  >
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-center text-xs">{report.id}</td>
                    <td className="px-4 py-3">
                      <img src={report.scan?.thumbnail_url || "https://via.placeholder.com/48"} alt="thumbnail" className="size-10 object-cover rounded-md border border-slate-200 dark:border-slate-800" />
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
                      <button className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-indigo-600 dark:text-indigo-400 bg-transparent rounded-md hover:bg-indigo-50 dark:hover:bg-indigo-500/10 transition-colors outline-none focus:bg-indigo-50 dark:focus:bg-indigo-500/10 focus:ring-2 focus:ring-indigo-500">
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
          
          <div className="px-4 py-3 border-t border-slate-200 dark:border-slate-800 flex justify-between items-center text-sm text-slate-500 dark:text-slate-400 bg-white dark:bg-slate-900">
            <span>Showing 1-{reportsData.length} of {total}</span>
            <div className="flex gap-2">
              <button disabled className="px-3 py-1.5 text-sm font-medium text-slate-400 dark:text-slate-500 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md cursor-not-allowed outline-none focus:ring-2 focus:ring-slate-500">Previous</button>
              <button className="px-3 py-1.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors outline-none focus:ring-2 focus:ring-slate-500">Next</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
