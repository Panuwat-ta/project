import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  ArrowLeft,
  User,
  Activity,
  Flag,
  Ban,
  CheckCircle2,
  AlertCircle,
  Clock,
} from "lucide-react";
import { getUser, updateUserStatus } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { StatusBadge, Badge, RiskBadge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty } from "@/components/ui/Table";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";
import { formatOptionalMetric } from "@/lib/display-state";
import { useAdminQuery } from "@/lib/use-admin-query";

export function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();

  const {
    data: user,
    isLoading: loading,
    error,
    reload: fetchUserData,
  } = useAdminQuery(() => getUser(id), {
    deps: [id],
    errorMessage: "เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้",
    logPrefix: "Fetch user detail error:",
  });

  // Status Modal State
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [reason, setReason] = useState("");
  const [reasonError, setReasonError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleToggleStatus = async () => {
    if (!reason.trim()) {
      setReasonError("กรุณาระบุเหตุผลการดำเนินการ");
      return;
    }

    setIsSubmitting(true);
    try {
      await updateUserStatus(user.id, !user.is_active, reason.trim());
      toast.success(
        !user.is_active
          ? "ปลดการระงับบัญชีผู้ใช้สำเร็จ"
          : "ระงับการใช้งานบัญชีผู้ใช้สำเร็จ"
      );
      setShowStatusModal(false);
      setReason("");
      fetchUserData();
    } catch (err) {
      toast.error("ดำเนินการไม่สำเร็จ: " + err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-muted rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="h-64 bg-muted rounded-xl animate-pulse" />
          <div className="md:col-span-2 h-64 bg-muted rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4 text-center">
        <div className="size-12 rounded-full bg-danger-subtle flex items-center justify-center text-danger">
          <AlertCircle className="size-6" />
        </div>
        <h3 className="text-base font-semibold text-foreground">
          ไม่สามารถเปิดโปรไฟล์ผู้ใช้ #{id} ได้
        </h3>
        <p className="text-xs text-muted-foreground max-w-sm">{error || "ไม่พบบัญชีในระบบ"}</p>
        <Button variant="primary" size="sm" onClick={() => navigate("/admin/users")}>
          กลับไปรายชื่อผู้ใช้
        </Button>
      </div>
    );
  }

  const isAdmin = user.role === "admin" || user.is_superadmin;
  const recentScans = user.recent_scans || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link
            to="/admin/users"
            className="p-1.5 rounded-lg border border-border text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
            aria-label="กลับไปหน้ารายชื่อผู้ใช้"
          >
            <ArrowLeft className="size-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2.5">
              <h2 className="text-xl font-bold tracking-tight text-foreground">
                {user.full_name || "บัญชีผู้ใช้"}
              </h2>
              <StatusBadge status={user.is_active ? "active" : "banned"} />
              <Badge variant={isAdmin ? "primary" : "default"} size="sm">
                {user.role}
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground font-mono mt-0.5">
              รหัสผู้ใช้ #{user.id} • {user.email}
            </p>
          </div>
        </div>

        {/* Ban / Unban Button */}
        {!isAdmin && (
          <Button
            variant={user.is_active ? "danger" : "outline"}
            size="sm"
            icon={user.is_active ? Ban : CheckCircle2}
            onClick={() => {
              setShowStatusModal(true);
              setReason("");
              setReasonError("");
            }}
            className={!user.is_active ? "text-success border-success-border hover:bg-success-subtle" : ""}
          >
            {user.is_active ? "ระงับการใช้งานบัญชี" : "ปลดการระงับสิทธิ์"}
          </Button>
        )}
      </div>

      {/* Account metrics share one surface so status and activity remain comparable. */}
      <Card>
        <CardContent className="p-0 grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-border-subtle">
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] font-medium text-muted-foreground"><Activity className="size-4 text-primary" />สแกนสะสมทั้งหมด</div>
            <div className="mt-1 text-lg font-bold font-mono text-foreground">{formatNumber(user.total_scans ?? user.scans_count ?? 0)} ครั้ง</div>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] font-medium text-muted-foreground"><Flag className="size-4 text-danger" />รายงานทั้งหมด</div>
            <div className="mt-1 text-lg font-bold font-mono text-foreground">{formatNumber(user.total_reports ?? 0)} รายการ</div>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 text-[13px] font-medium text-muted-foreground"><Clock className="size-4 text-muted-foreground" />ลงทะเบียนเมื่อ</div>
            <div className="mt-1 text-[13px] font-semibold font-mono text-foreground">{formatDate(user.created_at)}</div>
          </div>
        </CardContent>
      </Card>

      {/* Details & Activity Table */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Account Info Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="size-4 text-primary" />
              <span>ข้อมูลบัญชีผู้ใช้</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-[13px]">
            <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
              <span className="text-muted-foreground font-medium">ชื่อ-นามสกุล:</span>
              <span className="text-foreground font-sans font-semibold">{user.full_name || "-"}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
              <span className="text-muted-foreground font-medium">อีเมล:</span>
              <span className="text-foreground font-mono font-semibold">{user.email}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
              <span className="text-muted-foreground font-medium">สิทธิ์:</span>
              <span className="text-foreground font-semibold uppercase">{user.role}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
              <span className="text-muted-foreground font-medium">สถานะปัจจุบัน:</span>
              <span className={user.is_active ? "text-success font-bold" : "text-danger font-bold"}>
                {user.is_active ? "ใช้งาน" : "ถูกระงับ"}
              </span>
            </div>

            {user.ban_reason && (
              <div className="py-2 space-y-1">
                <span className="text-danger font-semibold">เหตุผลการระงับล่าสุด:</span>
                <p className="text-danger font-sans bg-danger-subtle p-2 rounded border border-danger-border">
                  {user.ban_reason}
                </p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Activity / Scans List */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="size-4 text-primary" />
              <span>การสแกนล่าสุด</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead>รหัสการสแกน</TableHead>
                  <TableHead>คะแนนความเสี่ยง</TableHead>
                  <TableHead>ระดับผลการตรวจ</TableHead>
                  <TableHead>สถานะ</TableHead>
                  <TableHead>วันที่สแกน</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentScans.length === 0 ? (
                  <TableEmpty colSpan={5} message="ยังไม่มีประวัติการสแกนรูปภาพจากผู้ใช้นี้" />
                ) : (
                  recentScans.map((scan) => (
                    <TableRow key={scan.id}>
                      <TableCell className="font-mono text-[13px] font-semibold text-foreground">
                        #{scan.id}
                      </TableCell>
                      <TableCell className="font-mono text-[13px] font-bold text-foreground">
                        {formatOptionalMetric(scan.total_risk_score, { suffix: "%" })}
                      </TableCell>
                      <TableCell>
                        <RiskBadge score={scan.total_risk_score} />
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={scan.status} />
                      </TableCell>
                      <TableCell className="font-mono text-[13px] text-muted-foreground">
                        {formatDate(scan.created_at)}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      {/* Suspend Modal */}
      <Modal
        isOpen={showStatusModal}
        onClose={() => setShowStatusModal(false)}
        title={user.is_active ? `ระงับบัญชี: ${user.email}` : `ปลดการระงับ: ${user.email}`}
        description="กรุณาระบุเหตุผล เหตุผลนี้จะถูกบันทึกไว้ในประวัติระบบ"
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={() => setShowStatusModal(false)} disabled={isSubmitting}>
              ยกเลิก
            </Button>
            <Button
              variant={user.is_active ? "danger" : "primary"}
              size="sm"
              isLoading={isSubmitting}
              onClick={handleToggleStatus}
            >
              {user.is_active ? "ยืนยันระงับการใช้งาน" : "ยืนยันปลดระงับ"}
            </Button>
          </>
        }
      >
        <div className="space-y-4 pt-2">
          <Textarea
            label="เหตุผลการดำเนินการ *"
            required
            value={reason}
            onChange={(e) => {
              setReason(e.target.value);
              setReasonError("");
            }}
            placeholder="ระบุสาเหตุ เช่น ตรวจพบบัญชีสร้างรายงานปลอม, บัญชีแอบอ้าง..."
            error={reasonError}
            rows={4}
          />
        </div>
      </Modal>
    </div>
  );
}
