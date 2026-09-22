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
  downloadExportJob,
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
  const [downloadingJobId, setDownloadingJobId] = useState(null);

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
          if (!updated) return;
          const stillActive = updated.jobs?.some(
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

  const handleDownloadJob = async (job) => {
    setDownloadingJobId(job.id);
    try {
      const response = await downloadExportJob(job.id);
      const blob = await response.blob();
      const objectUrl = window.URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = objectUrl;
      anchor.download = `scamguard-export-${job.id}.zip`;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.URL.revokeObjectURL(objectUrl);
    } catch (err) {
      toast.error("ดาวน์โหลดไฟล์ส่งออกล้มเหลว: " + err.message);
    } finally {
      setDownloadingJobId(null);
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
          <p className="text-[13px] text-muted-foreground mt-0.5">
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

      {/* Export constraints and availability */}
      <Card>
        <CardContent className="p-0 grid grid-cols-1 md:grid-cols-3 divide-y md:divide-y-0 md:divide-x divide-border-subtle">
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] text-muted-foreground font-medium"><CheckCircle2 className="size-4 text-success" />รายงานที่ยืนยันแล้ว</div>
            <div className="mt-1 text-lg font-bold text-foreground"><span className="font-mono">{formatNumber(totalApprovedCount)}</span> รูปภาพ</div>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] text-muted-foreground font-medium"><ShieldCheck className="size-4 text-primary" />สิทธิ์ใช้ข้อมูลเพื่อการวิจัย</div>
            <div className="mt-1 text-[13px] font-semibold text-foreground">ใช้เฉพาะรายการที่ได้รับอนุญาต</div>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] text-muted-foreground font-medium"><FileArchive className="size-4 text-muted-foreground" />รูปแบบไฟล์</div>
            <div className="mt-1 text-[13px] font-semibold text-foreground font-mono">ZIP + Manifest.json</div>
          </div>
        </CardContent>
      </Card>

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
            <fieldset className="space-y-2">
              <legend className="block text-[13px] font-semibold text-foreground">
                เลือกหมวดหมู่ที่ต้องการส่งออก
              </legend>
              <div className="flex flex-wrap gap-2">
                {CATEGORIES.map((cat) => {
                  const isSelected = selectedCategories.includes(cat.key);
                  return (
                    <button
                      key={cat.key}
                      type="button"
                      onClick={() => toggleCategory(cat.key)}
                      aria-pressed={isSelected}
                      className={`h-8 px-3 rounded-lg text-xs font-medium border transition-colors ${
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
            </fieldset>

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
                <label htmlFor="include-metadata" className="flex items-center gap-2 cursor-pointer select-none text-[13px] text-foreground font-medium">
                  <input
                    id="include-metadata"
                    name="include_metadata"
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
                                <Button
                                  variant="outline"
                                  size="xs"
                                  icon={Download}
                                  isLoading={downloadingJobId === job.id}
                                  onClick={() => handleDownloadJob(job)}
                                  className="text-primary border-primary-border hover:bg-primary-subtle"
                                >
                                  ดาวน์โหลด ZIP
                                </Button>
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