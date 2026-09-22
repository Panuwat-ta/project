import { Link, useLocation } from "react-router-dom";
import { Menu, Sun, Moon, Monitor, Search, User } from "lucide-react";
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

export function TopBar({ onMenuClick, onOpenCommandPalette }) {
  const { theme, setTheme } = useTheme();
  const location = useLocation();

  const themeOptions = [
    { value: "system", label: "ตามระบบ", icon: Monitor },
    { value: "light", label: "สว่าง", icon: Sun },
    { value: "dark", label: "มืด", icon: Moon },
  ];

  // Find matching title or default
  const activeTitle =
    Object.entries(ROUTE_TITLES).find(([route]) =>
      location.pathname.startsWith(route)
    )?.[1] || "ScamGuard Admin";

  return (
    <header className="h-14 shrink-0 flex items-center justify-between border-b border-border bg-card text-card-foreground px-4 md:px-6 z-20">
      {/* Mobile context only. Desktop page headers own the page title. */}
      <div className="flex items-center gap-3 md:hidden">
        <button
          type="button"
          onClick={onMenuClick}
          className="size-9 -ml-1.5 inline-flex items-center justify-center text-muted-foreground hover:text-foreground rounded-md hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          aria-label="เปิดเมนูด้านข้าง"
        >
          <Menu className="size-5" />
        </button>
        <h1 className="text-sm font-semibold text-foreground">{activeTitle}</h1>
      </div>
      <div className="hidden md:block" aria-hidden="true" />

      {/* Right: Quick Command Search, Live Status, Theme & Profile */}
      <div className="flex items-center gap-2.5">
        {/* Command Search Trigger */}
        <button
          type="button"
          onClick={onOpenCommandPalette}
          className="h-9 flex items-center gap-2 px-3 rounded-lg border border-border bg-muted/60 text-[13px] text-muted-foreground hover:border-primary hover:text-foreground transition-colors cursor-pointer select-none font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <Search className="size-3.5 text-muted-foreground" />
          <span className="hidden sm:inline">ค้นหาด่วน...</span>
          <kbd className="px-1.5 py-0.5 text-[10px] font-mono bg-secondary border border-border rounded text-secondary-foreground font-semibold">
            Ctrl K
          </kbd>
        </button>

        {/* Theme selector */}
        <div
          className="inline-flex items-center rounded-full border border-border bg-background/70 p-1 shadow-sm"
          role="group"
          aria-label="เลือกธีม"
        >
          {themeOptions.map(({ value, label, icon: Icon }) => {
            const isActive = theme === value;
            return (
              <button
                key={value}
                type="button"
                onClick={() => setTheme(value)}
                title={`ธีม: ${label}`}
                aria-label={`ใช้ธีม${label}`}
                aria-pressed={isActive}
                className={[
                  "size-7 inline-flex items-center justify-center rounded-full border transition-colors",
                  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 focus-visible:ring-offset-background",
                  isActive
                    ? "border-border bg-muted text-foreground shadow-sm"
                    : "border-transparent text-muted-foreground hover:bg-muted/70 hover:text-foreground",
                ].join(" ")}
              >
                <Icon className="size-3.5" aria-hidden="true" />
              </button>
            );
          })}
        </div>

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
