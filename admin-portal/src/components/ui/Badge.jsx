import { cn } from "@/lib/utils";
import { getEvidenceState, getOperationalStatus, getRiskState } from "@/lib/display-state";

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
    sm: "text-xs px-1.5 py-0.5 gap-1",
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
  const risk = getRiskState(score);

  if (!risk.available) {
    return (
      <Badge variant="default" className={cn("font-semibold", className)}>
        ไม่ทราบ
      </Badge>
    );
  }

  return (
    <Badge variant={risk.variant} withDot className={cn("font-semibold", className)}>
      <span>{risk.label}</span>
      <span className="opacity-80 font-mono">({risk.score})</span>
    </Badge>
  );
}

export function OperationalStatusBadge({ status, className }) {
  const item = getOperationalStatus(status);
  return (
    <Badge
      variant={item.variant}
      withDot={item.variant !== "default"}
      className={cn("font-semibold", className)}
    >
      {item.label}
    </Badge>
  );
}

export function EvidenceState({ status, className }) {
  const item = getEvidenceState(status);
  return (
    <Badge variant={item.variant} className={cn("font-semibold", className)}>
      {item.label}
    </Badge>
  );
}

export function StatusBadge({ status, className }) {
  const s = String(status || "").toLowerCase();

  const config = {
    pending: { variant: "info", label: "รอตรวจ", withDot: true },
    reviewing: { variant: "warning", label: "กำลังตรวจ", withDot: true },
    approved: { variant: "success", label: "ยืนยันแล้ว", withDot: true },
    rejected: { variant: "danger", label: "ปฏิเสธ", withDot: true },
    active: { variant: "success", label: "ใช้งาน", withDot: true },
    banned: { variant: "danger", label: "ระงับ", withDot: true },
    deployed: { variant: "primary", label: "กำลังใช้งาน", withDot: true },
    staged: { variant: "default", label: "รอใช้งาน", withDot: false },
    queued: { variant: "info", label: "รอคิว", withDot: true },
    running: { variant: "warning", label: "กำลังทำงาน", withDot: true },
    processing_source: { variant: "warning", label: "กำลังตรวจแหล่งที่มา", withDot: true },
    processing_visual: { variant: "warning", label: "กำลังวิเคราะห์ภาพ", withDot: true },
    processing_text: { variant: "warning", label: "กำลังวิเคราะห์ข้อความ", withDot: true },
    completed: { variant: "success", label: "เสร็จสิ้น", withDot: true },
    succeeded: { variant: "success", label: "สำเร็จ", withDot: true },
    failed: { variant: "danger", label: "ล้มเหลว", withDot: true },
    canceled: { variant: "default", label: "ยกเลิก", withDot: false },
    cancelled: { variant: "default", label: "ยกเลิก", withDot: false },
  };

  const item = config[s] || { variant: "default", label: status, withDot: false };

  return (
    <Badge variant={item.variant} withDot={item.withDot} className={className}>
      {item.label}
    </Badge>
  );
}
