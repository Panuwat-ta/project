import { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import { Bell, Search, Sun, Moon, Menu, Loader2, AlertCircle } from "lucide-react";
import { useTheme } from "@/components/theme-provider";
import { searchGlobal } from "@/lib/api";

export function TopBar({ onMenuClick }) {
  const { theme, setTheme } = useTheme();

  const handleThemeToggle = () => {
    const isSystemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const currentActualTheme = theme === 'system' ? (isSystemDark ? 'dark' : 'light') : theme;
    
    setTheme(currentActualTheme === 'light' ? 'dark' : 'light');
  };

  // Determine which icon to show based on the current resolved theme
  const isSystemDark = typeof window !== 'undefined' && window.matchMedia("(prefers-color-scheme: dark)").matches;
  const currentActualTheme = theme === 'system' ? (isSystemDark ? 'dark' : 'light') : theme;
  const ThemeIcon = currentActualTheme === 'light' ? Sun : Moon;

  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const abortControllerRef = useRef(null);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    if (!query.trim() || query.length < 2) {
      setResults([]);
      setIsSearching(false);
      return;
    }

    const search = async () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      abortControllerRef.current = new AbortController();

      setIsSearching(true);
      try {
        const res = await searchGlobal(query);
        setResults(res.items || []);
        setShowDropdown(true);
      } catch (err) {
        if (err.name !== "AbortError") {
          console.error("Global search failed:", err);
        }
      } finally {
        setIsSearching(false);
      }
    };

    const debounceId = setTimeout(() => {
      search();
    }, 300);

    return () => clearTimeout(debounceId);
  }, [query]);

  return (
    <header className="flex h-14 shrink-0 items-center justify-between border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 md:px-6 z-10 relative">
      <div className="flex-1 flex items-center gap-2 md:gap-4 relative">
        <button 
          onClick={onMenuClick}
          className="p-2 -ml-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md transition-colors md:hidden focus:outline-none focus:ring-2 focus:ring-indigo-500"
          aria-label="Toggle Menu"
        >
          <Menu className="size-5" />
        </button>

        <div className="relative w-full max-w-md hidden md:block" ref={dropdownRef}>
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-slate-400 dark:text-slate-500" />
          <input
            type="search"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              if (e.target.value.length >= 2) setShowDropdown(true);
            }}
            onFocus={() => {
              if (query.length >= 2) setShowDropdown(true);
            }}
            placeholder="Search reports, users, scan IDs..."
            className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 text-sm rounded-md pl-9 pr-3 py-1.5 outline-none focus:border-indigo-500 focus:bg-white dark:focus:bg-slate-900 focus:ring-1 focus:ring-indigo-500 transition-all"
          />
          {isSearching && (
            <div className="absolute right-2.5 top-1/2 -translate-y-1/2">
              <Loader2 className="size-4 animate-spin text-indigo-500" />
            </div>
          )}

          {showDropdown && query.length >= 2 && (
            <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-lg rounded-md overflow-hidden z-50 max-h-96 overflow-y-auto">
              {!isSearching && results.length === 0 ? (
                <div className="p-4 text-center text-sm text-slate-500 dark:text-slate-400">
                  ไม่พบผลลัพธ์
                </div>
              ) : (
                <ul className="divide-y divide-slate-100 dark:divide-slate-800">
                  {results.map((item) => (
                    <li key={`${item.type}-${item.id}`}>
                      <Link
                        to={item.url}
                        onClick={() => setShowDropdown(false)}
                        className="block px-4 py-3 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-slate-900 dark:text-slate-100">{item.title}</span>
                          <span className={`text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full ${
                            item.type === 'user' ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400' :
                            item.type === 'report' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' :
                            'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                          }`}>
                            {item.type}
                          </span>
                        </div>
                        {item.subtitle && (
                          <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 truncate">
                            {item.subtitle}
                          </div>
                        )}
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button 
          onClick={handleThemeToggle}
          title={`Theme: ${theme}`}
          className="relative p-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md transition-colors outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <ThemeIcon className="size-4" />
        </button>

        <button 
          className="relative p-2 text-slate-400 dark:text-slate-500 cursor-not-allowed rounded-md transition-colors"
          title="Notifications (Coming soon)"
        >
          <Bell className="size-4 opacity-50" />
        </button>
      </div>
    </header>
  );
}
