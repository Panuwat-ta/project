import { useState, useEffect, useRef, useCallback } from "react";
import {
  Download,
  Database,
  RefreshCw,
  Ban,
  CheckCircle2,
  FileArchive,
  Layers,
  Clock,
  ShieldCheck,
} from "lucide-react";
import {
  fetchReports,
  createExportJob,
  fetchExportJobs,
  cancelExportJob,
  getExportDownloadUrl,
} from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { StatusBadge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";

const CATEGORIES = [
  { key: "romance_scam", label: "หลอกลวงความรัก (Romance)" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์ (Shopping)" },
  { key: "fake_slip", label: "สลิปโอนเงินปลอม (Slip)" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง (Invest)" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน (Identity)" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ (Other)" },
];

export function DatasetExport() {
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [includeMetadata, setIncludeMetadata] = useState(true);

  const [totalApprovedCount, setTotalApprovedCount] = useState(0);
  const [isExporting, setIsExporting] = useState(false);

  // Export Jobs History
  const [jobs, setJobs] = useState([]);
  const [jobsLoading, setJobsLoading] = useState(true);
  const [isRefreshingJobs, setIsRefreshingJobs] = useState(false);
  const [page, setPage] = useState(1);
  const [totalJobs, setTotalJobs] = useState(0);

  const pollingRef = useRef(null);
  const toast = useToast();

  const loadApprovedOverview = useCallback(async () => {
    try {
      const data = await fetchReports({ page: 1, limit: 1, status: "approved" });
      setTotalApprovedCount(data.total || 0);
    } catch {
      // silent
    }
  }, []);

  const loadJobs = useCallback(async (manual = false) => {
    try {
      if (manual) setIsRefreshingJobs(true);
      else setJobsLoading(true);

      const data = await fetchExportJobs({ page, limit: 10 });
      setJobs(data.items || []);
      setTotalJobs(data.total || 0);

      if (manual) toast.success("รีเฟรชประวัติงานส่งออกสำเร็จ");
    } catch (err) {
      console.error("Load export jobs failed:", err);
      toast.error("ไม่สามารถโหลดประวัติงานส่งออกได้");
    } finally {
      setJobsLoading(false);
      setIsRefreshingJobs(false);
    }
  }, [page, toast]);

  useEffect(() => {
    loadApprovedOverview();
    loadJobs();
  }, [loadApprovedOverview, loadJobs]);

  // Polling for active jobs
  useEffect(() => {
    const hasActive = jobs.some((j) => j.status === "queued" || j.status === "running");
    if (hasActive && !pollingRef.current) {
      pollingRef.current = setInterval(async () => {
        try {
          const updated = await fetchExportJobs({ page, limit: 10 });
          setJobs(updated.items || []);
          const stillActive = updated.items?.some(
            (j) => j.status === "queued" || j.status === "running"
          );
          if (!stillActive && pollingRef.current) {
            clearInterval(pollingRef.current);
            pollingRef.current = null;
          }
        } catch {
          // silent
        }
      }, 3000);
    } else if (!hasActive && pollingRef.current) {
      clearInterval(pollingRef.current);
      pollingRef.current = null;
    }

    return () => {
      if (pollingRef.current) {
        clearInterval(pollingRef.current);
        pollingRef.current = null;
      }
    };
  }, [jobs, page]);

  const toggleCategory = (key) => {
    setSelectedCategories((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]
    );
  };

  const handleCreateExport = async (e) => {
    e.preventDefault();
    setIsExporting(true);

    const payload = {
      categories: selectedCategories.length > 0 ? selectedCategories : null,
      from_date: fromDate || null,
      to_date: toDate || null,
      include_metadata: includeMetadata,
    };

    try {
      await createExportJob(payload);
      toast.success("สร้างงานส่งออกชุดข้อมูลเรียบร้อยแล้ว ระบบกำลังประมวลผลในเบื้องหลัง");
      setSelectedCategories([]);
      setFromDate("");
      setToDate("");
      loadJobs();
    } catch (err) {
      toast.error("สร้างงานส่งออกล้มเหลว: " + err.message);
    } finally {
      setIsExporting(false);
    }
  };

  const handleCancelJob = async (jobId) => {
    try {
      await cancelExportJob(jobId);
      toast.info(`ยกเลิกงานส่งออก #${jobId} เรียบร้อยแล้ว`);
      loadJobs();
    } catch (err) {
      toast.error("ยกเลิกงานล้มเหลว: " + err.message);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <Database className="size-5 text-cyan-400" />
            <span>ส่งออกชุดข้อมูลสำหรับงานวิจัย (Dataset Export Pipeline)</span>
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            รวบรวมรูปภาพหลอกลวงที่ผ่านการยืนยัน (Approved) พร้อมความยินยอม PDPA เพื่อใช้ฝึกและประเมินโมเดล AI
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshingJobs}
            onClick={() => loadJobs(true)}
          >
            รีเฟรชประวัติงาน
          </Button>
        </div>
      </div>

      {/* Overview Stat Bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 flex items-center justify-center">
              <CheckCircle2 className="size-5" />
            </div>
            <div>
              <div className="text-xs text-slate-500">รายงานที่ผ่านการอนุมัติ (Approved)</div>
              <div className="text-xl font-bold font-mono text-slate-900 dark:text-slate-100">
                {formatNumber(totalApprovedCount)} รูปภาพ
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 flex items-center justify-center">
              <ShieldCheck className="size-5" />
            </div>
            <div>
              <div className="text-xs text-slate-500">มาตรการคุ้มครองข้อมูล (PDPA Filter)</div>
              <div className="text-xs font-semibold text-emerald-400 font-mono mt-0.5">
                Enforced (allow_research_use=true)
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-amber-500/10 border border-amber-500/30 text-amber-400 flex items-center justify-center">
              <FileArchive className="size-5" />
            </div>
            <div>
              <div className="text-xs text-slate-500">รูปแบบไฟล์ผลลัพธ์ (Packaging)</div>
              <div className="text-xs font-semibold text-slate-300 font-mono mt-0.5">
                ZIP Archive + Manifest.json
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Export Configuration Form Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Layers className="size-4 text-cyan-400" />
            <span>สร้างงานส่งออกชุดข้อมูลใหม่ (New Export Job)</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleCreateExport} className="space-y-5">
            {/* Category Filter Pills */}
            <div className="space-y-2">
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300">
                เลือกหมวดหมู่ที่ต้องการส่งออก (ค่าเริ่มต้นคือทุกหมวดหมู่)
              </label>
              <div className="flex flex-wrap gap-2">
                {CATEGORIES.map((cat) => {
                  const isSelected = selectedCategories.includes(cat.key);
                  return (
                    <button
                      key={cat.key}
                      type="button"
                      onClick={() => toggleCategory(cat.key)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all ${
                        isSelected
                          ? "bg-cyan-500/20 border-cyan-500 text-cyan-300 shadow-sm"
                          : "bg-slate-50 dark:bg-slate-800/80 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:text-slate-200"
                      }`}
                    >
                      {cat.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Date Range & Metadata Options */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
              <div className="space-y-1.5">
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300">
                  ตั้งแต่วันที่ (From Date)
                </label>
                <input
                  type="date"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                  className="w-full px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-xs text-slate-900 dark:text-slate-100 outline-none focus:border-cyan-500 font-mono"
                />
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300">
                  ถึงวันที่ (To Date)
                </label>
                <input
                  type="date"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                  className="w-full px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-xs text-slate-900 dark:text-slate-100 outline-none focus:border-cyan-500 font-mono"
                />
              </div>

              <div className="flex items-end pb-1.5">
                <label className="flex items-center gap-2 cursor-pointer select-none text-xs text-slate-700 dark:text-slate-300 font-medium">
                  <input
                    type="checkbox"
                    checked={includeMetadata}
                    onChange={(e) => setIncludeMetadata(e.target.checked)}
                    className="size-4 rounded accent-cyan-500"
                  />
                  <span>รวม Metadata & Heatmap Mask ลงในไฟล์</span>
                </label>
              </div>
            </div>

            <div className="pt-2 flex justify-end">
              <Button
                type="submit"
                variant="primary"
                size="md"
                icon={Download}
                isLoading={isExporting}
              >
                เริ่มสร้างไฟล์ส่งออก (Queue Export Job)
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Export Jobs History Table Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="size-4 text-cyan-400" />
            <span>ประวัติงานส่งออกชุดข้อมูล (Export Jobs History)</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {jobsLoading ? (
            <TableSkeleton rows={5} cols={6} />
          ) : (
            <div>
              <Table>
                <TableHeader>
                  <TableRow isHoverable={false}>
                    <TableHead>Job ID</TableHead>
                    <TableHead>หมวดหมู่ที่เลือก</TableHead>
                    <TableHead>จำนวนภาพ / ขนาด</TableHead>
                    <TableHead>สถานะงาน</TableHead>
                    <TableHead>วันที่สร้างงาน</TableHead>
                    <TableHead className="text-right">การจัดการ</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {jobs.length === 0 ? (
                    <TableEmpty colSpan={6} message="ยังไม่มีประวัติการส่งออกชุดข้อมูล" />
                  ) : (
                    jobs.map((job) => {
                      const isDone = job.status === "succeeded";
                      const isRunning = job.status === "running" || job.status === "queued";
                      const downloadUrl = getExportDownloadUrl(job.id);

                      return (
                        <TableRow key={job.id}>
                          <TableCell className="font-mono text-xs font-semibold">
                            #{job.id}
                          </TableCell>

                          <TableCell>
                            <span className="text-xs text-slate-700 dark:text-slate-300">
                              {job.categories && job.categories.length > 0
                                ? job.categories.join(", ")
                                : "ทุกหมวดหมู่"}
                            </span>
                          </TableCell>

                          <TableCell className="font-mono text-xs">
                            {job.file_count ? `${formatNumber(job.file_count)} ไฟล์` : "-"}
                            {job.file_size_mb ? ` (${job.file_size_mb} MB)` : ""}
                          </TableCell>

                          <TableCell>
                            <StatusBadge status={job.status} />
                          </TableCell>

                          <TableCell className="font-mono text-xs text-slate-500 whitespace-nowrap">
                            {formatDate(job.created_at)}
                          </TableCell>

                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-2">
                              {isDone && (
                                <a
                                  href={downloadUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 text-xs font-medium transition-colors"
                                >
                                  <Download className="size-3.5" />
                                  <span>ดาวน์โหลด ZIP</span>
                                </a>
                              )}

                              {isRunning && (
                                <Button
                                  variant="dangerOutline"
                                  size="xs"
                                  icon={Ban}
                                  onClick={() => handleCancelJob(job.id)}
                                >
                                  ยกเลิก
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>

              <Pagination
                page={page}
                totalPages={Math.max(1, Math.ceil(totalJobs / 10))}
                totalItems={totalJobs}
                onPageChange={(p) => setPage(p)}
                limit={10}
              />
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}