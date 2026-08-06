import { Bell, Search } from "lucide-react";

export function TopBar() {
  return (
    <header className="flex h-14 shrink-0 items-center justify-between border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 md:px-6 z-10">
      <div className="flex-1 flex items-center gap-4">
        <div className="relative w-full max-w-md hidden md:block">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-slate-400 dark:text-slate-500" />
          <input
            type="search"
            placeholder="Search reports, users, scan IDs..."
            className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 text-sm rounded-md pl-9 pr-3 py-1.5 outline-none focus:border-indigo-500 focus:bg-white dark:focus:bg-slate-900 focus:ring-1 focus:ring-indigo-500 transition-all"
          />
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button className="relative p-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-md transition-colors outline-none focus:ring-2 focus:ring-indigo-500">
          <Bell className="size-4" />
          <span className="absolute top-1.5 right-1.5 size-2 rounded-full bg-red-500 border-[1.5px] border-white dark:border-slate-900"></span>
        </button>
      </div>
    </header>
  );
}
