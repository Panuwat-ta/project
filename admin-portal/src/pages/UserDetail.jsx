import { useState, useEffect, useCallback } from "react";
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
import { StatusBadge, Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, TableEmpty } from "@/components/ui/Table";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate, formatNumber } from "@/lib/utils";

export function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();

  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Status Modal State
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [reason, setReason] = useState("");
  const [reasonError, setReasonError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchUserData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getUser(id);
      setUser(data);
    } catch (err) {
      console.error("Fetch user detail error:", err);
      setError(err.message || "ไม่สามารถโหลดข้อมูลผู้ใช้ได้");
      toast.error("เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้");
    } finally {
      setLoading(false);
    }
  }, [id, toast]);

  useEffect(() => {
    fetchUserData();
  }, [fetchUserData]);

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
        <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="h-64 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
          <div className="md:col-span-2 h-64 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4 text-center">
        <div className="size-12 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-500">
          <AlertCircle className="size-6" />
        </div>
        <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">
          ไม่สามารถเปิดโปรไฟล์ผู้ใช้ #{id} ได้
        </h3>
        <p className="text-xs text-slate-600 dark:text-slate-400 max-w-sm">{error || "ไม่พบบัญชีในระบบ"}</p>
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
            className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <ArrowLeft className="size-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2.5">
              <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
                {user.full_name || "บัญชีผู้ใช้"}
              </h2>
              <StatusBadge status={user.is_active ? "active" : "banned"} />
              <Badge variant={isAdmin ? "primary" : "default"} size="sm">
                {user.role}
              </Badge>
            </div>
            <p className="text-xs text-slate-600 dark:text-slate-400 font-mono mt-0.5">
              User ID: #{user.id} • {user.email}
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
            className={!user.is_active ? "text-emerald-500 border-emerald-500/30 hover:bg-emerald-500/10" : ""}
          >
            {user.is_active ? "ระงับการใช้งานบัญชี" : "ปลดการระงับสิทธิ์"}
          </Button>
        )}
      </div>

      {/* Overview Metric Panels */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3.5">
            <div className="size-10 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-600 dark:text-cyan-400 flex items-center justify-center">
              <Activity className="size-5" />
            </div>
            <div>
              <div className="text-xs font-medium text-slate-600 dark:text-slate-400">สแกนสะสมทั้งหมด</div>
              <div className="text-xl font-bold font-mono text-slate-900 dark:text-slate-100">
                {formatNumber(user.total_scans ?? user.scans_count ?? 0)} ครั้ง
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3.5">
            <div className="size-10 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <Flag className="size-5" />
            </div>
            <div>
              <div className="text-xs font-medium text-slate-600 dark:text-slate-400">ส่งรายงาน Scam ทั้งหมด</div>
              <div className="text-xl font-bold font-mono text-slate-900 dark:text-slate-100">
                {formatNumber(user.total_reports ?? 0)} รายการ
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3.5">
            <div className="size-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Clock className="size-5" />
            </div>
            <div>
              <div className="text-xs font-medium text-slate-600 dark:text-slate-400">ลงทะเบียนเมื่อ</div>
              <div className="text-xs font-semibold font-mono text-slate-900 dark:text-slate-100 mt-1">
                {formatDate(user.created_at)}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Details & Activity Table */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Account Info Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="size-4 text-cyan-600 dark:text-cyan-400" />
              <span>ข้อมูลบัญชีผู้ใช้</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 font-mono text-xs">
            <div className="flex items-center justify-between py-1.5 border-b border-slate-200 dark:border-slate-800/80">
              <span className="text-slate-600 dark:text-slate-400 font-medium">ชื่อ-นามสกุล:</span>
              <span className="text-slate-900 dark:text-slate-100 font-sans font-semibold">{user.full_name || "-"}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-slate-200 dark:border-slate-800/80">
              <span className="text-slate-600 dark:text-slate-400 font-medium">อีเมล:</span>
              <span className="text-slate-900 dark:text-slate-100 font-semibold">{user.email}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-slate-200 dark:border-slate-800/80">
              <span className="text-slate-600 dark:text-slate-400 font-medium">ระดับสิทธิ์ (Role):</span>
              <span className="text-slate-900 dark:text-slate-100 font-semibold uppercase">{user.role}</span>
            </div>

            <div className="flex items-center justify-between py-1.5 border-b border-slate-200 dark:border-slate-800/80">
              <span className="text-slate-600 dark:text-slate-400 font-medium">สถานะปัจจุบัน:</span>
              <span className={user.is_active ? "text-emerald-700 dark:text-emerald-400 font-bold" : "text-rose-600 dark:text-rose-400 font-bold"}>
                {user.is_active ? "ปกติ (Active)" : "ถูกระงับ (Banned)"}
              </span>
            </div>

            {user.banned_reason && (
              <div className="py-2 space-y-1">
                <span className="text-rose-600 dark:text-rose-400 font-semibold">เหตุผลการระงับล่าสุด:</span>
                <p className="text-rose-900 dark:text-rose-200 font-sans bg-rose-50 dark:bg-rose-950/40 p-2 rounded border border-rose-200 dark:border-rose-500/30">
                  {user.banned_reason}
                </p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Activity / Scans List */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="size-4 text-cyan-600 dark:text-cyan-400" />
              <span>ประวัติการสแกนล่าสุด (Recent Scan Activity)</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow isHoverable={false}>
                  <TableHead>Scan ID</TableHead>
                  <TableHead>คะแนนความเสี่ยง</TableHead>
                  <TableHead>ระดับผลการตรวจ</TableHead>
                  <TableHead>วันที่สแกน</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentScans.length === 0 ? (
                  <TableEmpty colSpan={4} message="ยังไม่มีประวัติการสแกนรูปภาพจากผู้ใช้นี้" />
                ) : (
                  recentScans.map((scan) => (
                    <TableRow key={scan.id}>
                      <TableCell className="font-mono text-xs font-semibold text-slate-900 dark:text-slate-100">
                        #{scan.id}
                      </TableCell>
                      <TableCell className="font-mono text-xs font-bold text-slate-800 dark:text-slate-200">
                        {scan.risk_score}%
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant={scan.risk_score >= 70 ? "danger" : scan.risk_score >= 40 ? "warning" : "success"}
                          size="sm"
                        >
                          {scan.risk_level || (scan.risk_score >= 70 ? "HIGH" : scan.risk_score >= 40 ? "MEDIUM" : "LOW")}
                        </Badge>
                      </TableCell>
                      <TableCell className="font-mono text-xs text-slate-700 dark:text-slate-400">
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
        description="กรุณาระบุเหตุผลอย่างละเอียดเพื่อบันทึกประวัติลง Audit Trail"
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
