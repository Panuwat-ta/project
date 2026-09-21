import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Shield, Lock, Mail, Eye, EyeOff, AlertCircle } from "lucide-react";
import { adminLogin } from "@/lib/api";
import { Button } from "@/components/ui/Button";

export function Login() {
  const [email, setEmail] = useState(
    import.meta.env.DEV ? (import.meta.env.VITE_DEFAULT_ADMIN_USERNAME || "") : ""
  );
  const [password, setPassword] = useState(
    import.meta.env.DEV ? (import.meta.env.VITE_DEFAULT_ADMIN_PASSWORD || "") : ""
  );
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
    <div className="min-h-screen flex items-center justify-center bg-background px-4 font-sans text-foreground relative overflow-hidden">
      <div className="w-full max-w-md bg-card rounded-xl border border-border p-7 shadow-sm">
        {/* Header Branding */}
        <div className="flex flex-col items-center text-center mb-7">
          <div className="size-10 rounded-lg bg-primary-subtle border border-primary-border flex items-center justify-center mb-4">
            <Shield className="size-5 text-primary" />
          </div>
          <h1 className="text-lg font-bold tracking-tight text-foreground">
            ScamGuard Admin
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            สำหรับผู้ดูแลระบบ
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleLogin} className="space-y-4">
          {error && (
            <div id="login-error" role="alert" className="p-3 rounded-lg bg-danger-subtle border border-danger-border text-danger text-xs flex items-start gap-2.5">
              <AlertCircle className="size-4 shrink-0 mt-0.5 text-danger" />
              <span>{error}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label htmlFor="admin-email" className="block text-[13px] font-semibold text-foreground">อีเมลผู้ดูแลระบบ</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
              <input
                ref={emailInputRef}
                id="admin-email"
                type="email"
                autoComplete="username"
                aria-invalid={error ? true : undefined}
                aria-describedby={error ? "login-error" : undefined}
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@scamguard.local"
                className="w-full h-10 pl-9 pr-3 rounded-lg bg-muted/40 border border-input text-sm text-foreground placeholder:text-muted-foreground outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35 transition-colors font-mono"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="admin-password" className="block text-[13px] font-semibold text-foreground">รหัสผ่าน</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
              <input
                id="admin-password"
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                aria-invalid={error ? true : undefined}
                aria-describedby={error ? "login-error" : undefined}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full h-10 pl-9 pr-10 rounded-lg bg-muted/40 border border-input text-sm text-foreground placeholder:text-muted-foreground outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35 transition-colors font-mono"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-2 top-1/2 -translate-y-1/2 size-8 inline-flex items-center justify-center rounded-md text-muted-foreground hover:text-foreground hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                aria-label={showPassword ? "ซ่อนรหัสผ่าน" : "แสดงรหัสผ่าน"}
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
              เข้าสู่ระบบ
            </Button>
          </div>
        </form>

        {/* Security Notice */}
        <div className="mt-6 pt-4 border-t border-border-subtle text-center">
          <p className="text-xs text-muted-foreground">
            สำหรับผู้ดูแลระบบเท่านั้น กิจกรรมสำคัญจะถูกบันทึกไว้ในประวัติระบบ
          </p>
        </div>
      </div>
    </div>
  );
}
