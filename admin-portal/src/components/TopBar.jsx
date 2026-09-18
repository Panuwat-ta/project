import { Link, useLocation } from "react-router-dom";
import { Menu, Sun, Moon, Monitor, Search, User, ShieldCheck } from "lucide-react";
import { useTheme } from "@/components/theme-provider";

const ROUTE_TITLES = {
  "/admin/dashboard": "ภาพรวม",
  "/admin/reports": "รายงานรอตรวจ",
  "/admin/users": "ผู้ใช้งาน",
  "/admin/models": "โมเดล AI",
  "/admin/dataset": "ส่งออกชุดข้อมูล",
  "/admin/audit-log": "บันทึกกิจกรรม",
  "/admin/profile": "บัญชีและความปลอดภัย",
};

export function TopBar({ onMenuClick, onOpenCommandPalette, isWsConnected = true }) {
  const { theme, setTheme } = useTheme();
  const location = useLocation();

  const handleThemeToggle = () => {
    const order = ["system", "light", "dark"];
    const currentIndex = Math.max(0, order.indexOf(theme));
    setTheme(order[(currentIndex + 1) % order.length]);
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
    )?.[1] || "ScamGuard Admin";

  return (
    <header className="h-14 shrink-0 flex items-center justify-between border-b border-border bg-card text-card-foreground px-4 md:px-6 z-20">
      {/* Left: Mobile Menu & Current Context */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onMenuClick}
          className="size-9 -ml-1.5 inline-flex items-center justify-center text-muted-foreground hover:text-foreground rounded-md md:hidden hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          aria-label="เปิดเมนูด้านข้าง"
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
          className="h-9 flex items-center gap-2 px-3 rounded-lg border border-border bg-muted/60 text-[13px] text-muted-foreground hover:border-primary hover:text-foreground transition-all cursor-pointer select-none font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <Search className="size-3.5 text-muted-foreground" />
          <span className="hidden sm:inline">ค้นหาด่วน...</span>
          <kbd className="px-1.5 py-0.5 text-[10px] font-mono bg-secondary border border-border rounded text-secondary-foreground font-semibold">
            Ctrl K
          </kbd>
        </button>

        {/* Live System Status Pulse */}
        <div
          className="hidden lg:flex h-8 items-center gap-1.5 px-2.5 rounded-full bg-muted border border-border text-xs font-medium text-foreground select-none"
          title={isWsConnected ? "เชื่อมต่อแบบเรียลไทม์" : "ขาดการเชื่อมต่อ"}
        >
          <span
            className={`size-2 rounded-full ${
              isWsConnected ? "bg-success animate-pulse" : "bg-danger"
            }`}
          />
          <span>{isWsConnected ? "เรียลไทม์" : "ขาดการเชื่อมต่อ"}</span>
        </div>

        {/* Theme Toggle */}
        <button
          type="button"
          onClick={handleThemeToggle}
          title={`ธีม: ${theme === "system" ? "ตามระบบ" : theme === "light" ? "สว่าง" : "มืด"}`}
          className="size-9 inline-flex items-center justify-center rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          aria-label="เปลี่ยนธีม"
        >
          {theme === "system" ? (
            <Monitor className="size-4 text-muted-foreground" />
          ) : isDark ? (
            <Sun className="size-4 text-warning" />
          ) : (
            <Moon className="size-4 text-foreground" />
          )}
        </button>

        {/* Profile Link */}
        <Link
          to="/admin/profile"
          className="size-9 inline-flex items-center justify-center rounded-lg text-muted-foreground hover:text-primary hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          title="บัญชีผู้ดูแลระบบ"
          aria-label="เปิดหน้าบัญชีผู้ดูแลระบบ"
        >
          <User className="size-4" />
        </Link>
      </div>
    </header>
  );
}
