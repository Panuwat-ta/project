import { cn } from "@/lib/utils";

export function Badge({
  children,
  variant = "default",
  size = "md",
  withDot = false,
  className,
  ...props
}) {
  const variants = {
    default:
      "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700",
    primary:
      "bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border-cyan-500/30",
    success:
      "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30",
    warning:
      "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30",
    danger:
      "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/30",
    info:
      "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/30",
    purple:
      "bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/30",
  };

  const dots = {
    default: "bg-slate-400",
    primary: "bg-cyan-400",
    success: "bg-emerald-400",
    warning: "bg-amber-400",
    danger: "bg-rose-400",
    info: "bg-sky-400",
    purple: "bg-purple-400",
  };

  const sizes = {
    sm: "text-[10px] px-1.5 py-0.5 gap-1",
    md: "text-xs px-2.5 py-0.5 gap-1.5",
    lg: "text-xs px-3 py-1 gap-2",
  };

  return (
    <span
      className={cn(
        "inline-flex items-center font-medium rounded-full border tabular-nums transition-colors",
        variants[variant] || variants.default,
        sizes[size],
        className
      )}
      {...props}
    >
      {withDot && (
        <span
          className={cn(
            "size-1.5 rounded-full shrink-0",
            dots[variant] || dots.default
          )}
        />
      )}
      {children}
    </span>
  );
}

export function RiskBadge({ score, className }) {
  const numericScore = typeof score === "number" ? score : Number(score) || 0;

  let variant = "success";
  let label = "LOW";

  if (numericScore >= 70) {
    variant = "danger";
    label = "HIGH";
  } else if (numericScore >= 40) {
    variant = "warning";
    label = "MEDIUM";
  }

  return (
    <Badge variant={variant} withDot className={cn("font-semibold font-mono", className)}>
      <span>{label}</span>
      <span className="opacity-80">({numericScore})</span>
    </Badge>
  );
}

export function StatusBadge({ status, className }) {
  const s = String(status || "").toLowerCase();

  const config = {
    pending: { variant: "info", label: "Pending", withDot: true },
    reviewing: { variant: "warning", label: "Reviewing", withDot: true },
    approved: { variant: "success", label: "Approved", withDot: true },
    rejected: { variant: "danger", label: "Rejected", withDot: true },
    active: { variant: "success", label: "Active", withDot: true },
    banned: { variant: "danger", label: "Banned", withDot: true },
    deployed: { variant: "primary", label: "Active Model", withDot: true },
    staged: { variant: "default", label: "Staged", withDot: false },
    queued: { variant: "info", label: "Queued", withDot: true },
    running: { variant: "warning", label: "Running", withDot: true },
    succeeded: { variant: "success", label: "Succeeded", withDot: true },
    failed: { variant: "danger", label: "Failed", withDot: true },
    cancelled: { variant: "default", label: "Cancelled", withDot: false },
  };

  const item = config[s] || { variant: "default", label: status, withDot: false };

  return (
    <Badge variant={item.variant} withDot={item.withDot} className={className}>
      {item.label}
    </Badge>
  );
}
