import { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Search, RefreshCw, Eye, Image as ImageIcon } from "lucide-react";
import { fetchReports } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { Tabs } from "@/components/ui/Tabs";
import { RiskBadge, StatusBadge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { Card } from "@/components/ui/Card";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate } from "@/lib/utils";

const LIMIT = 15;

const STATUS_TABS = [
  { id: "All", label: "ทั้งหมด" },
  { id: "Pending", label: "รอตรวจ (Pending)" },
  { id: "Reviewing", label: "กำลังตรวจ (Reviewing)" },
  { id: "Approved", label: "ยืนยัน Scam (Approved)" },
  { id: "Rejected", label: "ปัดตก (Rejected)" },
];

const CATEGORIES = [
  { key: "All", label: "ทุกหมวดหมู่การหลอกลวง" },
  { key: "romance_scam", label: "หลอกลวงความรัก (Romance Scam)" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์ (Online Shopping)" },
  { key: "fake_slip", label: "สลิปโอนเงินปลอม (Fake Slip)" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง (Investment)" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน (Identity Theft)" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ (Other)" },
];

export function ReportsList() {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const toast = useToast();

  const activeTab = searchParams.get("status") || "All";
  const category = searchParams.get("category") || "All";
  const pageParam = parseInt(searchParams.get("page") || "1", 10);
  const initialSearch = searchParams.get("search") || "";

  const [search, setSearch] = useState(initialSearch);
  const [debouncedSearch, setDebouncedSearch] = useState(initialSearch);
  const [page, setPage] = useState(pageParam);
  const [reports, setReports] = useState([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const searchTimer = useRef(null);

  // Debounce search input
  useEffect(() => {
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      setDebouncedSearch(search.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(searchTimer.current);
  }, [search]);

  // Sync params to URL
  const updateUrlParams = useCallback(
    (newTab, newCat, newPage, newSearch) => {
      const params = new URLSearchParams();
      if (newTab && newTab !== "All") params.set("status", newTab.toLowerCase());
      if (newCat && newCat !== "All") params.set("category", newCat);
      if (newPage > 1) params.set("page", String(newPage));
      if (newSearch) params.set("search", newSearch);
      setSearchParams(params, { replace: true });
    },
    [setSearchParams]
  );

  const loadReports = useCallback(
    async (manual = false) => {
      try {
        if (manual) setIsRefreshing(true);
        else setIsLoading(true);

        const data = await fetchReports({
          page,
          limit: LIMIT,
          status: activeTab,
          category,
          search: debouncedSearch,
        });

        setReports(data.items || []);
        setTotal(data.total || 0);

        if (manual) {
          toast.success("รีเฟรชคิวรายงานสำเร็จ");
        }
      } catch (err) {
        console.error("Load reports error:", err);
        toast.error("ไม่สามารถโหลดรายการรายงานได้: " + err.message);
        setReports([]);
        setTotal(0);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    [page, activeTab, category, debouncedSearch, toast]
  );

  useEffect(() => {
    updateUrlParams(activeTab, category, page, debouncedSearch);
    loadReports();
  }, [activeTab, category, page, debouncedSearch, updateUrlParams, loadReports]);

  const handleTabChange = (newTab) => {
    setPage(1);
    updateUrlParams(newTab, category, 1, debouncedSearch);
  };

  const handleCategoryChange = (e) => {
    const newCat = e.target.value;
    setPage(1);
    updateUrlParams(activeTab, newCat, 1, debouncedSearch);
  };

  const totalPages = Math.max(1, Math.ceil(total / LIMIT));

  return (
    <div className="space-y-5">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <span>คิวรายงานการหลอกลวง (Scam Reports Queue)</span>
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            ตรวจสอบ พิสูจน์หลักฐานความผิดปกติของรูปภาพ และตัดสินสถานะรายงาน
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshing}
            onClick={() => loadReports(true)}
          >
            รีเฟรชคิว
          </Button>
        </div>
      </div>

      {/* Filter and Search Toolbar */}
      <Card>
        <div className="p-4 flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-border-subtle">
          {/* Status Tabs */}
          <Tabs
            tabs={STATUS_TABS}
            activeTab={activeTab}
            onChange={handleTabChange}
          />

          {/* Search & Category Filter */}
          <div className="flex flex-col sm:flex-row items-center gap-3">
            <select
              value={category}
              onChange={handleCategoryChange}
              className="w-full sm:w-auto px-3 py-1.5 bg-card border border-input text-xs font-medium text-foreground rounded-lg outline-none focus:border-ring focus:ring-1 focus:ring-ring transition-all"
            >
              {CATEGORIES.map((cat) => (
                <option key={cat.key} value={cat.key}>
                  {cat.label}
                </option>
              ))}
            </select>

            <div className="relative w-full sm:w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-3.5 text-muted-foreground" />
              <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="ค้นหารหัส, ผู้ส่ง, รายละเอียด..."
                className="w-full pl-8 pr-3 py-1.5 bg-card border border-input text-xs text-foreground placeholder:text-muted-foreground rounded-lg outline-none focus:border-ring focus:ring-1 focus:ring-ring transition-all font-mono"
              />
            </div>
          </div>
        </div>

        {/* Data Table */}
        {isLoading ? (
          <TableSkeleton rows={8} cols={6} />
        ) : (
          <div>
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead className="w-16">ตัวอย่าง</TableHead>
                  <TableHead>รหัสรายงาน (ID / Hash)</TableHead>
                  <TableHead>หมวดหมู่</TableHead>
                  <TableHead>คะแนนเสี่ยง (Risk)</TableHead>
                  <TableHead>ผู้ส่งรายงาน</TableHead>
                  <TableHead>สถานะ</TableHead>
                  <TableHead>วันที่ส่งตรวจ</TableHead>
                  <TableHead className="text-right">การจัดการ</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {reports.length === 0 ? (
                  <TableEmpty
                    colSpan={8}
                    message="ไม่พบรายงานที่ตรงกับเงื่อนไขการค้นหา"
                  >
                    {(search || activeTab !== "All" || category !== "All") && (
                      <Button
                        variant="ghost"
                        size="xs"
                        onClick={() => {
                          setSearch("");
                          setDebouncedSearch("");
                          handleTabChange("All");
                        }}
                        className="mt-2 text-cyan-500"
                      >
                        ล้างตัวกรองทั้งหมด
                      </Button>
                    )}
                  </TableEmpty>
                ) : (
                  reports.map((report) => {
                    const thumbUrl = report.image_url || report.thumbnail_url;
                    return (
                      <TableRow
                        key={report.id}
                        className="cursor-pointer"
                        onClick={() => navigate(`/admin/reports/${report.id}`)}
                      >
                        {/* Thumbnail */}
                        <TableCell onClick={(e) => e.stopPropagation()}>
                          <div className="size-11 rounded-lg border border-border overflow-hidden bg-muted flex items-center justify-center relative group shrink-0">
                            {thumbUrl ? (
                              <img
                                src={thumbUrl}
                                alt="Report Preview"
                                className="size-full object-cover group-hover:scale-110 transition-transform duration-200"
                              />
                            ) : (
                              <ImageIcon className="size-5 text-muted-foreground" />
                            )}
                          </div>
                        </TableCell>

                        {/* ID and Hash */}
                        <TableCell>
                          <div className="font-mono text-xs font-semibold text-foreground">
                            #{report.id}
                          </div>
                          {report.image_hash && (
                            <div className="text-[10px] font-mono text-muted-foreground truncate max-w-[140px]" title={report.image_hash}>
                              {report.image_hash.substring(0, 16)}...
                            </div>
                          )}
                        </TableCell>

                        {/* Category */}
                        <TableCell>
                          <span className="text-xs font-medium text-foreground">
                            {report.category_label || report.category || "ไม่ระบุ"}
                          </span>
                        </TableCell>

                        {/* Risk Score */}
                        <TableCell>
                          <RiskBadge score={report.risk_score} />
                        </TableCell>

                        {/* Submitter */}
                        <TableCell>
                          <div className="text-xs text-foreground font-medium">
                            {report.user_name || "ผู้ใช้ทั่วไป"}
                          </div>
                          <div className="text-[10px] text-muted-foreground font-mono truncate max-w-[150px]">
                            {report.user_email || "-"}
                          </div>
                        </TableCell>

                        {/* Status Badge */}
                        <TableCell>
                          <StatusBadge status={report.status} />
                        </TableCell>

                        {/* Created At */}
                        <TableCell className="text-xs text-muted-foreground font-mono whitespace-nowrap">
                          {formatDate(report.created_at)}
                        </TableCell>

                        {/* Action Button */}
                        <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                          <Button
                            variant="secondary"
                            size="xs"
                            icon={Eye}
                            onClick={() => navigate(`/admin/reports/${report.id}`)}
                          >
                            ตรวจสอบ
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>

            {/* Pagination */}
            <Pagination
              page={page}
              totalPages={totalPages}
              totalItems={total}
              onPageChange={(p) => setPage(p)}
              limit={LIMIT}
            />
          </div>
        )}
      </Card>
    </div>
  );
}