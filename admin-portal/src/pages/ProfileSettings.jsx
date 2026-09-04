import { useState, useEffect, useCallback } from "react";
import {
  User,
  Shield,
  Smartphone,
  Laptop,
  Monitor,
  AlertCircle,
  LogOut,
  Clock,
  KeyRound,
} from "lucide-react";
import {
  fetchAdminProfile,
  updateAdminProfile,
  fetchAdminSessions,
  revokeAdminSession,
  logoutAdmin,
} from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from "@/components/ui/Table";
import { Modal } from "@/components/ui/Modal";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate } from "@/lib/utils";

export function ProfileSettings() {
  const [profile, setProfile] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);

  // Change Password Form
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [isUpdatingPassword, setIsUpdatingPassword] = useState(false);

  // Revoke Session Modal
  const [revokeSessionId, setRevokeSessionId] = useState(null);
  const [isRevoking, setIsRevoking] = useState(false);

  const toast = useToast();

  const loadProfileData = useCallback(async () => {
    try {
      setLoading(true);
      const [p, s] = await Promise.all([fetchAdminProfile(), fetchAdminSessions()]);
      setProfile(p);
      setSessions(s.items || []);
    } catch (err) {
      console.error("Load admin profile error:", err);
      toast.error("ไม่สามารถโหลดข้อมูลโปรไฟล์หรือเซสชันได้: " + err.message);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    loadProfileData();
  }, [loadProfileData]);

  const handleUpdatePassword = async (e) => {
    e.preventDefault();
    setPasswordError("");

    if (newPassword.length < 8) {
      setPasswordError("รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 8 ตัวอักษร");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError("รหัสผ่านยืนยันไม่ตรงกับรหัสผ่านใหม่");
      return;
    }

    setIsUpdatingPassword(true);
    try {
      await updateAdminProfile({
        current_password: currentPassword,
        new_password: newPassword,
      });
      toast.success("เปลี่ยนรหัสผ่านสำเร็จเรียบร้อยแล้ว");
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setPasswordError(err.message || "ไม่สามารถเปลี่ยนรหัสผ่านได้ กรุณาตรวจสอบรหัสผ่านเดิม");
    } finally {
      setIsUpdatingPassword(false);
    }
  };

  const confirmRevokeSession = async () => {
    if (!revokeSessionId) return;
    setIsRevoking(true);
    try {
      await revokeAdminSession(revokeSessionId);
      toast.success("เพิกถอนเซสชันสำเร็จ");
      setSessions((prev) => prev.filter((s) => s.id !== revokeSessionId));
      setRevokeSessionId(null);
    } catch (err) {
      toast.error("ไม่สามารถเพิกถอนเซสชันได้: " + err.message);
    } finally {
      setIsRevoking(false);
    }
  };

  const parseDevice = (ua = "") => {
    const l = ua.toLowerCase();
    if (l.includes("mobile") || l.includes("android") || l.includes("iphone")) {
      return { icon: Smartphone, label: "Mobile Device" };
    }
    if (l.includes("mac") || l.includes("windows") || l.includes("linux")) {
      return { icon: Laptop, label: "Workstation / Laptop" };
    }
    return { icon: Monitor, label: "Web Console" };
  };

  if (loading && !profile) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-72 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
          <div className="h-72 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <Shield className="size-5 text-cyan-600 dark:text-cyan-400" />
            <span>การตั้งค่าบัญชีและความปลอดภัย (Profile & Security)</span>
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5">
            จัดการข้อมูล Super Admin, นโยบายรหัสผ่าน และเพิกถอนเซสชันการเข้าใช้งาน (Session Management)
          </p>
        </div>

        <Button
          variant="dangerOutline"
          size="sm"
          icon={LogOut}
          onClick={logoutAdmin}
        >
          ออกจากระบบ
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Profile Info Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="size-4 text-cyan-600 dark:text-cyan-400" />
              <span>ข้อมูลบัญชีผู้ดูแลระบบ (Super Admin)</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800">
              <div className="size-12 rounded-xl bg-cyan-500/20 text-cyan-700 dark:text-cyan-400 border border-cyan-500/30 flex items-center justify-center font-bold text-base">
                {profile?.full_name?.substring(0, 2).toUpperCase() || "SA"}
              </div>
              <div className="min-w-0">
                <div className="text-sm font-bold text-slate-900 dark:text-slate-100">
                  {profile?.full_name || "Super Admin"}
                </div>
                <div className="text-xs text-slate-700 dark:text-slate-300 font-mono font-medium">{profile?.email}</div>
                <div className="flex items-center gap-2 mt-1">
                  <Badge variant="primary" size="sm" withDot>
                    Super Admin
                  </Badge>
                  <Badge variant="success" size="sm">
                    Active
                  </Badge>
                </div>
              </div>
            </div>

            <div className="space-y-2 font-mono text-xs">
              <div className="flex justify-between py-1.5 border-b border-slate-200 dark:border-slate-800">
                <span className="text-slate-600 dark:text-slate-400 font-medium">Account ID:</span>
                <span className="text-slate-900 dark:text-slate-100 font-bold">#{profile?.id || "1"}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-200 dark:border-slate-800">
                <span className="text-slate-600 dark:text-slate-400 font-medium">สิทธิ์การเข้าถึง:</span>
                <span className="text-emerald-700 dark:text-emerald-400 font-bold">Full System Governance (RBAC)</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-600 dark:text-slate-400 font-medium">เข้าสู่ระบบล่าสุด:</span>
                <span className="text-slate-900 dark:text-slate-100 font-bold">{formatDate(profile?.last_login_at || new Date())}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Change Password Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <KeyRound className="size-4 text-cyan-600 dark:text-cyan-400" />
              <span>เปลี่ยนรหัสผ่าน (Change Password)</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleUpdatePassword} className="space-y-4">
              {passwordError && (
                <div className="p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-700 dark:text-rose-400 text-xs flex items-center gap-2">
                  <AlertCircle className="size-4 shrink-0" />
                  <span>{passwordError}</span>
                </div>
              )}

              <div className="space-y-1">
                <label className="block text-xs font-medium text-slate-800 dark:text-slate-300">
                  รหัสผ่านปัจจุบัน
                </label>
                <input
                  type="password"
                  required
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-xs text-slate-900 dark:text-slate-100 outline-none focus:border-cyan-500 font-mono"
                />
              </div>

              <div className="space-y-1">
                <label className="block text-xs font-medium text-slate-800 dark:text-slate-300">
                  รหัสผ่านใหม่ (ขั้นต่ำ 8 ตัวอักษร)
                </label>
                <input
                  type="password"
                  required
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-xs text-slate-900 dark:text-slate-100 outline-none focus:border-cyan-500 font-mono"
                />
              </div>

              <div className="space-y-1">
                <label className="block text-xs font-medium text-slate-800 dark:text-slate-300">
                  ยืนยันรหัสผ่านใหม่
                </label>
                <input
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-xs text-slate-900 dark:text-slate-100 outline-none focus:border-cyan-500 font-mono"
                />
              </div>

              <div className="pt-2 flex justify-end">
                <Button
                  type="submit"
                  variant="primary"
                  size="sm"
                  isLoading={isUpdatingPassword}
                >
                  บันทึกรหัสผ่านใหม่
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>

      {/* Active Sessions Management Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="size-4 text-cyan-600 dark:text-cyan-400" />
            <span>เซสชันการเข้าใช้งานปัจจุบัน (Active Admin Sessions)</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow isHoverable={false}>
                <TableHead>อุปกรณ์ / ไคลเอนต์</TableHead>
                <TableHead>IP Address</TableHead>
                <TableHead>เข้าใช้งานล่าสุด</TableHead>
                <TableHead>สถานะ</TableHead>
                <TableHead className="text-right">การจัดการ</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sessions.length === 0 ? (
                <TableRow isHoverable={false}>
                  <TableCell colSpan={5} className="py-6 text-center text-xs text-slate-600 dark:text-slate-400">
                    ไม่พบข้อมูลเซสชันอื่นในระบบ
                  </TableCell>
                </TableRow>
              ) : (
                sessions.map((sess) => {
                  const dev = parseDevice(sess.user_agent);
                  const Icon = dev.icon;
                  const isCurrent = sess.is_current;

                  return (
                    <TableRow key={sess.id}>
                      <TableCell>
                        <div className="flex items-center gap-2.5">
                          <div className="size-8 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-600 dark:text-slate-400">
                            <Icon className="size-4" />
                          </div>
                          <div>
                            <div className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                              {dev.label}
                            </div>
                            <div className="text-[10px] text-slate-600 dark:text-slate-400 font-mono truncate max-w-xs font-medium">
                              {sess.user_agent || "Web Admin Client"}
                            </div>
                          </div>
                        </div>
                      </TableCell>

                      <TableCell className="font-mono text-xs font-medium text-slate-800 dark:text-slate-200">
                        {sess.ip_address || "127.0.0.1"}
                      </TableCell>

                      <TableCell className="font-mono text-xs text-slate-700 dark:text-slate-400 font-medium">
                        {formatDate(sess.last_active_at || sess.created_at)}
                      </TableCell>

                      <TableCell>
                        {isCurrent ? (
                          <Badge variant="primary" size="sm" withDot>
                            เซสชันปัจจุบัน
                          </Badge>
                        ) : (
                          <Badge variant="default" size="sm">
                            เชื่อมต่ออยู่
                          </Badge>
                        )}
                      </TableCell>

                      <TableCell className="text-right">
                        {!isCurrent && (
                          <Button
                            variant="dangerOutline"
                            size="xs"
                            onClick={() => setRevokeSessionId(sess.id)}
                          >
                            เพิกถอน
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Revoke Session Confirmation Modal */}
      <Modal
        isOpen={!!revokeSessionId}
        onClose={() => setRevokeSessionId(null)}
        title="ยืนยันการเพิกถอนเซสชัน (Revoke Session)"
        description="การเพิกถอนจะบังคับให้อุปกรณ์ดังกล่าวออกจากระบบทันที และไม่สามารถใช้ Refresh Token เดิมได้อีก"
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={() => setRevokeSessionId(null)} disabled={isRevoking}>
              ยกเลิก
            </Button>
            <Button variant="danger" size="sm" isLoading={isRevoking} onClick={confirmRevokeSession}>
              ยืนยันเพิกถอนเซสชัน
            </Button>
          </>
        }
      >
        <p className="text-xs text-slate-700 dark:text-slate-300">
          คุณต้องการเพิกถอน Session ID: <span className="font-mono text-cyan-700 dark:text-cyan-400 font-bold">#{revokeSessionId}</span> หรือไม่?
        </p>
      </Modal>
    </div>
  );
}
