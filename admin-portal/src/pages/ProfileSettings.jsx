import { useState, useEffect } from "react";
import { Lock, LogOut, CheckCircle2, AlertCircle, Laptop, Smartphone, Monitor } from "lucide-react";
import { fetchAdminProfile, updateAdminProfile, fetchAdminSessions, revokeAdminSession } from "@/lib/api";

export function ProfileSettings() {
  const [profile, setProfile] = useState(null);
  const [sessions, setSessions] = useState([]);
  
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const loadData = async () => {
    try {
      const [profRes, sessRes] = await Promise.all([
        fetchAdminProfile(),
        fetchAdminSessions()
      ]);
      setProfile(profRes);
      setSessions(sessRes.items || []);
    } catch (err) {
      setError("ไม่สามารถโหลดข้อมูลโปรไฟล์ได้: " + err.message);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleUpdatePassword = async (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    if (newPassword !== confirmPassword) {
      setError("รหัสผ่านใหม่ไม่ตรงกัน");
      return;
    }
    if (newPassword.length < 8) {
      setError("รหัสผ่านใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร");
      return;
    }

    setLoading(true);
    try {
      await updateAdminProfile({ current_password: currentPassword, new_password: newPassword });
      setSuccess("เปลี่ยนรหัสผ่านสำเร็จ");
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleRevokeSession = async (sessionId) => {
    if (!confirm("คุณแน่ใจหรือไม่ที่จะเพิกถอนเซสชันนี้?")) return;
    try {
      await revokeAdminSession(sessionId);
      setSessions(sessions.filter(s => s.id !== sessionId));
    } catch (err) {
      alert("ไม่สามารถเพิกถอนเซสชันได้: " + err.message);
    }
  };

  const parseUserAgent = (ua) => {
    if (!ua) return { icon: Monitor, name: "Unknown Device" };
    const lowerUA = ua.toLowerCase();
    if (lowerUA.includes("mobile") || lowerUA.includes("android") || lowerUA.includes("iphone")) {
      return { icon: Smartphone, name: "Mobile Device" };
    }
    if (lowerUA.includes("mac") || lowerUA.includes("windows") || lowerUA.includes("linux")) {
      return { icon: Laptop, name: "Desktop" };
    }
    return { icon: Monitor, name: "Device" };
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
          ตั้งค่าโปรไฟล์ <span className="text-lg font-normal text-slate-500 dark:text-slate-400">(Profile Settings)</span>
        </h1>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl shadow-sm border border-slate-200 dark:border-slate-800 p-6 space-y-8">
        
        {/* Read-only Profile info */}
        <div className="space-y-4">
          <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100 tracking-wide uppercase">ข้อมูลบัญชี</h3>
          {profile ? (
            <div className="bg-slate-50 dark:bg-slate-800/50 p-4 rounded-xl border border-slate-200 dark:border-slate-700 flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center text-indigo-700 dark:text-indigo-400 font-bold text-lg flex-shrink-0">
                {profile.full_name?.substring(0, 2).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <div className="font-medium text-slate-900 dark:text-slate-100 truncate">{profile.full_name}</div>
                <div className="text-sm text-slate-500 dark:text-slate-400 truncate">{profile.email}</div>
                <div className="text-xs text-indigo-600 dark:text-indigo-400 font-medium mt-1">Super Admin</div>
              </div>
            </div>
          ) : (
            <div className="h-20 bg-slate-100 dark:bg-slate-800 animate-pulse rounded-xl"></div>
          )}
        </div>

        <div className="h-px bg-slate-200 dark:bg-slate-800"></div>

        {/* Change Password */}
        <div className="space-y-4">
          <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100 tracking-wide uppercase flex items-center gap-2">
            <Lock className="w-4 h-4" /> เปลี่ยนรหัสผ่าน
          </h3>
          
          {error && (
            <div className="flex items-center gap-2 p-3 text-sm text-red-600 bg-red-50 dark:bg-red-900/20 dark:text-red-400 rounded-lg border border-red-100 dark:border-red-800/50">
              <AlertCircle className="w-4 h-4" /> {error}
            </div>
          )}
          
          {success && (
            <div className="flex items-center gap-2 p-3 text-sm text-emerald-600 bg-emerald-50 dark:bg-emerald-900/20 dark:text-emerald-400 rounded-lg border border-emerald-100 dark:border-emerald-800/50">
              <CheckCircle2 className="w-4 h-4" /> {success}
            </div>
          )}

          <form onSubmit={handleUpdatePassword} className="space-y-4 max-w-sm">
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">รหัสผ่านปัจจุบัน</label>
              <input 
                type="password" 
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="w-full px-3 py-2 bg-white dark:bg-slate-800/50 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" 
              />
            </div>
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)</label>
              <input 
                type="password" 
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="w-full px-3 py-2 bg-white dark:bg-slate-800/50 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" 
              />
            </div>
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">ยืนยันรหัสผ่านใหม่</label>
              <input 
                type="password" 
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full px-3 py-2 bg-white dark:bg-slate-800/50 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" 
              />
            </div>
            <button 
              type="submit" 
              disabled={loading || !currentPassword || !newPassword || !confirmPassword}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
            >
              บันทึกรหัสผ่าน
            </button>
          </form>
        </div>

        <div className="h-px bg-slate-200 dark:bg-slate-800"></div>

        {/* Active Sessions */}
        <div className="space-y-4">
          <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100 tracking-wide uppercase">อุปกรณ์ที่เข้าสู่ระบบ</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400">เซสชันทั้งหมดที่กำลังใช้งานบัญชีของคุณอยู่ คุณสามารถกดเพื่อออกจากระบบจากอุปกรณ์อื่นได้</p>
          
          <div className="space-y-3">
            {sessions.filter(s => !s.revoked_at).map(session => {
              const deviceInfo = parseUserAgent(session.user_agent);
              const Icon = deviceInfo.icon;
              return (
                <div key={session.id} className="flex items-center justify-between p-4 bg-white dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 rounded-xl">
                  <div className="flex items-center gap-4 min-w-0">
                    <div className="p-2 bg-slate-100 dark:bg-slate-700 rounded-lg text-slate-600 dark:text-slate-300 flex-shrink-0">
                      <Icon className="w-5 h-5" />
                    </div>
                    <div className="min-w-0">
                      <div className="font-medium text-slate-900 dark:text-slate-100 flex items-center gap-2 flex-wrap">
                        <span className="truncate">{deviceInfo.name}</span>
                        {session.is_current && <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-400 text-xs rounded-full font-semibold whitespace-nowrap">Current</span>}
                      </div>
                      <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 break-words">
                        IP: {session.ip_address} • เข้าใช้งานล่าสุด: {new Date(session.last_used_at || session.created_at).toLocaleString('th-TH')}
                      </div>
                    </div>
                  </div>
                  
                  {!session.is_current && (
                    <button 
                      onClick={() => handleRevokeSession(session.id)}
                      className="p-2 text-red-600 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-500/10 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-red-500"
                      title="ออกจากระบบอุปกรณ์นี้"
                    >
                      <LogOut className="w-5 h-5" />
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>
        
      </div>
    </div>
  );
}
