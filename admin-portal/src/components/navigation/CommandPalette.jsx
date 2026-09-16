import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { CornerDownLeft, FileText, LayoutDashboard, Search, Users } from 'lucide-react';
import { apiRequest } from '../../lib/api-client.js';
import { isInternalPath } from '../../lib/utils.js';
import { searchResponseSchema } from '../../schemas/admin.js';
import { NAV_SECTIONS } from '../../app/route-config.js';
import Dialog from '../ui/Dialog.jsx';

const NAV_ICONS = {
  '/admin/dashboard': LayoutDashboard,
  '/admin/reports': FileText,
  '/admin/users': Users,
};

const FLAT_NAV = NAV_SECTIONS.flatMap((section) => section.items);

export default function CommandPalette({ open, onClose }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [searchState, setSearchState] = useState('idle');
  const [activeIndex, setActiveIndex] = useState(0);
  const [globalError, setGlobalError] = useState(null);
  const navigate = useNavigate();
  const inputRef = useRef(null);
  const listRef = useRef(null);

  useEffect(() => {
    if (!open) {
      setQuery('');
      setResults([]);
      setSearchState('idle');
      setGlobalError(null);
      setActiveIndex(0);
      return;
    }
    const timer = setTimeout(() => inputRef.current?.focus(), 30);
    const keyHandler = (event) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        onClose();
      }
    };
    document.addEventListener('keydown', keyHandler);
    return () => {
      clearTimeout(timer);
      document.removeEventListener('keydown', keyHandler);
    };
  }, [open, onClose]);

  // Global search: fires at 2+ chars, debounced 250ms, aborts stale requests.
  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      setSearchState('idle');
      return undefined;
    }
    setSearchState('loading');
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const data = await apiRequest(`/admin/search?q=${encodeURIComponent(query.trim())}`, {
          schema: searchResponseSchema,
          signal: controller.signal,
        });
        setResults(data.items ?? []);
        setSearchState('done');
        setGlobalError(null);
      } catch (error) {
        if (error?.name === 'AbortError' || error?.name === 'AbortedRequestError') return;
        setSearchState('error');
        setGlobalError(error?.message ?? 'ค้นหาไม่สำเร็จ');
      }
    }, 250);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [query]);

  const navMatches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return FLAT_NAV;
    return FLAT_NAV.filter((item) => item.label.toLowerCase().includes(q));
  }, [query]);

  const go = (url) => {
    if (!isInternalPath(url)) return;
    onClose();
    navigate(url);
  };

  const flatCount = navMatches.length + results.length;

  const onKeyDown = (event) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      setActiveIndex((i) => Math.min(i + 1, flatCount - 1));
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      setActiveIndex((i) => Math.max(i - 1, 0));
    } else if (event.key === 'Enter') {
      event.preventDefault();
      if (activeIndex < navMatches.length) go(navMatches[activeIndex].to);
      else {
        const item = results[activeIndex - navMatches.length];
        if (item) go(item.url);
      }
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title="คำสั่งและการค้นหา" labelledBy="cmd-palette-title">
      <div onKeyDown={onKeyDown}>
        <div className="flex items-center gap-2 rounded-lg border border-line-strong bg-elevated px-3">
          <Search size={16} aria-hidden="true" className="shrink-0 text-ink-muted" />
          <input
            ref={inputRef}
            id="cmd-palette-title"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setActiveIndex(0);
            }}
            placeholder="พิมพ์เพื่อค้นหาเมนูหรือรายงาน…"
            aria-label="ค้นหาเมนูหรือรายงาน"
            aria-expanded="true"
            aria-controls="cmd-palette-list"
            aria-activedescendant={`cmd-opt-${activeIndex}`}
            role="combobox"
            autoComplete="off"
            className="h-11 w-full bg-transparent text-sm outline-none placeholder:text-ink-muted"
          />
          <kbd className="hidden shrink-0 items-center gap-1 rounded border border-line bg-surface px-1.5 py-0.5 font-mono text-[11px] text-ink-muted sm:flex">
            <CornerDownLeft size={12} aria-hidden="true" /> เลือก
          </kbd>
        </div>
        <div id="cmd-palette-list" ref={listRef} role="listbox" aria-label="ผลการค้นหา" className="mt-2 max-h-80 overflow-y-auto">
          {navMatches.map((item, i) => {
            const Icon = NAV_ICONS[item.to] ?? FileText;
            return (
              <button
                key={item.to}
                id={`cmd-opt-${i}`}
                role="option"
                aria-selected={i === activeIndex}
                type="button"
                onClick={() => go(item.to)}
                onMouseEnter={() => setActiveIndex(i)}
                className={`flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-left text-sm ${i === activeIndex ? 'bg-surface-2 font-semibold' : ''}`}
              >
                <Icon size={16} aria-hidden="true" className="shrink-0 text-ink-muted" />
                {item.label}
              </button>
            );
          })}
          {query.trim().length >= 2 && (
            <p className="px-3 pb-1 pt-3 text-xs font-semibold text-ink-muted">
              {searchState === 'loading' ? 'กำลังค้นหา…' : `ผลการค้นหาทั่วไป (${results.length})`}
            </p>
          )}
          {results.map((item, j) => {
            const i = navMatches.length + j;
            return (
              <button
                key={`${item.type}-${item.id}`}
                id={`cmd-opt-${i}`}
                role="option"
                aria-selected={i === activeIndex}
                type="button"
                onClick={() => go(item.url)}
                onMouseEnter={() => setActiveIndex(i)}
                className={`flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-left text-sm ${i === activeIndex ? 'bg-surface-2 font-semibold' : ''}`}
              >
                <FileText size={16} aria-hidden="true" className="shrink-0 text-ink-muted" />
                <span className="min-w-0">
                  <span className="block truncate">{item.title}</span>
                  {item.subtitle && <span className="block truncate text-xs text-ink-muted">{item.subtitle}</span>}
                </span>
              </button>
            );
          })}
          {searchState === 'error' && globalError && (
            <p role="alert" className="px-3 py-2 text-[13px] text-bad">{globalError}</p>
          )}
          {query.trim().length >= 2 && searchState === 'done' && results.length === 0 && navMatches.length === 0 && (
            <p className="px-3 py-4 text-center text-sm text-ink-muted">ไม่พบผลการค้นหา</p>
          )}
        </div>
      </div>
    </Dialog>
  );
}
