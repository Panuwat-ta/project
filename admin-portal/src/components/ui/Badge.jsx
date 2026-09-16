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
      "bg-muted text-foreground border-border",
    primary:
      "bg-primary-subtle text-primary border-primary-border",
    success:
      "bg-success-subtle text-success border-success-border",
    warning:
      "bg-warning-subtle text-warning border-warning-border",
    danger:
      "bg-danger-subtle text-danger border-danger-border",
    info:
      "bg-info-subtle text-info border-info-border",
    purple:
      "bg-accent text-accent-foreground border-border",
  };

  const dots = {
    default: "bg-muted-foreground",
    primary: "bg-primary",
    success: "bg-success",
    warning: "bg-warning",
    danger: "bg-danger",
    info: "bg-info",
    purple: "bg-accent-foreground",
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
