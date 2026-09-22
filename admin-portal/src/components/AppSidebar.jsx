import { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  LayoutDashboard,
  Flag,
  Users,
  Cpu,
  Database,
  FileText,
  LogOut,
  Settings,
  Shield,
  X,
} from "lucide-react";
import { logoutAdmin, getStoredUser, fetchDashboard } from "@/lib/api";
import { cn } from "@/lib/utils";

const NAV_GROUPS = [
  {
    label: "งานหลัก",
    items: [
      { name: "ภาพรวม", path: "/admin/dashboard", icon: LayoutDashboard },
      { name: "รายงานรอตรวจ", path: "/admin/reports", icon: Flag, showPendingCount: true },
      { name: "ผู้ใช้งาน", path: "/admin/users", icon: Users },
    ],
  },
  {
    label: "โมเดล AI & ชุดข้อมูล",
    items: [
      { name: "โมเดล AI", path: "/admin/models", icon: Cpu },
      { name: "ส่งออกชุดข้อมูล", path: "/admin/dataset", icon: Database },
    ],
  },
  {
    label: "ความปลอดภัย & ระบบ",
    items: [
      { name: "บันทึกกิจกรรม", path: "/admin/audit-log", icon: FileText },
      { name: "บัญชีและความปลอดภัย", path: "/admin/profile", icon: Settings },
    ],
  },
];

export function AppSidebar({ isOpen, setIsOpen }) {
  const location = useLocation();
  const [user, setUser] = useState(() => getStoredUser() || { email: "", full_name: "Admin" });
  const [pendingCount, setPendingCount] = useState(0);

  useEffect(() => {
    const stored = getStoredUser();
    if (stored) setUser(stored);

    // Fetch pending count for badge
    const loadPending = async () => {
      try {
        const d = await fetchDashboard();
        if (d?.reports?.pending !== undefined) {
          setPendingCount(d.reports.pending);
        }
      } catch {
        // silent fallback
      }
    };
    loadPending();
  }, []);

  const handleClose = () => {
    if (setIsOpen) setIsOpen(false);
  };

  return (
    <aside
      className={cn(
        "fixed inset-y-0 left-0 w-64 shrink-0 bg-sidebar border-r border-sidebar-border text-sidebar-foreground flex flex-col h-full z-40 transition-transform duration-200 ease-in-out md:static md:translate-x-0 select-none",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}
    >
      {/* Brand Header */}
      <div className="h-14 flex items-center justify-between px-4 border-b border-sidebar-border bg-sidebar">
        <Link to="/admin/dashboard" onClick={handleClose} className="flex items-center gap-2.5">
          <div className="size-7 rounded-lg bg-primary/10 border border-primary/30 text-primary flex items-center justify-center font-bold text-xs shadow-sm">
            <Shield className="size-4 text-primary" />
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-sm text-sidebar-foreground tracking-tight leading-none">
              ScamGuard
            </span>
            <span className="text-[11px] text-sidebar-muted font-medium mt-0.5">
              ผู้ดูแลระบบ
            </span>
          </div>
        </Link>

        <button
          type="button"
          onClick={handleClose}
          className="size-8 inline-flex items-center justify-center text-sidebar-muted hover:text-sidebar-foreground rounded-md hover:bg-sidebar-accent transition-colors md:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          aria-label="ปิดเมนูด้านข้าง"
        >
          <X className="size-4" />
        </button>
      </div>

      {/* Navigation Groups */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="space-y-1">
            <div className="text-xs font-semibold text-sidebar-muted px-3 pb-1">
              {group.label}
            </div>

            {group.items.map((item) => {
              const isActive = location.pathname.startsWith(item.path);
              const Icon = item.icon;

              return (
                <Link
                  key={item.name}
                  to={item.path}
                  onClick={handleClose}
                  className={cn(
                    "flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors group outline-none focus-visible:ring-2 focus-visible:ring-ring",
                    isActive
                      ? "bg-primary/10 text-primary border border-primary/20 font-semibold"
                      : "text-sidebar-muted hover:bg-sidebar-accent hover:text-sidebar-foreground border border-transparent"
                  )}
                >
                  <div className="flex items-center gap-2.5">
                    <Icon
                      className={cn(
                        "size-4 shrink-0 transition-colors",
                        isActive ? "text-primary" : "text-sidebar-muted group-hover:text-sidebar-foreground"
                      )}
                    />
                    <span>{item.name}</span>
                  </div>

                  {item.showPendingCount && pendingCount > 0 && (
                    <span
                      className={cn(
                        "px-1.5 py-0.5 rounded-full text-[11px] font-mono font-bold transition-colors",
                        isActive
                          ? "bg-danger text-danger-foreground"
                          : "bg-danger/20 text-danger border border-danger/30"
                      )}
                    >
                      {pendingCount}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Admin User Footer Card */}
      <div className="p-3 border-t border-sidebar-border bg-sidebar">
        <div className="flex items-center justify-between p-2 rounded-lg bg-sidebar-accent border border-sidebar-border">
          <Link
            to="/admin/profile"
            onClick={handleClose}
            className="flex items-center gap-2.5 min-w-0 flex-1 hover:opacity-85 transition-opacity"
          >
            <div className="size-7 rounded-md bg-primary/20 text-primary border border-primary/40 flex items-center justify-center font-bold text-xs shrink-0">
              {user.full_name?.substring(0, 2).toUpperCase() || "SA"}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-sm font-medium text-sidebar-foreground truncate">
                {user.full_name || "ผู้ดูแลระบบ"}
              </div>
              <div className="text-xs text-sidebar-muted">
                ผู้ดูแลระบบ
              </div>
            </div>
          </Link>

          <button
            type="button"
            onClick={logoutAdmin}
            title="ออกจากระบบ"
            className="size-8 inline-flex items-center justify-center text-sidebar-muted hover:text-danger hover:bg-sidebar rounded-md transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <LogOut className="size-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}
