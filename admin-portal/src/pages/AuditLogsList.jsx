import { useState, Fragment } from "react";
import {
  RefreshCw,
  ChevronDown,
  ChevronUp,
  Shield,
  Terminal,
} from "lucide-react";
import { fetchAuditLogs } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { Badge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { SearchInput, Select } from "@/components/ui/Input";
import { formatDate, formatNumber } from "@/lib/utils";
import { useAdminQuery } from "@/lib/use-admin-query";
import { useDebouncedValue } from "@/lib/use-debounced-value";

const LIMIT = 25;

const ENTITY_TYPES = [
  { value: "All", label: "ทุกประเภท" },
  { value: "report", label: "รายงาน" },
  { value: "user", label: "ผู้ใช้" },
  { value: "model", label: "โมเดล AI" },
  { value: "dataset", label: "ชุดข้อมูล" },
];

export function AuditLogsList() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const debouncedSearch = useDebouncedValue(search, 300, () => setPage(1));
  const [entityType, setEntityType] = useState("All");
  const [expandedLogId, setExpandedLogId] = useState(null);

  const {
    data: { logs, total },
    isLoading,
    isRefreshing,
    reload: loadLogs,
  } = useAdminQuery(
    async () => {
      const data = await fetchAuditLogs({
        page,
        limit: LIMIT,
        search: debouncedSearch,
        action: "All",
        entity_type: entityType,
      });
      return { logs: data.items || [], total: data.total || 0 };
    },
    {
      deps: [page, debouncedSearch, entityType],
      initialData: { logs: [], total: 0 },
      successMessage: "รีเฟรชบันทึกกิจกรรมแล้ว",
      errorMessage: "ไม่สามารถโหลดบันทึกกิจกรรมได้",
      logPrefix: "Load audit logs failed:",
    }
  );

  const toggleExpand = (id) => {
    setExpandedLogId((prev) => (prev === id ? null : id));
  };

  const getActionBadgeVariant = (action = "") => {
    const a = action.toLowerCase();
    if (a.includes("approved") || a.includes("unbanned")) return "success";
    if (a.includes("rejected") || a.includes("banned")) return "danger";
    if (a.includes("deploy")) return "primary";
    if (a.includes("export")) return "info";
    return "default";
  };

  const totalPages = Math.max(1, Math.ceil(total / LIMIT));

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Shield className="size-5 text-primary" />
            <span>บันทึกกิจกรรมผู้ดูแล</span>
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            ประวัติการดำเนินการและการเปลี่ยนแปลงที่เกิดขึ้นในระบบ
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshing}
            onClick={() => loadLogs(true)}
          >
            รีเฟรช
          </Button>
        </div>
      </div>

      {/* Filter and Table Card */}
      <Card>
        <div className="p-4 flex flex-col sm:flex-row items-center justify-between gap-4 border-b border-border-subtle">
          <div className="flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto">
            <Select
              value={entityType}
              onChange={(e) => {
                setEntityType(e.target.value);
                setPage(1);
              }}
              containerClassName="sm:w-auto"
              className="sm:w-auto min-w-40"
              aria-label="กรองประเภทกิจกรรม"
            >
              {ENTITY_TYPES.map((et) => (
                <option key={et.value} value={et.value}>
                  {et.label}
                </option>
              ))}
            </Select>

            <SearchInput
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="ค้นหากิจกรรม ผู้ดูแล IP หรือรายละเอียด..."
              containerClassName="sm:w-72"
              aria-label="ค้นหาบันทึกกิจกรรม"
            />
          </div>

          <div className="text-xs text-muted-foreground hidden sm:block">
            รายการทั้งหมด: <span className="font-bold text-foreground">{formatNumber(total)}</span> รายการ
          </div>
        </div>

        {/* Audit Log Table */}
        {isLoading ? (
          <TableSkeleton rows={8} cols={6} />
        ) : (
          <div>
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead className="w-12"></TableHead>
                  <TableHead>รหัส</TableHead>
                  <TableHead>กิจกรรม</TableHead>
                  <TableHead>รายการ</TableHead>
                  <TableHead>ผู้ดำเนินการ</TableHead>
                  <TableHead>IP Address / Device</TableHead>
                  <TableHead>เวลาที่บันทึก</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.length === 0 ? (
                  <TableEmpty colSpan={7} message="ไม่พบบันทึกกิจกรรมที่ตรงกับเงื่อนไข" />
                ) : (
                  logs.map((log) => {
                    const isExpanded = expandedLogId === log.id;
                    const variant = getActionBadgeVariant(log.action);

                    return (
                      <Fragment key={log.id}>
                        <TableRow
                          className="cursor-pointer"
                          onClick={() => toggleExpand(log.id)}
                        >
                          <TableCell>
                            <button
                              type="button"
                              className="p-1 rounded text-muted-foreground hover:text-foreground"
                            >
                              {isExpanded ? (
                                <ChevronUp className="size-3.5" />
                              ) : (
                                <ChevronDown className="size-3.5" />
                              )}
                            </button>
                          </TableCell>

                          <TableCell className="font-mono text-[13px] font-semibold text-foreground">
                            #{log.id}
                          </TableCell>

                          <TableCell>
                            <Badge variant={variant} size="sm" withDot>
                              {log.action}
                            </Badge>
                          </TableCell>

                          <TableCell className="font-mono text-[13px]">
                            <span className="text-muted-foreground font-medium">{log.entity_type}</span>{" "}
                            <span className="font-semibold text-foreground">
                              #{log.entity_id || "-"}
                            </span>
                          </TableCell>

                          <TableCell className="text-[13px]">
                            <div className="font-medium text-foreground font-mono">
                              {log.admin_email || log.admin_id || "ผู้ดูแลระบบ"}
                            </div>
                          </TableCell>

                          <TableCell className="font-mono text-[13px] text-foreground">
                            <div>{log.ip_address || "-"}</div>
                            {log.user_agent && (
                              <div className="text-xs text-muted-foreground truncate max-w-[140px]">
                                {log.user_agent}
                              </div>
                            )}
                          </TableCell>

                          <TableCell className="font-mono text-[13px] text-muted-foreground whitespace-nowrap">
                            {formatDate(log.created_at)}
                          </TableCell>
                        </TableRow>

                        {/* Expanded Payload Viewer */}
                        {isExpanded && (
                          <TableRow isHoverable={false} className="bg-muted/20">
                            <TableCell colSpan={7} className="p-4">
                              <div className="p-4 rounded-lg bg-muted/40 border border-border text-xs space-y-3">
                                <div className="flex items-center gap-2 text-primary font-semibold">
                                  <Terminal className="size-4" />
                                  <span>รายละเอียดการเปลี่ยนแปลง</span>
                                </div>

                                {log.reason && (
                                  <div className="p-2.5 rounded bg-card border border-border text-foreground">
                                    <span className="text-warning font-semibold">บันทึกเหตุผล: </span>
                                    {log.reason}
                                  </div>
                                )}

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                  <div>
                                    <div className="text-xs text-muted-foreground font-medium mb-1">
                                      ก่อนเปลี่ยน
                                    </div>
                                    <pre className="p-3 rounded bg-card border border-border text-muted-foreground text-xs font-mono overflow-x-auto">
                                      {log.before_state
                                        ? JSON.stringify(log.before_state, null, 2)
                                        : "null"}
                                    </pre>
                                  </div>

                                  <div>
                                    <div className="text-xs text-success font-medium mb-1">
                                      หลังเปลี่ยน
                                    </div>
                                    <pre className="p-3 rounded bg-card border border-border text-success text-xs font-mono overflow-x-auto">
                                      {log.after_state || log.details
                                        ? JSON.stringify(log.after_state || log.details, null, 2)
                                        : "null"}
                                    </pre>
                                  </div>
                                </div>
                              </div>
                            </TableCell>
                          </TableRow>
                        )}
                      </Fragment>
                    );
                  })
                )}
              </TableBody>
            </Table>

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