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
import { Input } from "@/components/ui/Input";
import { formatDate, formatNumber, formatFileSize } from "@/lib/utils";
import { useAdminQuery } from "@/lib/use-admin-query";

const CATEGORIES = [
  { key: "romance_scam", label: "หลอกลวงความรัก" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์" },
  { key: "fake_slip", label: "สลิปโอนเงินปลอม" },
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

  const [totalApprovedCount, setTotalApprovedCount] = useState(0);
  const [isExporting, setIsExporting] = useState(false);

  // Export Jobs History
  const [page, setPage] = useState(1);

  const {
    data: { jobs, totalJobs },
    isLoading: jobsLoading,
    isRefreshing: isRefreshingJobs,
    reload: loadJobs,
  } = useAdminQuery(
    async () => {
      const data = await fetchExportJobs({ page, limit: 10 });
      return { jobs: data.items || [], totalJobs: data.total || 0 };
    },
    {
      deps: [page],
      initialData: { jobs: [], totalJobs: 0 },
      resetOnError: false,
      successMessage: "รีเฟรชประวัติงานส่งออกสำเร็จ",
      errorMessage: "ไม่สามารถโหลดประวัติงานส่งออกได้",
      logPrefix: "Load export jobs failed:",
    }
  );

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

  useEffect(() => {
    loadApprovedOverview();
  }, [loadApprovedOverview]);

  // Polling for active jobs
  useEffect(() => {
    const hasActive = jobs.some((j) => j.status === "queued" || j.status === "running");
    if (hasActive && !pollingRef.current) {
      pollingRef.current = setInterval(async () => {
        try {
          const updated = await loadJobs(false, true);
          const stillActive = updated?.jobs?.some(
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
    // loadJobs is a stable reload; jobs/page drive the polling lifecycle.
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
      toast.success("เริ่มสร้างไฟล์ส่งออกแล้ว");
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
          <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Database className="size-5 text-primary" />
            <span>ส่งออกชุดข้อมูล</span>
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            สร้างชุดข้อมูลจากรายงานที่ยืนยันแล้วและได้รับอนุญาตให้นำไปใช้วิจัย
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
            รีเฟรช
          </Button>
        </div>
      </div>

      {/* Overview Stat Bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-success-subtle border border-success-border text-success flex items-center justify-center">
              <CheckCircle2 className="size-5" />
            </div>
            <div>
              <div className="text-xs text-muted-foreground font-medium">รายงานที่ยืนยันแล้ว</div>
              <div className="text-xl font-bold text-foreground">
                <span className="font-mono">{formatNumber(totalApprovedCount)}</span> รูปภาพ
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-primary-subtle border border-primary-border text-primary flex items-center justify-center">
              <ShieldCheck className="size-5" />
            </div>
            <div>
              <div className="text-xs text-muted-foreground font-medium">สิทธิ์ใช้ข้อมูลเพื่อการวิจัย</div>
              <div className="text-[13px] font-semibold text-success mt-0.5">
                ใช้เฉพาะรายการที่ได้รับอนุญาต
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="size-10 rounded-lg bg-warning-subtle border border-warning-border text-warning flex items-center justify-center">
              <FileArchive className="size-5" />
            </div>
            <div>
              <div className="text-xs text-muted-foreground font-medium">รูปแบบไฟล์</div>
              <div className="text-xs font-bold text-foreground font-mono mt-0.5">
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
            <Layers className="size-4 text-primary" />
            <span>สร้างไฟล์ส่งออก</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleCreateExport} className="space-y-5">
            {/* Category Filter Pills */}
            <div className="space-y-2">
              <label className="block text-[13px] font-semibold text-foreground">
                เลือกหมวดหมู่ที่ต้องการส่งออก
              </label>
              <div className="flex flex-wrap gap-2">
                {CATEGORIES.map((cat) => {
                  const isSelected = selectedCategories.includes(cat.key);
                  return (
                    <button
                      key={cat.key}
                      type="button"
                      onClick={() => toggleCategory(cat.key)}
                      className={`h-8 px-3 rounded-lg text-xs font-medium border transition-all ${
                        isSelected
                          ? "bg-primary-subtle border-primary-border text-primary font-semibold shadow-sm"
                          : "bg-muted/40 border-border text-muted-foreground hover:text-foreground hover:bg-muted"
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
              <Input
                type="date"
                label="ตั้งแต่วันที่"
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
                className="font-mono"
              />

              <Input
                type="date"
                label="ถึงวันที่"
                value={toDate}
                onChange={(e) => setToDate(e.target.value)}
                className="font-mono"
              />

              <div className="flex items-end pb-1.5">
                <label className="flex items-center gap-2 cursor-pointer select-none text-[13px] text-foreground font-medium">
                  <input
                    type="checkbox"
                    checked={includeMetadata}
                    onChange={(e) => setIncludeMetadata(e.target.checked)}
                    className="size-4 rounded accent-primary"
                  />
                  <span>รวม Metadata และ Heatmap</span>
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
                สร้างไฟล์ส่งออก
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Export Jobs History Table Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="size-4 text-primary" />
            <span>ประวัติการส่งออก</span>
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
                    <TableHead>รหัสงาน</TableHead>
                    <TableHead>ความคืบหน้า</TableHead>
                    <TableHead>จำนวนภาพ / ขนาด</TableHead>
                    <TableHead>สถานะ</TableHead>
                    <TableHead>วันที่สร้าง</TableHead>
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
                          <TableCell className="font-mono text-[13px] font-bold text-foreground">
                            #{job.id}
                          </TableCell>

                          <TableCell>
                            <span className="text-[13px] font-medium text-foreground">
                              {Math.round(Number(job.progress ?? 0))}%{job.total_rows != null ? ` · ${formatNumber(job.total_rows)} แถว` : ""}
                            </span>
                          </TableCell>

                          <TableCell className="font-mono text-[13px] font-semibold text-foreground">
                            {job.file_size_bytes != null ? formatFileSize(job.file_size_bytes) : "-"}
                          </TableCell>

                          <TableCell>
                            <StatusBadge status={job.status} />
                          </TableCell>

                          <TableCell className="font-mono text-[13px] text-muted-foreground whitespace-nowrap">
                            {formatDate(job.created_at)}
                          </TableCell>

                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-2">
                              {isDone && (
                                <a
                                  href={downloadUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-primary-subtle border border-primary-border text-primary hover:bg-primary/20 text-[13px] font-semibold transition-colors"
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