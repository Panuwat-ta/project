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
  Radio,
} from "lucide-react";
import { logoutAdmin, getStoredUser, fetchDashboard } from "@/lib/api";
import { cn } from "@/lib/utils";

const NAV_GROUPS = [
  {
    label: "ศูนย์บัญชาการ",
    items: [
      { name: "แดชบอร์ดสถิติ", path: "/admin/dashboard", icon: LayoutDashboard },
      { name: "คิวรายงานสแกน", path: "/admin/reports", icon: Flag, showPendingCount: true },
      { name: "จัดการผู้ใช้งาน", path: "/admin/users", icon: Users },
    ],
  },
  {
    label: "โมเดล AI & ชุดข้อมูล",
    items: [
      { name: "โมเดลตรวจจับ (AI)", path: "/admin/models", icon: Cpu },
      { name: "ส่งออกชุดข้อมูล", path: "/admin/dataset", icon: Database },
    ],
  },
  {
    label: "ความปลอดภัย & ระบบ",
    items: [
      { name: "บันทึก Audit Log", path: "/admin/audit-log", icon: FileText },
      { name: "ตั้งค่าโปรไฟล์", path: "/admin/profile", icon: Settings },
    ],
  },
];

export function AppSidebar({ isOpen, setIsOpen }) {
  const location = useLocation();
  const [user, setUser] = useState({ email: "admin@scamguard.local", full_name: "Super Admin" });
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
        "fixed inset-y-0 left-0 w-64 shrink-0 bg-slate-900 border-r border-slate-800 flex flex-col h-full z-40 transition-transform duration-200 ease-in-out md:static md:translate-x-0 select-none",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}
    >
      {/* Brand Header */}
      <div className="h-14 flex items-center justify-between px-4 border-b border-slate-800 bg-slate-950/50">
        <Link to="/admin/dashboard" onClick={handleClose} className="flex items-center gap-2.5">
          <div className="size-7 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 flex items-center justify-center font-bold text-xs shadow-sm">
            <Shield className="size-4 text-cyan-400" />
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-sm text-slate-100 tracking-tight leading-none">
              ScamGuard
            </span>
            <span className="text-[10px] font-mono text-cyan-400 font-semibold tracking-wider uppercase mt-0.5">
              Admin Console
            </span>
          </div>
        </Link>

        <button
          type="button"
          onClick={handleClose}
          className="p-1.5 text-slate-400 hover:text-slate-100 rounded-md hover:bg-slate-800 transition-colors md:hidden"
          aria-label="Close sidebar"
        >
          <X className="size-4" />
        </button>
      </div>

      {/* Navigation Groups */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="space-y-1">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider px-3 pb-1">
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
                    "flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all group outline-none focus-visible:ring-2 focus-visible:ring-cyan-500",
                    isActive
                      ? "bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 font-semibold"
                      : "text-slate-400 hover:bg-slate-800/80 hover:text-slate-200 border border-transparent"
                  )}
                >
                  <div className="flex items-center gap-2.5">
                    <Icon
                      className={cn(
                        "size-4 shrink-0 transition-colors",
                        isActive ? "text-cyan-400" : "text-slate-400 group-hover:text-slate-200"
                      )}
                    />
                    <span>{item.name}</span>
                  </div>

                  {item.showPendingCount && pendingCount > 0 && (
                    <span
                      className={cn(
                        "px-1.5 py-0.5 rounded-full text-[10px] font-mono font-bold transition-colors",
                        isActive
                          ? "bg-rose-500 text-white"
                          : "bg-rose-500/20 text-rose-400 border border-rose-500/30"
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
      <div className="p-3 border-t border-slate-800 bg-slate-950/40">
        <div className="flex items-center justify-between p-2 rounded-lg bg-slate-900 border border-slate-800/80">
          <Link
            to="/admin/profile"
            onClick={handleClose}
            className="flex items-center gap-2.5 min-w-0 flex-1 hover:opacity-85 transition-opacity"
          >
            <div className="size-7 rounded-md bg-cyan-500/20 text-cyan-400 border border-cyan-500/40 flex items-center justify-center font-bold text-xs shrink-0">
              {user.full_name?.substring(0, 2).toUpperCase() || "SA"}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-xs font-medium text-slate-200 truncate">
                {user.full_name || "Super Admin"}
              </div>
              <div className="text-[10px] text-cyan-400 font-mono flex items-center gap-1">
                <Radio className="size-2.5 text-emerald-400 animate-pulse" />
                <span>Super Admin</span>
              </div>
            </div>
          </Link>

          <button
            type="button"
            onClick={logoutAdmin}
            title="ออกจากระบบ (Log out)"
            className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-slate-800 rounded-md transition-colors"
          >
            <LogOut className="size-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}
