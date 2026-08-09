import { useState, useEffect } from "react";
import { Download, Loader2, Database, CheckCircle2, CalendarDays } from "lucide-react";

import { fetchReports, exportDataset } from "@/lib/api";

const CATEGORIES = [
  { key: "romance_scam", label: "หลอกลวงความรัก" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์" },
  { key: "fake_slip", label: "สลิปปลอม" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ" },
];

function getFilenameFromDisposition(disposition) {
  if (!disposition) return null;
  const match = disposition.match(/filename="?([^"]+)"?/i);
  return match ? match[1] : null;
}

export function DatasetExport() {
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [includeMetadata, setIncludeMetadata] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState("");
  const [lastExport, setLastExport] = useState(null);

  const [approved, setApproved] = useState([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [history, setHistory] = useState([]);

  useEffect(() => {
    async function loadApproved() {
      setIsLoading(true);
      try {
        const data = await fetchReports({ page: 1, limit: 100, status: "approved" });
        setApproved(data.items || []);
        setTotal(data.total || 0);
      } catch (err) {
        console.error("Failed to load approved reports", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadApproved();
  }, []);

  const toggleCategory = (key) => {
    setSelectedCategories((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]
    );
  };

  const handleExport = async (e) => {
    e.preventDefault();
    setExporting(true);
    setExportError("");
    try {
      const res = await exportDataset({
        categories: selectedCategories.length > 0 ? selectedCategories : null,
        from_date: fromDate || null,
        to_date: toDate || null,
        include_metadata: includeMetadata,
        format: "zip",
      });
      const blob = await res.blob();
      const filename = getFilenameFromDisposition(res.headers.get("content-disposition")) || "scamguard_dataset.zip";
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);

      const exportedAt = new Date();
      setHistory((prev) => [
        { name: filename, size: blob.size, date: exportedAt },
        ...prev,
      ]);
      setLastExport({ filename, size: blob.size, date: exportedAt });
    } catch (err) {
      setExportError(err.message);
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Dataset Export</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          สร้างชุดข้อมูลจาก Scam Report ที่ได้รับการอนุมัติเพื่อนำไปใช้เทรนหรือทดสอบโมเดล
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <Database className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">สร้าง Export</h3>
          </div>
        </div>

        <form onSubmit={handleExport} className="p-6 flex flex-col gap-6">
          <div>
            <p className="text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">หมวดหมู่</p>
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
              {CATEGORIES.map((c) => {
                const isChecked = selectedCategories.includes(c.key);
                return (
                  <label
                    key={c.key}
                    className={`flex items-center gap-2.5 px-3 py-2.5 rounded-lg border cursor-pointer transition-colors ${
                      isChecked
                        ? "border-indigo-500 bg-indigo-50 dark:bg-indigo-500/10 text-indigo-700 dark:text-indigo-400"
                        : "border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400 hover:border-slate-300 dark:hover:border-slate-700"
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={isChecked}
                      onChange={() => toggleCategory(c.key)}
                      className="size-4 accent-indigo-600"
                    />
                    <span className="text-sm">{c.label}</span>
                  </label>
                );
              })}
            </div>
            <p className="mt-2 text-xs text-slate-400 dark:text-slate-500">ปล่อยว่างเพื่อเลือกทุกหมวดหมู่</p>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2 flex items-center gap-1.5">
                <CalendarDays className="size-4 text-slate-400" /> จากวันที่
              </label>
              <input
                type="date"
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
                className="w-full h-9 px-3 text-sm bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-md outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2 flex items-center gap-1.5">
                <CalendarDays className="size-4 text-slate-400" /> ถึงวันที่
              </label>
              <input
                type="date"
                value={toDate}
                min={fromDate || undefined}
                onChange={(e) => setToDate(e.target.value)}
                className="w-full h-9 px-3 text-sm bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-md outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
              />
            </div>
            <div>
              <label className="flex items-center justify-between h-9 mt-7 px-3 py-2 rounded-md bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 cursor-pointer">
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300">รวม Metadata</span>
                <button
                  type="button"
                  onClick={() => setIncludeMetadata(!includeMetadata)}
                  className={`relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900 ${
                    includeMetadata ? "bg-indigo-600" : "bg-slate-300 dark:bg-slate-700"
                  }`}
                >
                  <span
                    className={`inline-block size-4 transform rounded-full bg-white shadow transition-transform ${
                      includeMetadata ? "translate-x-5" : "translate-x-1"
                    }`}
                  />
                </button>
              </label>
            </div>
          </div>

          {exportError && (
            <div className="p-3 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm font-medium rounded-lg border border-red-100 dark:border-red-800/50">
              {exportError}
            </div>
          )}

          {lastExport && (
            <div className="p-4 rounded-lg border border-emerald-200 dark:border-emerald-800/50 bg-emerald-50 dark:bg-emerald-900/10 flex items-start gap-3">
              <CheckCircle2 className="size-5 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
              <div className="text-sm">
                <p className="font-medium text-emerald-700 dark:text-emerald-400">Export สำเร็จ</p>
                <p className="text-xs text-emerald-600 dark:text-emerald-400/80 mt-0.5">
                  {lastExport.filename} ({formatBytes(lastExport.size)}) — {lastExport.date.toLocaleString("th-TH")}
                </p>
              </div>
            </div>
          )}

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={exporting}
              className="inline-flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors disabled:opacity-70 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
            >
              {exporting ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  กำลังสร้าง Export...
                </>
              ) : (
                <>
                  <Download className="size-4" />
                  สร้าง Export
                </>
              )}
            </button>
            <span className="text-sm text-slate-500 dark:text-slate-400">
              มีรูปที่พร้อม Export จำนวน <span className="font-bold">{total.toLocaleString()}</span> รายการ
            </span>
          </div>
        </form>
      </div>

      {/* Export History (session) */}
      {history.length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ประวัติ Export ในเซสชันนี้</h3>
          </div>
          <div className="flex-1 overflow-x-auto">
            <table className="w-full text-sm text-left whitespace-nowrap">
              <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
                <tr>
                  <th className="px-4 py-3 font-medium">#</th>
                  <th className="px-4 py-3 font-medium">Export ID</th>
                  <th className="px-4 py-3 font-medium">Size</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium text-right">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                {history.map((item, i) => (
                  <tr key={`${item.date.getTime()}`} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-xs">{i + 1}</td>
                    <td className="px-4 py-3 font-mono text-xs text-slate-900 dark:text-slate-100">{item.filename}</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-400">{formatBytes(item.size)}</td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">
                        Done
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right text-slate-500 dark:text-slate-400 text-xs">
                      {item.date.toLocaleString("th-TH")}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Approved reports preview */}
      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800">
          <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">รายการที่พร้อม Export (สถานะ Approved)</h3>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">แสดงข้อมูลส่วนหนึ่งที่นำไปใช้ทำ Dataset ได้</p>
        </div>
        <div className="p-6">
          {isLoading ? (
            <div className="grid gap-3 grid-cols-2 sm:grid-cols-3 lg:grid-cols-5">
              {Array.from({ length: 10 }).map((_, i) => (
                <div key={i} className="aspect-square rounded-lg bg-slate-100 dark:bg-slate-800/40 animate-pulse" />
              ))}
            </div>
          ) : approved.length === 0 ? (
            <div className="py-12 text-center text-slate-500 dark:text-slate-400">
              ยังไม่มีรายงานที่ได้รับการอนุมัติ
            </div>
          ) : (
            <div className="grid gap-4 grid-cols-2 sm:grid-cols-3 lg:grid-cols-5">
              {approved.slice(0, 15).map((report) => (
                <div key={report.id} className="rounded-lg border border-slate-200 dark:border-slate-800 overflow-hidden">
                  {report.scan?.thumbnail_url ? (
                    <img src={report.scan.thumbnail_url} alt={report.category} className="w-full aspect-square object-cover" />
                  ) : (
                    <div className="w-full aspect-square flex items-center justify-center bg-slate-100 dark:bg-slate-800 text-slate-400 text-xs">N/A</div>
                  )}
                  <div className="px-2.5 py-2">
                    <p className="text-xs font-medium text-slate-900 dark:text-slate-100 truncate">{report.category}</p>
                    <p className="text-[10px] text-slate-500 dark:text-slate-400 mt-0.5">Risk {report.scan?.total_risk_score ?? 0}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function formatBytes(bytes) {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`;
}