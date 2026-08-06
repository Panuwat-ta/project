import { Link, useNavigate, useLocation } from "react-router-dom";
import { LayoutDashboard, Flag, Users, Cpu, Database, FileText, LogOut, Settings, X } from "lucide-react";
import { useState, useEffect } from "react";

const navItems = [
  { name: "Dashboard", path: "/admin/dashboard", icon: LayoutDashboard },
  { name: "Scam Reports", path: "/admin/reports", icon: Flag },
  { name: "User Management", path: "/admin/users", icon: Users },
  { name: "AI Models", path: "/admin/models", icon: Cpu },
  { name: "Dataset Export", path: "/admin/dataset", icon: Database },
  { name: "Audit Log", path: "/admin/audit-log", icon: FileText },
];

export function AppSidebar({ isOpen, setIsOpen }) {
  const navigate = useNavigate();
  const location = useLocation();
  const [user, setUser] = useState({ email: "admin@scamguard.com", full_name: "Super Admin" });
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  useEffect(() => {
    const storedUser = localStorage.getItem("user");
    if (storedUser) {
      setUser(JSON.parse(storedUser));
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    navigate("/login");
  };

  const closeSidebar = () => {
    if (setIsOpen) setIsOpen(false);
  };

  return (
    <aside className={`fixed inset-y-0 left-0 w-64 shrink-0 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col h-full z-30 transform transition-transform duration-200 ease-in-out md:static md:translate-x-0 ${isOpen ? "translate-x-0" : "-translate-x-full"}`}>
      <div className="h-14 flex items-center justify-between px-4 border-b border-slate-200 dark:border-slate-800">
        <div className="flex items-center gap-2">
          <div className="bg-indigo-600 text-white p-1 rounded text-xs font-bold leading-none shadow-sm">
            SG
          </div>
          <span className="font-semibold text-slate-900 dark:text-slate-100 tracking-tight">ScamGuard</span>
        </div>
        
        {/* Close Button on Mobile */}
        <button 
          onClick={closeSidebar}
          className="p-1.5 text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors md:hidden focus:outline-none"
        >
          <X className="size-5" />
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto p-3 space-y-1">
        <div className="text-xs font-medium text-slate-400 dark:text-slate-500 uppercase tracking-wider mb-2 px-2 mt-4">Menu</div>
        {navItems.map((item) => {
          const isActive = location.pathname.startsWith(item.path);
          return (
            <Link
              key={item.name}
              to={item.path}
              onClick={closeSidebar}
              className={`flex items-center justify-between px-3 py-2 rounded-md text-sm transition-colors ${isActive ? "bg-indigo-50 dark:bg-indigo-500/10 text-indigo-700 dark:text-indigo-400 font-medium" : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-slate-100"
                }`}
            >
              <div className="flex items-center gap-3">
                <item.icon className={`size-4 ${isActive ? "text-indigo-600 dark:text-indigo-400" : "text-slate-400 dark:text-slate-500"}`} />
                <span>{item.name}</span>
              </div>
              {item.badge && (
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${isActive ? "bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-400" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400"
                  }`}>
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="p-3 border-t border-slate-200 dark:border-slate-800 relative">
        <button
          onClick={() => setIsDropdownOpen(!isDropdownOpen)}
          className="flex items-center gap-3 w-full p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors text-left outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
        >
          <div className="size-8 rounded bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-400 flex items-center justify-center font-bold text-sm shrink-0">
            {user.full_name.substring(0, 2).toUpperCase()}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-slate-900 dark:text-slate-100 truncate">{user.full_name}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{user.email}</p>
          </div>
        </button>

        {isDropdownOpen && (
          <div className="absolute bottom-full left-3 w-56 mb-2 bg-white dark:bg-slate-900 rounded-md shadow-lg border border-slate-200 dark:border-slate-800 py-1 overflow-hidden">
            <button className="w-full text-left px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-slate-100 flex items-center gap-2 transition-colors">
              <Settings className="size-4 text-slate-400 dark:text-slate-500" />
              Profile Settings
            </button>
            <div className="h-px bg-slate-100 dark:bg-slate-800 my-1"></div>
            <button
              onClick={handleLogout}
              className="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center gap-2 transition-colors"
            >
              <LogOut className="size-4 text-red-500 dark:text-red-400" />
              Log out
            </button>
          </div>
        )}
      </div>
    </aside>
  );
}
