import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { RefreshCw, Eye, Ban, CheckCircle2 } from "lucide-react";
import { fetchUsers, updateUserStatus } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty, Pagination } from "@/components/ui/Table";
import { StatusBadge, Badge } from "@/components/ui/Badge";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { Modal } from "@/components/ui/Modal";
import { SearchInput, Textarea } from "@/components/ui/Input";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";
import { useAdminQuery } from "@/lib/use-admin-query";
import { useDebouncedValue } from "@/lib/use-debounced-value";

const LIMIT = 15;

export function UsersList() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const debouncedSearch = useDebouncedValue(search, 300, () => setPage(1));

  const {
    data: { users, total },
    isLoading,
    isRefreshing,
    reload: loadUsers,
  } = useAdminQuery(
    async () => {
      const data = await fetchUsers(page, LIMIT, debouncedSearch);
      return { users: data.items || [], total: data.total || 0 };
    },
    {
      deps: [page, debouncedSearch],
      initialData: { users: [], total: 0 },
      successMessage: "รีเฟรชรายชื่อผู้ใช้สำเร็จ",
      errorMessage: "ไม่สามารถโหลดรายชื่อผู้ใช้ได้",
      logPrefix: "Load users error:",
    }
  );

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

  const openStatusModal = (user, targetActive) => {
    setModalState({ isOpen: true, user, targetActive });
    setReason("");
    setReasonError("");
  };

  const resetStatusModal = () => {
    setModalState({ isOpen: false, user: null, targetActive: false });
    setReason("");
    setReasonError("");
  };

  const closeStatusModal = () => {
    if (isSubmitting) return;
    resetStatusModal();
  };

  const handleUpdateStatus = async () => {
    if (!reason.trim()) {
      setReasonError("กรุณาระบุเหตุผล เหตุผลนี้จะถูกบันทึกไว้ในประวัติระบบ");
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
      resetStatusModal();
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
            ผู้ใช้งาน
          </h2>
          <p className="text-[13px] text-muted-foreground mt-0.5">
            ดูข้อมูลผู้ใช้และจัดการสถานะบัญชี
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
            รีเฟรช
          </Button>
        </div>
      </div>

      {/* Filter and Table Card */}
      <Card>
        <div className="p-4 flex items-center justify-between gap-4 border-b border-border-subtle">
          <SearchInput
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="ค้นหาชื่อ อีเมล หรือรหัสผู้ใช้..."
            containerClassName="sm:w-80"
            aria-label="ค้นหาผู้ใช้งาน"
          />

          <div className="text-xs text-muted-foreground hidden sm:block">
            ผู้ใช้ทั้งหมด: <span className="font-bold text-foreground">{formatNumber(total)}</span> บัญชี
          </div>
        </div>

        {isLoading ? (
          <TableSkeleton rows={8} cols={6} />
        ) : (
          <div>
            <div className="hidden md:block">
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead>รหัสผู้ใช้</TableHead>
                  <TableHead>ข้อมูลผู้ใช้งาน</TableHead>
                  <TableHead>สิทธิ์</TableHead>
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
                      <TableRow key={user.id}>
                        {/* ID */}
                        <TableCell>
                          <Link
                            to={`/admin/users/${user.id}`}
                            className="font-mono text-[13px] font-semibold text-foreground hover:text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
                          >
                            #{user.id}
                          </Link>
                        </TableCell>

                        {/* Name / Email */}
                        <TableCell>
                          <div className="text-[13px] font-medium text-foreground">
                            {user.full_name || "ไม่มีชื่อระบุ"}
                          </div>
                          <div className="text-xs font-mono text-muted-foreground font-medium">{user.email}</div>
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
                        <TableCell className="font-mono text-[13px] text-foreground">
                          {formatNumber(user.total_scans ?? user.scans_count ?? 0)} ครั้ง
                        </TableCell>

                        {/* Created At */}
                        <TableCell className="text-[13px] text-muted-foreground font-mono whitespace-nowrap">
                          {formatDate(user.created_at)}
                        </TableCell>

                        {/* Actions */}
                        <TableCell className="text-right">
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
                                  className="text-success border-success-border hover:bg-success-subtle"
                                >
                                  ปลดระงับ
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
            </div>

            <div className="md:hidden divide-y divide-border-subtle">
              {users.length === 0 ? (
                <div className="px-4 py-10 text-center text-sm text-muted-foreground">ไม่พบบัญชีผู้ใช้ที่ค้นหา</div>
              ) : users.map((user) => {
                const isAdmin = user.role === "admin" || user.is_superadmin;
                return (
                  <article key={user.id} className="p-4 space-y-3">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <Link
                          to={`/admin/users/${user.id}`}
                          className="text-sm font-semibold text-foreground hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
                        >
                          {user.full_name || "ไม่มีชื่อระบุ"}
                        </Link>
                        <div className="mt-0.5 text-xs font-mono text-muted-foreground truncate">{user.email}</div>
                        <div className="mt-1 text-xs font-mono text-muted-foreground">#{user.id}</div>
                      </div>
                      <StatusBadge status={user.is_active ? "active" : "banned"} />
                    </div>
                    <div className="flex flex-wrap items-center gap-2 text-[13px]">
                      <Badge variant={isAdmin ? "primary" : "default"} size="sm">{user.role}</Badge>
                      <span className="text-muted-foreground">สแกน <span className="font-mono font-semibold text-foreground">{formatNumber(user.total_scans ?? user.scans_count ?? 0)}</span> ครั้ง</span>
                    </div>
                    <div className="flex items-center justify-between gap-3 border-t border-border-subtle pt-3">
                      <span className="text-xs font-mono text-muted-foreground">{formatDate(user.created_at)}</span>
                      <div className="flex items-center gap-2">
                        <Link
                          to={`/admin/users/${user.id}`}
                          className="inline-flex h-9 items-center justify-center gap-1.5 rounded-md border border-border px-3 text-[13px] font-medium text-foreground transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                        >
                          <Eye className="size-4" />
                          โปรไฟล์
                        </Link>
                        {!isAdmin && (user.is_active ? (
                          <Button variant="dangerOutline" size="sm" icon={Ban} onClick={() => openStatusModal(user, false)}>ระงับ</Button>
                        ) : (
                          <Button variant="outline" size="sm" icon={CheckCircle2} onClick={() => openStatusModal(user, true)} className="text-success border-success-border hover:bg-success-subtle">ปลดระงับ</Button>
                        ))}
                      </div>
                    </div>
                  </article>
                );
              })}
            </div>

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
            label="เหตุผลในการดำเนินการ *"
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