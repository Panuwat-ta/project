import { cn } from '../../lib/utils.js';
import { formatNumber } from '../../lib/formatters.js';

const TONES = {
  neutral: 'bg-surface-2 text-ink-2',
  info: 'bg-surface-2 text-action',
  warning: 'bg-surface-2 text-warn',
  danger: 'bg-surface-2 text-bad',
  success: 'bg-surface-2 text-ok',
};

export default function MetricCard({ label, value, icon, supportingText, tone = 'neutral', className }) {
  return (
    <section aria-label={label} className={cn('rounded-xl border border-line bg-surface p-4 sm:p-5', className)}>
      <div className="flex items-start gap-3">
        {icon && (
          <span aria-hidden="true" className={cn('flex h-9 w-9 shrink-0 items-center justify-center rounded-lg', TONES[tone])}>
            {icon}
          </span>
        )}
        <div className="min-w-0">
          <p className="text-[13px] text-ink-2">{label}</p>
          <p className="tnum text-[26px] font-bold leading-tight">{formatNumber(value)}</p>
          {supportingText && <p className="mt-0.5 text-xs text-ink-muted">{supportingText}</p>}
        </div>
      </div>
    </section>
  );
}
