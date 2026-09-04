import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Shield, Lock, Mail, Eye, EyeOff, AlertCircle } from "lucide-react";
import { adminLogin } from "@/lib/api";
import { Button } from "@/components/ui/Button";

export function Login() {
  const [email, setEmail] = useState(import.meta.env.VITE_DEFAULT_ADMIN_USERNAME || "");
  const [password, setPassword] = useState(import.meta.env.VITE_DEFAULT_ADMIN_PASSWORD || "");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const emailInputRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    emailInputRef.current?.focus();
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await adminLogin(email.trim(), password);
      navigate("/admin/dashboard");
    } catch (err) {
      setError(err.message || "การเข้าสู่ระบบล้มเหลว กรุณาตรวจสอบอีเมลและรหัสผ่าน");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#070b12] px-4 font-sans text-slate-100 select-none relative overflow-hidden">
      {/* Background ambient lighting */}
      <div className="absolute top-1/4 -left-32 size-96 rounded-full bg-cyan-500/10 blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 -right-32 size-96 rounded-full bg-indigo-500/10 blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-slate-900/90 rounded-2xl shadow-2xl border border-slate-800 p-8 backdrop-blur-xl relative z-10">
        {/* Header Branding */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="size-14 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center mb-4 shadow-[0_0_20px_rgba(0,229,255,0.15)]">
            <Shield className="size-7 text-cyan-400" />
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white">
            ScamGuard Security Console
          </h1>
          <p className="text-xs text-slate-400 mt-1 font-mono">
            ระบบตรวจสอบและจัดการภาพหลอกลวง (Super Admin)
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleLogin} className="space-y-4">
          {error && (
            <div className="p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs flex items-start gap-2.5">
              <AlertCircle className="size-4 shrink-0 mt-0.5 text-rose-400" />
              <span>{error}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="block text-xs font-medium text-slate-300">อีเมลผู้ดูแลระบบ</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-slate-500 pointer-events-none" />
              <input
                ref={emailInputRef}
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@scamguard.local"
                className="w-full pl-9 pr-3 py-2 rounded-lg bg-slate-950/70 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 outline-none focus:border-cyan-400 focus:ring-1 focus:ring-cyan-400 transition-all font-mono"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="block text-xs font-medium text-slate-300">รหัสผ่าน</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-slate-500 pointer-events-none" />
              <input
                type={showPassword ? "text" : "password"}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full pl-9 pr-10 py-2 rounded-lg bg-slate-950/70 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 outline-none focus:border-cyan-400 focus:ring-1 focus:ring-cyan-400 transition-all font-mono"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
          </div>

          <div className="pt-2">
            <Button
              type="submit"
              variant="primary"
              size="md"
              isLoading={loading}
              className="w-full justify-center"
            >
              เข้าสู่ระบบตรวจสอบ
            </Button>
          </div>
        </form>

        {/* Security Notice */}
        <div className="mt-6 pt-4 border-t border-slate-800/80 text-center">
          <p className="text-[11px] text-slate-500">
            สงวนสิทธิ์เฉพาะเจ้าหน้าที่รักษาความปลอดภัยและผู้ดูแลระบบเท่านั้น
            ทุกกิจกรรมจะถูกบันทึกผ่าน Immutable Audit Trail
          </p>
        </div>
      </div>
    </div>
  );
}
