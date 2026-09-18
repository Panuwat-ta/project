import { cn } from "@/lib/utils";

export function Tabs({ tabs, activeTab, onChange, className }) {
  const handleKeyDown = (event, index) => {
    let nextIndex = null;

    if (event.key === "ArrowRight") nextIndex = (index + 1) % tabs.length;
    if (event.key === "ArrowLeft") nextIndex = (index - 1 + tabs.length) % tabs.length;
    if (event.key === "Home") nextIndex = 0;
    if (event.key === "End") nextIndex = tabs.length - 1;

    if (nextIndex === null) return;

    event.preventDefault();
    const nextTab = tabs[nextIndex];
    const nextId = typeof nextTab === "string" ? nextTab : nextTab.id || nextTab.key;
    onChange(nextId);

    const tabButtons = event.currentTarget.parentElement?.querySelectorAll('[role="tab"]');
    tabButtons?.[nextIndex]?.focus();
  };

  return (
    <div
      className={cn(
        "flex w-full sm:w-auto overflow-x-auto p-1 rounded-lg bg-muted border border-border gap-1",
        className
      )}
      role="tablist"
      aria-label="ตัวกรองสถานะ"
    >
      {tabs.map((tab, index) => {
        const id = typeof tab === "string" ? tab : tab.id || tab.key;
        const label = typeof tab === "string" ? tab : tab.label;
        const count = typeof tab === "object" ? tab.count : undefined;
        const isActive = activeTab === id;

        return (
          <button
            key={id}
            type="button"
            onClick={() => onChange(id)}
            onKeyDown={(event) => handleKeyDown(event, index)}
            role="tab"
            aria-selected={isActive}
            tabIndex={isActive ? 0 : -1}
            className={cn(
              "shrink-0 h-9 px-3 text-[13px] font-medium rounded-md transition-all outline-none flex items-center gap-1.5 select-none focus-visible:ring-2 focus-visible:ring-ring",
              isActive
                ? "bg-card text-primary shadow-sm border border-border font-bold"
                : "text-muted-foreground hover:text-foreground font-medium"
            )}
          >
            <span>{label}</span>
            {count !== undefined && (
              <span
                className={cn(
                  "px-1.5 py-0.5 rounded-full text-[11px] font-mono",
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
