import { useState, useEffect, useRef } from "react";
import { Download, Loader2, Database, CheckCircle2, CalendarDays, XCircle, Ban, RefreshCw } from "lucide-react";
import { fetchReports, createExportJob, fetchExportJobs, getExportJob, cancelExportJob, getAccessToken } from "@/lib/api";

const CATEGORIES = [
  { key: "romance_scam", label: "หลอกลวงความรัก" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์" },
  { key: "fake_slip", label: "สลิปปลอม" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ" },
];

export function DatasetExport() {
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [includeMetadata, setIncludeMetadata] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState("");
  
  const [approved, setApproved] = useState([]);
  const [totalApproved, setTotalApproved] = useState(0);
  const [isLoadingReports, setIsLoadingReports] = useState(true);
  
  const [jobs, setJobs] = useState([]);
  const [isLoadingJobs, setIsLoadingJobs] = useState(true);
  const pollingRef = useRef(null);

  const loadApproved = async () => {
    setIsLoadingReports(true);
    try {
      const data = await fetchReports({ page: 1, limit: 100, status: "approved" });
      setApproved(data.items || []);
      setTotalApproved(data.total || 0);
    } catch (err) {
      console.error("Failed to load approved reports", err);
    } finally {
      setIsLoadingReports(false);
    }
  };

  const loadJobs = async () => {
    try {
      const data = await fetchExportJobs({ page: 1, limit: 20 });
      setJobs(data.items || []);
      
      const hasActive = data.items.some(j => j.status === 'queued' || j.status === 'running');
      if (hasActive && !pollingRef.current) {
        pollingRef.current = setInterval(pollActiveJobs, 3000);
      } else if (!hasActive && pollingRef.current) {
        clearInterval(pollingRef.current);
        pollingRef.current = null;
      }
    } catch (err) {
      console.error("Failed to load export jobs", err);
    } finally {
      setIsLoadingJobs(false);
    }
  };

  const pollActiveJobs = async () => {
    setJobs(prevJobs => {
      const newJobs = [...prevJobs];
      newJobs.forEach(async (job, idx) => {
        if (job.status === 'queued' || job.status === 'running') {
          try {
            const updated = await getExportJob(job.id);
            setJobs(current => {
              const copy = [...current];
              const i = copy.findIndex(c => c.id === updated.id);
              if (i >= 0) copy[i] = updated;
              
              const hasActiveNow = copy.some(j => j.status === 'queued' || j.status === 'running');
              if (!hasActiveNow && pollingRef.current) {
                clearInterval(pollingRef.current);
                pollingRef.current = null;
              }
              return copy;
            });
          } catch (e) {
            console.error(e);
          }
        }
      });
      return newJobs;
    });
  };

  useEffect(() => {
    loadApproved();
    loadJobs();
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, []);

  const toggleCategory = (key) => {
    setSelectedCategories((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]
    );
  };

  const handleCreateJob = async (e) => {
    e.preventDefault();
    setExporting(true);
    setExportError("");
    try {
      await createExportJob({
        categories: selectedCategories.length > 0 ? selectedCategories : null,
        from_date: fromDate || null,
        to_date: toDate || null,
        include_metadata: includeMetadata,
        format: "zip",
      });
      await loadJobs(); 
    } catch (err) {
      setExportError(err.message);
    } finally {
      setExporting(false);
    }
  };

  const handleCancelJob = async (jobId) => {
    if (!confirm("ต้องการยกเลิกงานนี้หรือไม่?")) return;
    try {
      await cancelExportJob(jobId);
      loadJobs();
    } catch (err) {
      alert("ไม่สามารถยกเลิกงานได้: " + err.message);
    }
  };

  const handleDownload = (jobId) => {
    const token = getAccessToken();
    const url = `/api/v1/admin/dataset/export-jobs/${jobId}/download`;
    
    fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    .then(async res => {
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.detail || "Download failed");
      }
      return res.blob();
    })
    .then(blob => {
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `scamguard_export_${jobId.substring(0, 8)}.zip`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(downloadUrl);
    })
    .catch(err => {
      alert("Download error: " + err.message);
    });
  };

  const renderJobStatus = (job) => {
    switch (job.status) {
      case 'succeeded':
        return <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">เสร็จสมบูรณ์</span>;
      case 'failed':
        return <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400">ล้มเหลว</span>;
      case 'canceled':
        return <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400">ถูกยกเลิก</span>;
      case 'expired':
        return <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400">หมดอายุ</span>;
      case 'running':
      case 'queued':
        return (
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400">
              {job.status === 'queued' ? 'รอดำเนินการ' : 'กำลังประมวลผล'}
            </span>
            {job.status === 'running' && (
              <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400">{Math.round(job.progress)}%</span>
            )}
          </div>
        );
      default:
        return <span>{job.status}</span>;
    }
  };

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Dataset Export</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          สร้างและดาวน์โหลดชุดข้อมูลจากรายงานที่ได้รับการอนุมัติ และผู้ใช้ยินยอมให้ใช้เพื่อการวิจัย
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <Database className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">สร้าง Export Job</h3>
          </div>
        </div>

        <form onSubmit={handleCreateJob} className="p-6 flex flex-col gap-6">
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
            <div className="p-3 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm font-medium rounded-lg border border-red-100 dark:border-red-800/50 flex items-start gap-2">
              <XCircle className="size-4 mt-0.5 shrink-0" />
              <span>{exportError}</span>
            </div>
          )}

          <div className="flex items-center gap-3 border-t border-slate-200 dark:border-slate-800 pt-6">
            <button
              type="submit"
              disabled={exporting}
              className="inline-flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors disabled:opacity-70 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
            >
              {exporting ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  กำลังส่งคำสั่ง...
                </>
              ) : (
                <>
                  <Database className="size-4" />
                  สั่งประมวลผล
                </>
              )}
            </button>
            <span className="text-sm text-slate-500 dark:text-slate-400">
              รายงานที่ยืนยันแล้วทั้งหมด: <span className="font-bold">{totalApproved.toLocaleString()}</span> รายการ
            </span>
          </div>
        </form>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
          <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ประวัติการส่งออก (Export Jobs)</h3>
          <button onClick={loadJobs} className="text-slate-500 hover:text-slate-700 dark:hover:text-slate-300">
            <RefreshCw className="size-4" />
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">Job ID</th>
                <th className="px-4 py-3 font-medium">สร้างเมื่อ</th>
                <th className="px-4 py-3 font-medium">สถานะ</th>
                <th className="px-4 py-3 font-medium">รายการ/ขนาด</th>
                <th className="px-4 py-3 font-medium text-right">การจัดการ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
              {isLoadingJobs ? (
                <tr>
                  <td colSpan="5" className="px-4 py-8 text-center text-slate-500">
                    <Loader2 className="size-5 animate-spin mx-auto mb-2" /> กำลังโหลดประวัติ...
                  </td>
                </tr>
              ) : jobs.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-4 py-8 text-center text-slate-500">ยังไม่มีประวัติการส่งออก</td>
                </tr>
              ) : (
                jobs.map((job) => (
                  <tr key={job.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-slate-500 dark:text-slate-400">
                      {job.id.substring(0, 8)}
                    </td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-400 text-xs">
                      {new Date(job.created_at).toLocaleString("th-TH")}
                    </td>
                    <td className="px-4 py-3">{renderJobStatus(job)}</td>
                    <td className="px-4 py-3 text-xs text-slate-600 dark:text-slate-400">
                      {job.total_rows !== null ? (
                        <>
                          <span className="font-semibold text-slate-900 dark:text-slate-100">{job.total_rows}</span> rows <br/>
                          <span className="text-[10px] opacity-70">{formatBytes(job.file_size_bytes)}</span>
                        </>
                      ) : '-'}
                      {job.error_message && (
                        <div className="text-red-500 max-w-[200px] truncate" title={job.error_message}>
                          {job.error_message}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {(job.status === 'queued' || job.status === 'running') && (
                        <button
                          onClick={() => handleCancelJob(job.id)}
                          className="inline-flex items-center justify-center p-1.5 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md transition-colors"
                          title="ยกเลิกงาน"
                        >
                          <Ban className="size-4" />
                        </button>
                      )}
                      {job.status === 'succeeded' && (
                        <button
                          onClick={() => handleDownload(job.id)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-indigo-700 bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-900/30 dark:text-indigo-400 dark:hover:bg-indigo-900/50 rounded-md transition-colors"
                        >
                          <Download className="size-3.5" />
                          ดาวน์โหลด
                        </button>
                      )}
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

function formatBytes(bytes) {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`;
}