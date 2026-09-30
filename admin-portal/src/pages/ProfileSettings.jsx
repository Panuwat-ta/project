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
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell, Pagination } from "@/components/ui/Table";
import { Modal } from "@/components/ui/Modal";
import { useToast } from "@/components/ui/ToastContext";
import { Input } from "@/components/ui/Input";
import { formatOptionalDate, formatOptionalIdentifier } from "@/lib/display-state";

const SESSION_PAGE_SIZE = 10;

export function ProfileSettings() {
  const [profile, setProfile] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [sessionPage, setSessionPage] = useState(1);
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
      setSessionPage(1);
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

  const totalSessionPages = Math.max(1, Math.ceil(sessions.length / SESSION_PAGE_SIZE));
  const visibleSessions = sessions.slice(
    (sessionPage - 1) * SESSION_PAGE_SIZE,
    sessionPage * SESSION_PAGE_SIZE
  );

  useEffect(() => {
    if (sessionPage > totalSessionPages) {
      setSessionPage(totalSessionPages);
    }
  }, [sessionPage, totalSessionPages]);

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
    if (!ua) return { icon: Monitor, label: "ไม่ทราบอุปกรณ์" };
    const l = ua.toLowerCase();
    if (l.includes("mobile") || l.includes("android") || l.includes("iphone")) {
      return { icon: Smartphone, label: "อุปกรณ์เคลื่อนที่" };
    }
    if (l.includes("mac") || l.includes("windows") || l.includes("linux")) {
      return { icon: Laptop, label: "คอมพิวเตอร์" };
    }
    return { icon: Monitor, label: "เว็บเบราว์เซอร์" };
  };

  if (loading && !profile) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-muted rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-72 bg-muted rounded-xl animate-pulse" />
          <div className="h-72 bg-muted rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Shield className="size-5 text-primary" />
            <span>บัญชีและความปลอดภัย</span>
          </h2>
          <p className="text-[13px] text-muted-foreground mt-0.5">
            จัดการข้อมูลบัญชี รหัสผ่าน และอุปกรณ์ที่เข้าสู่ระบบ
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
              <User className="size-4 text-primary" />
              <span>ข้อมูลผู้ดูแลระบบ</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-4 p-4 rounded-xl bg-muted/40 border border-border">
              <div className="size-12 rounded-xl bg-primary-subtle text-primary border border-primary-border flex items-center justify-center font-bold text-base">
                {profile?.full_name?.substring(0, 2).toUpperCase() || "SA"}
              </div>
              <div className="min-w-0">
                <div className="text-sm font-bold text-foreground">
                  {profile?.full_name || "ผู้ดูแลระบบ"}
                </div>
                <div className="text-xs text-muted-foreground font-mono font-medium">{profile?.email}</div>
                <div className="flex items-center gap-2 mt-1">
                  <Badge variant="primary" size="sm" withDot>
                    {profile?.is_superadmin ? "Superadmin" : (profile?.role || "ไม่ทราบสิทธิ์")}
                  </Badge>
                </div>
              </div>
            </div>

            <div className="space-y-2 text-[13px]">
              <div className="flex justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">รหัสบัญชี:</span>
                <span className="text-foreground font-mono font-bold">{formatOptionalIdentifier(profile?.id, { prefix: "#" })}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">สิทธิ์การเข้าถึง:</span>
                <span className="text-foreground font-bold">{profile?.is_superadmin ? "Superadmin" : (profile?.role || "ไม่ทราบ")}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-muted-foreground font-medium">เข้าสู่ระบบล่าสุด:</span>
                <span className="text-foreground font-mono font-bold">{formatOptionalDate(profile?.last_login_at)}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Change Password Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <KeyRound className="size-4 text-primary" />
              <span>เปลี่ยนรหัสผ่าน</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleUpdatePassword} className="space-y-4">
              {passwordError && (
                <div className="p-3 rounded-lg bg-danger-subtle border border-danger-border text-danger text-xs flex items-center gap-2">
                  <AlertCircle className="size-4 shrink-0" />
                  <span>{passwordError}</span>
                </div>
              )}

              <Input
                type="password"
                label="รหัสผ่านปัจจุบัน"
                required
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                placeholder="••••••••••••"
              />

              <Input
                type="password"
                label="รหัสผ่านใหม่"
                helperText="อย่างน้อย 8 ตัวอักษร"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="••••••••••••"
              />

              <Input
                type="password"
                label="ยืนยันรหัสผ่านใหม่"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="••••••••••••"
              />

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
            <Clock className="size-4 text-primary" />
            <span>อุปกรณ์ที่เข้าสู่ระบบ</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="hidden md:block">
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
                  <TableCell colSpan={5} className="py-6 text-center text-xs text-muted-foreground">
                    ไม่พบข้อมูลเซสชันอื่นในระบบ
                  </TableCell>
                </TableRow>
              ) : (
                visibleSessions.map((sess) => {
                  const dev = parseDevice(sess.user_agent);
                  const Icon = dev.icon;
                  const isCurrent = sess.is_current;

                  return (
                    <TableRow key={sess.id}>
                      <TableCell>
                        <div className="flex items-center gap-2.5">
                          <div className="size-8 rounded-lg bg-muted flex items-center justify-center text-muted-foreground">
                            <Icon className="size-4" />
                          </div>
                          <div>
                            <div className="text-sm font-semibold text-foreground">
                              {dev.label}
                            </div>
                            <div className="text-xs text-muted-foreground font-mono truncate max-w-xs" title={sess.user_agent || "ไม่ทราบข้อมูลไคลเอนต์"}>
                              {sess.user_agent || "ไม่ทราบข้อมูลไคลเอนต์"}
                            </div>
                          </div>
                        </div>
                      </TableCell>

                      <TableCell className="font-mono text-[13px] font-medium text-foreground">
                        {sess.ip_address || "ไม่ทราบ"}
                      </TableCell>

                      <TableCell className="font-mono text-[13px] text-muted-foreground">
                        {formatOptionalDate(sess.last_used_at || sess.created_at)}
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
                            variant="ghost"
                            size="xs"
                            className="text-muted-foreground hover:text-danger hover:bg-danger-subtle"
                            onClick={() => setRevokeSessionId(sess.id)}
                          >
                            ออกจากระบบอุปกรณ์นี้
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
          </div>

          <div className="md:hidden divide-y divide-border-subtle">
            {sessions.length === 0 ? (
              <div className="px-4 py-8 text-center text-sm text-muted-foreground">ไม่พบข้อมูลเซสชันอื่นในระบบ</div>
            ) : visibleSessions.map((sess) => {
              const dev = parseDevice(sess.user_agent);
              const Icon = dev.icon;
              const isCurrent = sess.is_current;
              return (
                <article key={sess.id} className="p-4 space-y-3">
                  <div className="flex items-start gap-3">
                    <div className="size-9 rounded-md bg-muted flex items-center justify-center text-muted-foreground shrink-0">
                      <Icon className="size-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-sm font-semibold text-foreground">{dev.label}</span>
                        {isCurrent ? <Badge variant="primary" size="sm" withDot>เซสชันปัจจุบัน</Badge> : <Badge variant="default" size="sm">เชื่อมต่ออยู่</Badge>}
                      </div>
                      <p className="mt-1 text-xs text-muted-foreground font-mono break-words line-clamp-2">{sess.user_agent || "ไม่ทราบข้อมูลไคลเอนต์"}</p>
                    </div>
                  </div>
                  <dl className="grid grid-cols-2 gap-3 text-xs">
                    <div><dt className="text-muted-foreground">IP Address</dt><dd className="mt-0.5 font-mono text-foreground break-all">{sess.ip_address || "ไม่ทราบ"}</dd></div>
                    <div><dt className="text-muted-foreground">เข้าใช้งานล่าสุด</dt><dd className="mt-0.5 font-mono text-foreground">{formatOptionalDate(sess.last_used_at || sess.created_at)}</dd></div>
                  </dl>
                  {!isCurrent && (
                    <div className="flex justify-end border-t border-border-subtle pt-3">
                      <Button variant="dangerOutline" size="sm" onClick={() => setRevokeSessionId(sess.id)}>ออกจากระบบอุปกรณ์นี้</Button>
                    </div>
                  )}
                </article>
              );
            })}
          </div>

          <Pagination
            page={sessionPage}
            totalPages={totalSessionPages}
            totalItems={sessions.length}
            onPageChange={setSessionPage}
            limit={SESSION_PAGE_SIZE}
          />
        </CardContent>
      </Card>

      {/* Revoke Session Confirmation Modal */}
      <Modal
        isOpen={!!revokeSessionId}
        onClose={() => setRevokeSessionId(null)}
        title="ออกจากระบบอุปกรณ์นี้?"
        description="อุปกรณ์นี้จะถูกออกจากระบบ และต้องเข้าสู่ระบบใหม่หากต้องการใช้งานอีกครั้ง"
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={() => setRevokeSessionId(null)} disabled={isRevoking}>
              ยกเลิก
            </Button>
            <Button variant="danger" size="sm" isLoading={isRevoking} onClick={confirmRevokeSession}>
              ยืนยันออกจากระบบ
            </Button>
          </>
        }
      >
        <p className="text-xs text-foreground">
          เซสชัน <span className="font-mono text-primary font-bold">#{revokeSessionId}</span> จะถูกยกเลิกทันที
        </p>
      </Modal>
    </div>
  );
}
