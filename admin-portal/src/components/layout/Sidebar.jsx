import {
  ClipboardList,
  Database,
  FileText,
  LayoutDashboard,
  ScrollText,
  Shapes,
  User,
  Users,
} from 'lucide-react';
import { NavLink } from 'react-router-dom';
import { NAV_SECTIONS } from '../../app/route-config.js';
import { cn } from '../../lib/utils.js';

const ICONS = {
  '/admin/dashboard': LayoutDashboard,
  '/admin/reports': FileText,
  '/admin/users': Users,
  '/admin/models': Shapes,
  '/admin/dataset': Database,
  '/admin/audit-log': ScrollText,
  '/admin/profile': User,
};

export function SidebarNav({ onNavigate }) {
  return (
    <nav aria-label="หลัก" className="flex flex-col gap-5">
      {NAV_SECTIONS.map((section) => (
        <div key={section.id}>
          <p className="px-3 pb-1.5 text-xs text-ink-muted">{section.label}</p>
          <ul className="flex flex-col gap-0.5">
            {section.items.map((item) => {
              const Icon = ICONS[item.to] ?? ClipboardList;
              return (
                <li key={item.to}>
                  <NavLink
                    to={item.to}
                    onClick={onNavigate}
                    className={({ isActive }) =>
                      cn(
                        'flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition-colors duration-150',
                        isActive
                          ? 'bg-surface-2 font-semibold text-ink'
                          : 'text-ink-2 hover:bg-surface-2 hover:text-ink',
                      )
                    }
                  >
                    <Icon size={18} aria-hidden="true" className="shrink-0" />
                    {item.label}
                  </NavLink>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </nav>
  );
}

export default function Sidebar() {
  return (
    <div className="hidden w-[244px] shrink-0 flex-col overflow-y-auto border-r border-line bg-surface px-3 py-4 md:sticky md:top-0 md:flex md:h-screen">
      <div className="flex items-center gap-2.5 px-2 pb-4">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-action text-sm font-bold text-white" aria-hidden="true">
          SG
        </span>
        <span className="text-[15px] font-bold">ScamGuard</span>
      </div>
      <SidebarNav />
    </div>
  );
}
