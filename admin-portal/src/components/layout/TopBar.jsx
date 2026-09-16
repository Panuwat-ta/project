import { Menu, Moon, Search, Sun } from 'lucide-react';
import IconButton from '../ui/IconButton.jsx';
import { useTheme } from './Theme.jsx';
import { useAuth } from '../../features/auth/AuthContext.jsx';

export default function TopBar({ onMenu, onSearch, liveState = 'offline' }) {
  const { theme, toggle } = useTheme();
  const { user } = useAuth();
  const initial = user?.full_name?.[0] ?? user?.email?.[0] ?? 'ผ';

  return (
    <header className="sticky top-0 z-30 flex h-16 shrink-0 items-center gap-3 border-b border-line bg-surface px-4 md:px-7">
      <IconButton label="เปิดเมนูนำทาง" onClick={onMenu} className="border-transparent md:hidden">
        <Menu size={20} aria-hidden="true" />
      </IconButton>
      <button
        type="button"
        onClick={onSearch}
        className="flex h-10 min-w-0 flex-1 items-center gap-2 rounded-lg border border-line bg-elevated px-3 text-sm text-ink-muted transition-colors duration-150 hover:border-line-strong md:max-w-md"
        aria-label="ค้นหาทั่วไป (Ctrl+K)"
      >
        <Search size={16} aria-hidden="true" className="shrink-0" />
        <span className="truncate">ค้นหารายงาน / ผู้ใช้…</span>
        <kbd className="ml-auto hidden shrink-0 rounded border border-line bg-surface px-1.5 py-0.5 font-mono text-[11px] lg:inline">
          Ctrl+K
        </kbd>
      </button>
      <div className="ml-auto flex items-center gap-2.5">
        <span
          role="status"
          className="hidden items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1 text-xs sm:inline-flex"
        >
          <span
            aria-hidden="true"
            className={`h-1.5 w-1.5 rounded-full ${liveState === 'live' ? 'bg-ok' : liveState === 'reconnecting' ? 'bg-warn' : 'bg-ink-muted'}`}
          />
          {liveState === 'live' ? 'Live' : liveState === 'reconnecting' ? 'กำลังเชื่อมต่อ' : 'ออฟไลน์'}
        </span>
        <IconButton
          label={theme === 'dark' ? 'เปลี่ยนเป็นธีมสว่าง' : 'เปลี่ยนเป็นธีมมืด'}
          onClick={toggle}
          className="border-transparent"
        >
          {theme === 'dark' ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
        </IconButton>
        <span
          className="flex h-8 w-8 items-center justify-center rounded-full bg-action text-[13px] font-semibold text-white"
          title={user?.email ?? ''}
          aria-label={`ผู้ใช้ปัจจุบัน ${user?.email ?? ''}`}
        >
          {initial}
        </span>
      </div>
    </header>
  );
}
