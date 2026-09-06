import { useState, useEffect, useCallback, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Search, RefreshCw, Eye, Ban, CheckCircle2 } from "lucide-react";
import { fetchUsers, updateUserStatus } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { StatusBadge, Badge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";

const LIMIT = 15;

export function UsersList() {
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const searchTimer = useRef(null);

  // Status Change Modal State
  const [modalState, setModalState] = useState({
    isOpen: false,
    user: null,
    targetActive: false, // true = unban, false = ban
  });
  const [reason, setReason] = useState("");
  const [reasonError, setReasonError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const navigate = useNavigate();
  const toast = useToast();

  useEffect(() => {
    clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      setDebouncedSearch(search.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(searchTimer.current);
  }, [search]);

  const loadUsers = useCallback(
    async (manual = false) => {
      try {
        if (manual) setIsRefreshing(true);
        else setIsLoading(true);

        const data = await fetchUsers(page, LIMIT, debouncedSearch);
        setUsers(data.items || []);
        setTotal(data.total || 0);

        if (manual) toast.success("รีเฟรชรายชื่อผู้ใช้สำเร็จ");
      } catch (err) {
        console.error("Load users error:", err);
        toast.error("ไม่สามารถโหลดรายชื่อผู้ใช้ได้: " + err.message);
        setUsers([]);
        setTotal(0);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    [page, debouncedSearch, toast]
  );

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const openStatusModal = (user, targetActive) => {
    setModalState({ isOpen: true, user, targetActive });
    setReason("");
    setReasonError("");
  };

  const closeStatusModal = () => {
    if (isSubmitting) return;
    setModalState({ isOpen: false, user: null, targetActive: false });
    setReason("");
    setReasonError("");
  };

  const handleUpdateStatus = async () => {
    if (!reason.trim()) {
      setReasonError("กรุณาระบุเหตุผลในการดำเนินการเพื่อบันทึกลง Audit Log");
      return;
    }

    setIsSubmitting(true);
    try {
      await updateUserStatus(modalState.user.id, modalState.targetActive, reason.trim());
      toast.success(
        modalState.targetActive
          ? `ปลดการระงับบัญชี ${modalState.user.email} สำเร็จ`
          : `ระงับการใช้งานบัญชี ${modalState.user.email} สำเร็จ`
      );
      closeStatusModal();
      loadUsers();
    } catch (err) {
      toast.error("ดำเนินการไม่สำเร็จ: " + err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / LIMIT));

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground">
            การจัดการผู้ใช้งาน (User Management)
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            ตรวจสอบประวัติการใช้งาน บัญชีผู้ส่งรายงาน และมาตรการระงับบัญชี (Ban/Unban)
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshing}
            onClick={() => loadUsers(true)}
          >
            รีเฟรชรายชื่อ
          </Button>
        </div>
      </div>

      {/* Filter and Table Card */}
      <Card>
        <div className="p-4 flex items-center justify-between gap-4 border-b border-border-subtle">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-3.5 text-muted-foreground" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="ค้นหาชื่อ, อีเมล, หรือ User ID..."
              className="w-full pl-8 pr-3 py-1.5 bg-card border border-input text-xs text-foreground placeholder:text-muted-foreground rounded-lg outline-none focus:border-ring focus:ring-1 focus:ring-ring transition-all font-mono"
            />
          </div>

          <div className="text-xs font-mono text-muted-foreground hidden sm:block">
            ผู้ใช้ทั้งหมด: <span className="font-bold text-foreground">{formatNumber(total)}</span> บัญชี
          </div>
        </div>

        {isLoading ? (
          <TableSkeleton rows={8} cols={6} />
        ) : (
          <div>
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead>User ID</TableHead>
                  <TableHead>ข้อมูลผู้ใช้งาน</TableHead>
                  <TableHead>สิทธิ์ (Role)</TableHead>
                  <TableHead>สถานะ</TableHead>
                  <TableHead>สแกนสะสม</TableHead>
                  <TableHead>วันที่ลงทะเบียน</TableHead>
                  <TableHead className="text-right">การจัดการ</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableEmpty colSpan={7} message="ไม่พบบัญชีผู้ใช้ที่ค้นหา" />
                ) : (
                  users.map((user) => {
                    const isAdmin = user.role === "admin" || user.is_superadmin;
                    return (
                      <TableRow
                        key={user.id}
                        className="cursor-pointer"
                        onClick={() => navigate(`/admin/users/${user.id}`)}
                      >
                        {/* ID */}
                        <TableCell className="font-mono text-xs font-semibold text-foreground">
                          #{user.id}
                        </TableCell>

                        {/* Name / Email */}
                        <TableCell>
                          <div className="text-xs font-medium text-foreground">
                            {user.full_name || "ไม่มีชื่อระบุ"}
                          </div>
                          <div className="text-[10px] font-mono text-muted-foreground font-medium">{user.email}</div>
                        </TableCell>

                        {/* Role */}
                        <TableCell>
                          <Badge variant={isAdmin ? "primary" : "default"} size="sm">
                            {user.role}
                          </Badge>
                        </TableCell>

                        {/* Status */}
                        <TableCell>
                          <StatusBadge status={user.is_active ? "active" : "banned"} />
                        </TableCell>

                        {/* Total Scans */}
                        <TableCell className="font-mono text-xs text-foreground">
                          {formatNumber(user.total_scans ?? user.scans_count ?? 0)} ครั้ง
                        </TableCell>

                        {/* Created At */}
                        <TableCell className="text-xs text-muted-foreground font-mono whitespace-nowrap">
                          {formatDate(user.created_at)}
                        </TableCell>

                        {/* Actions */}
                        <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                          <div className="flex items-center justify-end gap-2">
                            <Button
                              variant="ghost"
                              size="xs"
                              icon={Eye}
                              onClick={() => navigate(`/admin/users/${user.id}`)}
                            >
                              โปรไฟล์
                            </Button>

                            {!isAdmin && (
                              user.is_active ? (
                                <Button
                                  variant="dangerOutline"
                                  size="xs"
                                  icon={Ban}
                                  onClick={() => openStatusModal(user, false)}
                                >
                                  ระงับ
                                </Button>
                              ) : (
                                <Button
                                  variant="outline"
                                  size="xs"
                                  icon={CheckCircle2}
                                  onClick={() => openStatusModal(user, true)}
                                  className="text-emerald-500 border-emerald-500/30 hover:bg-emerald-500/10"
                                >
                                  ปลดแบน
                                </Button>
                              )
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
              totalPages={totalPages}
              totalItems={total}
              onPageChange={(p) => setPage(p)}
              limit={LIMIT}
            />
          </div>
        )}
      </Card>

      {/* Suspend / Unban Confirmation Modal */}
      <Modal
        isOpen={modalState.isOpen}
        onClose={closeStatusModal}
        title={
          modalState.targetActive
            ? `ปลดการระงับสิทธิ์บัญชี: ${modalState.user?.email}`
            : `ระงับการใช้งานบัญชี: ${modalState.user?.email}`
        }
        description={
          modalState.targetActive
            ? "ผู้ใช้จะสามารถเข้าสู่ระบบและใช้งานการสแกนภาพได้ตามปกติ"
            : "ผู้ใช้จะไม่สามารถเข้าใช้งานระบบได้จนกว่าผู้ดูแลระบบจะปลดการระงับ"
        }
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={closeStatusModal} disabled={isSubmitting}>
              ยกเลิก
            </Button>
            <Button
              variant={modalState.targetActive ? "primary" : "danger"}
              size="sm"
              isLoading={isSubmitting}
              onClick={handleUpdateStatus}
            >
              {modalState.targetActive ? "ยืนยันปลดระงับ" : "ระงับการใช้งาน"}
            </Button>
          </>
        }
      >
        <div className="space-y-4 pt-2">
          <Textarea
            label="เหตุผลในการดำเนินการ (Audit Reason) *"
            required
            value={reason}
            onChange={(e) => {
              setReason(e.target.value);
              setReasonError("");
            }}
            placeholder="ระบุเหตุผล เช่น พบพฤติกรรมส่งรายงานเท็จซ้ำซาก, มีการสร้างบัญชีสแปม..."
            error={reasonError}
            rows={4}
          />
        </div>
      </Modal>
    </div>
  );
}