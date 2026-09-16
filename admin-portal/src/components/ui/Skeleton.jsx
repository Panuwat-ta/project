import { cn } from '../../lib/utils.js';

export default function Skeleton({ className, label = 'กำลังโหลด' }) {
  return (
    <div role="status" aria-label={label} className={cn('animate-pulse rounded-lg bg-surface-2', className)} />
  );
}

export function SkeletonLines({ rows = 3, className }) {
  return (
    <div role="status" aria-label="กำลังโหลด" className={cn('flex flex-col gap-2', className)}>
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="h-4 animate-pulse rounded bg-surface-2" style={{ width: `${92 - i * 9}%` }} />
      ))}
    </div>
  );
}
