import { cn } from "@/lib/utils";

export function Tabs({ tabs, activeTab, onChange, className }) {
  return (
    <div
      className={cn(
        "inline-flex p-1 rounded-lg bg-muted border border-border gap-1",
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
                ? "bg-card text-primary shadow-sm border border-border font-bold"
                : "text-muted-foreground hover:text-foreground font-medium"
            )}
          >
            <span>{label}</span>
            {count !== undefined && (
              <span
                className={cn(
                  "px-1.5 py-0.2 rounded-full text-[10px] font-mono",
                  isActive
                    ? "bg-primary-subtle text-primary font-bold"
                    : "bg-secondary text-secondary-foreground font-semibold"
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
