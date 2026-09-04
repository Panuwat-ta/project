import { cn } from "@/lib/utils";

export function Tabs({ tabs, activeTab, onChange, className }) {
  return (
    <div
      className={cn(
        "inline-flex p-1 rounded-lg bg-slate-100 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700/60 gap-1",
        className
      )}
    >
      {tabs.map((tab) => {
        const id = typeof tab === "string" ? tab : tab.id || tab.key;
        const label = typeof tab === "string" ? tab : tab.label;
        const count = typeof tab === "object" ? tab.count : undefined;
        const isActive = activeTab === id;

        return (
          <button
            key={id}
            type="button"
            onClick={() => onChange(id)}
            className={cn(
              "px-3 py-1.5 text-xs font-medium rounded-md transition-all outline-none flex items-center gap-1.5 select-none",
              isActive
                ? "bg-white dark:bg-slate-900 text-cyan-700 dark:text-cyan-400 shadow-sm border border-slate-200/80 dark:border-slate-700/80 font-bold"
                : "text-slate-700 dark:text-slate-400 hover:text-slate-950 dark:hover:text-slate-200 font-medium"
            )}
          >
            <span>{label}</span>
            {count !== undefined && (
              <span
                className={cn(
                  "px-1.5 py-0.2 rounded-full text-[10px] font-mono",
                  isActive
                    ? "bg-cyan-500/10 text-cyan-700 dark:text-cyan-400 font-bold"
                    : "bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 font-semibold"
                )}
              >
                {count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
