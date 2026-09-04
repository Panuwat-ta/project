import { useState, useEffect, useCallback, useRef, Fragment } from "react";
import {
  Search,
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
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";

const LIMIT = 25;

const ENTITY_TYPES = [
  { value: "All", label: "ทุกประเภท (All Entities)" },
  { value: "report", label: "รายงาน Scam (Report)" },
  { value: "user", label: "บัญชีผู้ใช้ (User)" },
  { value: "model", label: "โมเดล AI (Model)" },
  { value: "dataset", label: "ชุดข้อมูล (Dataset)" },
];

export function AuditLogsList() {
  const [logs, setLogs] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [entityType, setEntityType] = useState("All");
  const [expandedLogId, setExpandedLogId] = useState(null);

  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const searchTimer = useRef(null);
  const toast = useToast();

  useEffect(() => {
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      setDebouncedSearch(search.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(searchTimer.current);
  }, [search]);

  const loadLogs = useCallback(
    async (manual = false) => {
      try {
        if (manual) setIsRefreshing(true);
        else setIsLoading(true);

        const data = await fetchAuditLogs({
          page,
          limit: LIMIT,
          search: debouncedSearch,
          action: "All",
          entity_type: entityType,
        });

        setLogs(data.items || []);
        setTotal(data.total || 0);

        if (manual) toast.success("รีเฟรชบันทึก Audit Logs สำเร็จ");
      } catch (err) {
        console.error("Load audit logs failed:", err);
        toast.error("ไม่สามารถโหลดบันทึก Audit Log ได้: " + err.message);
        setLogs([]);
        setTotal(0);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    [page, debouncedSearch, entityType, toast]
  );

  useEffect(() => {
    loadLogs();
  }, [loadLogs]);

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
          <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <Shield className="size-5 text-cyan-400" />
            <span>บันทึกความมั่นคงปลอดภัย (Security Audit Trail)</span>
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            เก็บบันทึกประวัติการตัดสินใจและการเข้าถึงของ Super Admin แบบ Immutable ย้อนหลัง
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
            รีเฟรชประวัติ
          </Button>
        </div>
      </div>

      {/* Filter and Table Card */}
      <Card>
        <div className="p-4 flex flex-col sm:flex-row items-center justify-between gap-4 border-b border-slate-100 dark:border-slate-800/80">
          <div className="flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto">
            <select
              value={entityType}
              onChange={(e) => {
                setEntityType(e.target.value);
                setPage(1);
              }}
              className="w-full sm:w-auto px-3 py-1.5 bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700/80 text-xs text-slate-800 dark:text-slate-200 rounded-lg outline-none focus:border-cyan-500 font-medium"
            >
              {ENTITY_TYPES.map((et) => (
                <option key={et.value} value={et.value}>
                  {et.label}
                </option>
              ))}
            </select>

            <div className="relative w-full sm:w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-3.5 text-slate-400" />
              <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="ค้นหากิจกรรม, แอดมิน, IP, รายละเอียด..."
                className="w-full pl-8 pr-3 py-1.5 bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700/80 text-xs text-slate-900 dark:text-slate-100 placeholder-slate-400 rounded-lg outline-none focus:border-cyan-500 font-mono"
              />
            </div>
          </div>

          <div className="text-xs font-mono text-slate-500 dark:text-slate-400 hidden sm:block">
            รายการทั้งหมด: <span className="font-semibold text-slate-700 dark:text-slate-300">{formatNumber(total)}</span> รายการ
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
                  <TableHead>Log ID</TableHead>
                  <TableHead>กิจกรรม (Action)</TableHead>
                  <TableHead>เป้าหมาย (Entity)</TableHead>
                  <TableHead>ผู้ดำเนินการ (Actor)</TableHead>
                  <TableHead>IP Address / Device</TableHead>
                  <TableHead>เวลาที่บันทึก</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.length === 0 ? (
                  <TableEmpty colSpan={7} message="ไม่พบบันทึก Audit Log ที่ตรงกับเงื่อนไข" />
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
                              className="p-1 rounded text-slate-400 hover:text-slate-200"
                            >
                              {isExpanded ? (
                                <ChevronUp className="size-3.5" />
                              ) : (
                                <ChevronDown className="size-3.5" />
                              )}
                            </button>
                          </TableCell>

                          <TableCell className="font-mono text-xs font-semibold text-slate-400">
                            #{log.id}
                          </TableCell>

                          <TableCell>
                            <Badge variant={variant} size="sm" withDot>
                              {log.action}
                            </Badge>
                          </TableCell>

                          <TableCell className="font-mono text-xs">
                            <span className="text-slate-600 dark:text-slate-400 font-medium">{log.entity_type}</span>{" "}
                            <span className="font-semibold text-slate-900 dark:text-slate-100">
                              #{log.entity_id || "-"}
                            </span>
                          </TableCell>

                          <TableCell className="text-xs">
                            <div className="font-medium text-slate-900 dark:text-slate-100 font-mono">
                              {log.admin_email || log.admin_id || "Super Admin"}
                            </div>
                          </TableCell>

                          <TableCell className="font-mono text-xs text-slate-700 dark:text-slate-300">
                            <div>{log.ip_address || log.ip || "127.0.0.1"}</div>
                            {log.user_agent && (
                              <div className="text-[10px] text-slate-500 truncate max-w-[140px]">
                                {log.user_agent}
                              </div>
                            )}
                          </TableCell>

                          <TableCell className="font-mono text-xs text-slate-500 whitespace-nowrap">
                            {formatDate(log.created_at)}
                          </TableCell>
                        </TableRow>

                        {/* Expanded Payload Viewer */}
                        {isExpanded && (
                          <TableRow isHoverable={false} className="bg-slate-950/40">
                            <TableCell colSpan={7} className="p-4">
                              <div className="p-4 rounded-lg bg-slate-950 border border-slate-800 font-mono text-xs space-y-3">
                                <div className="flex items-center gap-2 text-cyan-400 font-semibold">
                                  <Terminal className="size-4" />
                                  <span>Structured Audit Payload (Before / After Snapshot)</span>
                                </div>

                                {log.reason && (
                                  <div className="p-2.5 rounded bg-slate-900 border border-slate-800 text-slate-300">
                                    <span className="text-amber-400 font-semibold">บันทึกเหตุผล: </span>
                                    {log.reason}
                                  </div>
                                )}

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                  <div>
                                    <div className="text-[11px] text-slate-400 uppercase tracking-wider mb-1">
                                      สถานะก่อนทำรายการ (Before)
                                    </div>
                                    <pre className="p-3 rounded bg-slate-900 border border-slate-800 text-slate-400 text-[11px] overflow-x-auto">
                                      {log.before_state
                                        ? JSON.stringify(log.before_state, null, 2)
                                        : "null"}
                                    </pre>
                                  </div>

                                  <div>
                                    <div className="text-[11px] text-emerald-400 uppercase tracking-wider mb-1">
                                      สถานะหลังทำรายการ (After)
                                    </div>
                                    <pre className="p-3 rounded bg-slate-900 border border-slate-800 text-emerald-400 text-[11px] overflow-x-auto">
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