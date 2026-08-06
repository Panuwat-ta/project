import { NavLink } from "react-router-dom";
import { LayoutDashboard, Flag, Users, Cpu, Database, FileText } from "lucide-react";
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

const navItems = [
  { name: "Dashboard", path: "/admin/dashboard", icon: LayoutDashboard },
  { name: "Scam Reports", path: "/admin/reports", icon: Flag, badge: 28 },
  { name: "User Management", path: "/admin/users", icon: Users },
  { name: "AI Models", path: "/admin/models", icon: Cpu },
  { name: "Dataset Export", path: "/admin/dataset", icon: Database },
  { name: "Audit Log", path: "/admin/audit-log", icon: FileText },
];

export function Sidebar() {
  return (
    <aside className="w-[260px] h-screen fixed left-0 top-0 bg-secondary border-r border-border hidden md:flex flex-col z-40 transition-all duration-250 ease-in-out">
      <div className="h-16 flex items-center px-6 border-b border-border">
        <h1 className="text-primary font-heading font-bold text-xl tracking-wide flex items-center gap-2">
          <span className="bg-primary text-primary-foreground p-1 rounded-md text-sm leading-none">SG</span>
          ScamGuard
        </h1>
      </div>
      
      <div className="flex-1 py-6 px-3 flex flex-col gap-1 overflow-y-auto">
        <div className="text-xs font-semibold text-muted-foreground mb-2 px-3 uppercase tracking-wider">
          Menu
        </div>
        
        {navItems.map((item) => (
          <NavLink
            key={item.name}
            to={item.path}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors relative group",
                isActive
                  ? "bg-muted text-primary"
                  : "text-muted-foreground hover:bg-accent hover:text-foreground"
              )
            }
          >
            {({ isActive }) => (
              <>
                {isActive && (
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-8 bg-primary rounded-r-md" />
                )}
                <item.icon className={cn("size-5", isActive ? "text-primary" : "text-muted-foreground group-hover:text-foreground")} />
                <span className="flex-1">{item.name}</span>
                {item.badge && (
                  <Badge variant="destructive" className="h-5 px-1.5 rounded-full text-[10px] min-w-[20px] flex justify-center">
                    {item.badge}
                  </Badge>
                )}
              </>
            )}
          </NavLink>
        ))}
      </div>
      
      <div className="p-4 border-t border-border">
        <div className="bg-muted p-3 rounded-md flex flex-col gap-1">
          <span className="text-xs text-muted-foreground font-medium">System Status</span>
          <div className="flex items-center gap-2">
            <div className="size-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-sm font-semibold text-emerald-500">All Systems Operational</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
