import { useState, useEffect, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { RefreshCw, Eye, Image as ImageIcon } from "lucide-react";
import { fetchReports } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { Tabs } from "@/components/ui/Tabs";
import { RiskBadge, StatusBadge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { Card } from "@/components/ui/Card";
import { SearchInput, Select } from "@/components/ui/Input";
import { formatDate } from "@/lib/utils";
import { useAdminQuery } from "@/lib/use-admin-query";
import { useDebouncedValue } from "@/lib/use-debounced-value";

const LIMIT = 15;

const STATUS_TABS = [
  { id: "All", label: "ทั้งหมด" },
  { id: "Pending", label: "รอตรวจ" },
  { id: "Reviewing", label: "กำลังตรวจ" },
  { id: "Approved", label: "ยืนยันแล้ว" },
  { id: "Rejected", label: "ปฏิเสธ" },
];

const CATEGORIES = [
  { key: "All", label: "ทุกหมวดหมู่การหลอกลวง" },
  { key: "romance_scam", label: "หลอกลวงความรัก" },
  { key: "online_shopping", label: "ซื้อขายออนไลน์" },
  { key: "fake_slip", label: "สลิปโอนเงินปลอม" },
  { key: "investment", label: "ลงทุน / ผลตอบแทนสูง" },
  { key: "identity_theft", label: "ปลอมแปลงตัวตน" },
  { key: "ai_deepfake", label: "ภาพ AI / Deepfake" },
  { key: "other", label: "อื่น ๆ" },
];

const CATEGORY_LABELS = Object.fromEntries(CATEGORIES.filter((c) => c.key !== "All").map((c) => [c.key, c.label]));

export function ReportsList() {
  const [searchParams, setSearchParams] = useSearchParams();

  const statusParam = searchParams.get("status");
  const activeTab = STATUS_TABS.find(
    (tab) => tab.id.toLowerCase() === String(statusParam || "").toLowerCase()
  )?.id || "All";
  const category = searchParams.get("category") || "All";
  const pageParam = parseInt(searchParams.get("page") || "1", 10);
  const initialSearch = searchParams.get("search") || "";

  const [search, setSearch] = useState(initialSearch);
  const [page, setPage] = useState(pageParam);

  // Debounced search (resets to page 1)
  const debouncedSearch = useDebouncedValue(search, 300, () => setPage(1));

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

  const {
    data: { reports, total },
    isLoading,
    isRefreshing,
    reload: loadReports,
  } = useAdminQuery(
    async () => {
      const data = await fetchReports({
        page,
        limit: LIMIT,
        status: activeTab,
        category,
        search: debouncedSearch,
      });
      return { reports: data.items || [], total: data.total || 0 };
    },
    {
      deps: [page, activeTab, category, debouncedSearch],
      initialData: { reports: [], total: 0 },
      successMessage: "รีเฟรชคิวรายงานสำเร็จ",
      errorMessage: "ไม่สามารถโหลดรายการรายงานได้",
      logPrefix: "Load reports error:",
    }
  );

  useEffect(() => {
    updateUrlParams(activeTab, category, page, debouncedSearch);
  }, [activeTab, category, page, debouncedSearch, updateUrlParams]);

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
            <span>รายงานที่รอตรวจสอบ</span>
          </h2>
          <p className="text-[13px] text-muted-foreground mt-0.5">
            ตรวจสอบภาพและยืนยันผลรายงานจากผู้ใช้
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
            รีเฟรช
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
          <div className="flex flex-col sm:flex-row items-center gap-3 w-full lg:w-auto">
            <Select
              value={category}
              onChange={handleCategoryChange}
              containerClassName="sm:w-auto"
              className="sm:w-auto min-w-52"
              aria-label="กรองตามหมวดหมู่"
            >
              {CATEGORIES.map((cat) => (
                <option key={cat.key} value={cat.key}>
                  {cat.label}
                </option>
              ))}
            </Select>

            <SearchInput
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="ค้นหารหัส ผู้ส่ง หรือรายละเอียด..."
              containerClassName="sm:w-64"
              aria-label="ค้นหารายงาน"
            />
          </div>
        </div>

        {/* Data Table */}
        {isLoading ? (
          <TableSkeleton rows={8} cols={6} />
        ) : (
          <div>
            <div className="hidden md:block">
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead className="w-16">ตัวอย่าง</TableHead>
                  <TableHead>รหัสรายงาน</TableHead>
                  <TableHead>หมวดหมู่</TableHead>
                  <TableHead>คะแนนความเสี่ยง</TableHead>
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
                          handleTabChange("All");
                        }}
                        className="mt-2 text-primary"
                      >
                        ล้างตัวกรองทั้งหมด
                      </Button>
                    )}
                  </TableEmpty>
                ) : (
                  reports.map((report) => {
                    const thumbUrl = report.scan?.thumbnail_url;
                    return (
                      <TableRow key={report.id}>
                        {/* Thumbnail */}
                        <TableCell>
                          <div className="size-11 rounded-lg border border-border overflow-hidden bg-muted flex items-center justify-center relative group shrink-0">
                            {thumbUrl ? (
                              <img
                                src={thumbUrl}
                                alt="ตัวอย่างรายงาน"
                                className="size-full object-cover group-hover:scale-110 transition-transform duration-200"
                              />
                            ) : (
                              <ImageIcon className="size-5 text-muted-foreground" />
                            )}
                          </div>
                        </TableCell>

                        {/* ID */}
                        <TableCell>
                          <Link
                            to={`/admin/reports/${report.id}`}
                            className="font-mono text-[13px] font-semibold text-foreground hover:text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
                          >
                            #{report.id}
                          </Link>
                        </TableCell>

                        {/* Category */}
                        <TableCell>
                          <span className="text-[13px] font-medium text-foreground">
                            {CATEGORY_LABELS[report.category] || report.category || "ไม่ระบุ"}
                          </span>
                        </TableCell>

                        {/* Risk Score */}
                        <TableCell>
                          <RiskBadge score={report.scan?.total_risk_score} />
                        </TableCell>

                        {/* Submitter */}
                        <TableCell>
                          <div className="text-[13px] text-foreground font-medium">
                            {report.user?.full_name || report.user?.email || "ผู้ใช้ทั่วไป"}
                          </div>
                          <div className="text-xs text-muted-foreground font-mono truncate max-w-[150px]">
                            {report.user?.email || "-"}
                          </div>
                        </TableCell>

                        {/* Status Badge */}
                        <TableCell>
                          <StatusBadge status={report.status} />
                        </TableCell>

                        {/* Created At */}
                        <TableCell className="text-[13px] text-muted-foreground font-mono whitespace-nowrap">
                          {formatDate(report.created_at)}
                        </TableCell>

                        {/* Action Button */}
                        <TableCell className="text-right">
                          <Link
                            to={`/admin/reports/${report.id}`}
                            className="inline-flex h-8 items-center justify-center gap-1.5 rounded-md bg-secondary px-2.5 text-xs font-medium text-secondary-foreground transition-colors hover:bg-secondary/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                          >
                            <Eye className="size-4" />
                            ตรวจสอบ
                          </Link>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
            </div>

            <div className="md:hidden divide-y divide-border-subtle">
              {reports.length === 0 ? (
                <div className="px-4 py-10 text-center">
                  <p className="text-sm font-medium text-foreground">ไม่พบรายงานที่ตรงกับเงื่อนไขการค้นหา</p>
                  {(search || activeTab !== "All" || category !== "All") && (
                    <Button
                      variant="ghost"
                      size="xs"
                      onClick={() => { setSearch(""); handleTabChange("All"); }}
                      className="mt-2 text-primary"
                    >
                      ล้างตัวกรองทั้งหมด
                    </Button>
                  )}
                </div>
              ) : reports.map((report) => {
                const thumbUrl = report.scan?.thumbnail_url;
                return (
                  <article key={report.id} className="p-4 space-y-3">
                    <div className="flex items-start gap-3">
                      <div className="size-14 rounded-lg border border-border overflow-hidden bg-muted flex items-center justify-center shrink-0">
                        {thumbUrl ? (
                          <img src={thumbUrl} alt="ตัวอย่างรายงาน" className="size-full object-cover" />
                        ) : (
                          <ImageIcon className="size-5 text-muted-foreground" />
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-2">
                          <Link
                            to={`/admin/reports/${report.id}`}
                            className="font-mono text-sm font-semibold text-foreground hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
                          >
                            #{report.id}
                          </Link>
                          <StatusBadge status={report.status} />
                        </div>
                        <p className="mt-1 text-[13px] font-medium text-foreground break-words">
                          {CATEGORY_LABELS[report.category] || report.category || "ไม่ระบุ"}
                        </p>
                        <div className="mt-2"><RiskBadge score={report.scan?.total_risk_score} /></div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between gap-3 border-t border-border-subtle pt-3">
                      <div className="min-w-0 text-xs text-muted-foreground">
                        <div className="truncate">{report.user?.full_name || report.user?.email || "ผู้ใช้ทั่วไป"}</div>
                        <div className="font-mono mt-0.5">{formatDate(report.created_at)}</div>
                      </div>
                      <Link
                        to={`/admin/reports/${report.id}`}
                        className="inline-flex h-9 shrink-0 items-center justify-center gap-1.5 rounded-md border border-border px-3 text-[13px] font-medium text-foreground transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                      >
                        <Eye className="size-4" />
                        ตรวจสอบ
                      </Link>
                    </div>
                  </article>
                );
              })}
            </div>

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