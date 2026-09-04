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
    <header className="h-14 shrink-0 flex items-center justify-between border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 md:px-6 z-20">
      {/* Left: Mobile Menu & Current Context */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onMenuClick}
          className="p-1.5 -ml-1.5 text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100 rounded-md md:hidden hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          aria-label="Open sidebar menu"
        >
          <Menu className="size-5" />
        </button>

        <div className="flex items-center gap-2">
          <ShieldCheck className="size-4 text-cyan-500 hidden sm:inline-block" />
          <h1 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
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
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950/60 text-xs text-slate-500 hover:border-cyan-500/50 hover:text-slate-800 dark:hover:text-slate-200 transition-all cursor-pointer select-none"
        >
          <Search className="size-3.5 text-slate-400" />
          <span className="hidden sm:inline">ค้นหาด่วน...</span>
          <kbd className="px-1.5 py-0.5 text-[10px] font-mono bg-slate-200/80 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded text-slate-600 dark:text-slate-400">
            Ctrl K
          </kbd>
        </button>

        {/* Live System Status Pulse */}
        <div
          className="hidden lg:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700/60 text-[11px] font-mono font-medium text-slate-600 dark:text-slate-400 select-none"
          title={isWsConnected ? "WebSocket เชื่อมต่อสมบูรณ์ (Real-time)" : "WebSocket หลุดการเชื่อมต่อ"}
        >
          <span
            className={`size-2 rounded-full ${
              isWsConnected ? "bg-emerald-400 animate-pulse" : "bg-rose-400"
            }`}
          />
          <span>{isWsConnected ? "Live Telemetry" : "Offline"}</span>
        </div>

        {/* Theme Toggle */}
        <button
          type="button"
          onClick={handleThemeToggle}
          title={`โหมดปัจจุบัน: ${theme}`}
          className="p-2 rounded-lg text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          aria-label="Toggle theme"
        >
          {isDark ? <Sun className="size-4 text-amber-400" /> : <Moon className="size-4 text-slate-600" />}
        </button>

        {/* Profile Link */}
        <Link
          to="/admin/profile"
          className="p-1.5 rounded-lg text-slate-500 hover:text-cyan-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          title="โปรไฟล์ Super Admin"
        >
          <User className="size-4" />
        </Link>
      </div>
    </header>
  );
}
