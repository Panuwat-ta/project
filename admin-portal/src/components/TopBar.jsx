import { Link, useLocation } from "react-router-dom";
import { Menu, Sun, Moon, Search, User, ShieldCheck } from "lucide-react";
import { useTheme } from "@/components/theme-provider";

const ROUTE_TITLES = {
  "/admin/dashboard": "แดชบอร์ดภาพรวมระบบ",
  "/admin/reports": "คิวตรวจสอบรายงานการหลอกลวง",
  "/admin/users": "จัดการบัญชีผู้ใช้งาน",
  "/admin/models": "การจัดการโมเดล AI (SegFormer & Surya)",
  "/admin/dataset": "ส่งออกชุดข้อมูลวิจัย (Dataset Export)",
  "/admin/audit-log": "บันทึกประวัติการตรวจสอบ (Audit Logs)",
  "/admin/profile": "การตั้งค่าบัญชีและความปลอดภัย",
};

export function TopBar({ onMenuClick, onOpenCommandPalette, isWsConnected = true }) {
  const { theme, setTheme } = useTheme();
  const location = useLocation();

  const handleThemeToggle = () => {
    const isSystemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const currentActualTheme = theme === "system" ? (isSystemDark ? "dark" : "light") : theme;
    setTheme(currentActualTheme === "light" ? "dark" : "light");
  };

  const isDark =
    theme === "dark" ||
    (theme === "system" &&
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches);

  // Find matching title or default
  const activeTitle =
    Object.entries(ROUTE_TITLES).find(([route]) =>
      location.pathname.startsWith(route)
    )?.[1] || "Admin Console";

  return (
    <header className="h-14 shrink-0 flex items-center justify-between border-b border-border bg-card text-card-foreground px-4 md:px-6 z-20">
      {/* Left: Mobile Menu & Current Context */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onMenuClick}
          className="p-1.5 -ml-1.5 text-muted-foreground hover:text-foreground rounded-md md:hidden hover:bg-muted transition-colors"
          aria-label="Open sidebar menu"
        >
          <Menu className="size-5" />
        </button>

        <div className="flex items-center gap-2">
          <ShieldCheck className="size-4 text-primary hidden sm:inline-block" />
          <h1 className="text-sm font-semibold text-foreground">
            {activeTitle}
          </h1>
        </div>
      </div>

      {/* Right: Quick Command Search, Live Status, Theme & Profile */}
      <div className="flex items-center gap-2.5">
        {/* Command Search Trigger */}
        <button
          type="button"
          onClick={onOpenCommandPalette}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-border bg-muted/60 text-xs text-muted-foreground hover:border-primary hover:text-foreground transition-all cursor-pointer select-none font-medium"
        >
          <Search className="size-3.5 text-muted-foreground" />
          <span className="hidden sm:inline">ค้นหาด่วน...</span>
          <kbd className="px-1.5 py-0.5 text-[10px] font-mono bg-secondary border border-border rounded text-secondary-foreground font-semibold">
            Ctrl K
          </kbd>
        </button>

        {/* Live System Status Pulse */}
        <div
          className="hidden lg:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-muted border border-border text-[11px] font-mono font-semibold text-foreground select-none"
          title={isWsConnected ? "WebSocket เชื่อมต่อสมบูรณ์ (Real-time)" : "WebSocket หลุดการเชื่อมต่อ"}
        >
          <span
            className={`size-2 rounded-full ${
              isWsConnected ? "bg-success animate-pulse" : "bg-danger"
            }`}
          />
          <span>{isWsConnected ? "Live Telemetry" : "Offline"}</span>
        </div>

        {/* Theme Toggle */}
        <button
          type="button"
          onClick={handleThemeToggle}
          title={`โหมดปัจจุบัน: ${theme}`}
          className="p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
          aria-label="Toggle theme"
        >
          {isDark ? <Sun className="size-4 text-warning" /> : <Moon className="size-4 text-foreground" />}
        </button>

        {/* Profile Link */}
        <Link
          to="/admin/profile"
          className="p-1.5 rounded-lg text-muted-foreground hover:text-primary hover:bg-muted transition-colors"
          title="โปรไฟล์ Super Admin"
        >
          <User className="size-4" />
        </Link>
      </div>
    </header>
  );
}
