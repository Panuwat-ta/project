import { cn } from '../../lib/utils.js';

const TONES = {
  neutral: 'border-line-strong bg-surface-2 text-ink-2',
  info: 'border-action bg-surface text-action',
  success: 'border-ok bg-surface text-ok',
  warning: 'border-warn bg-surface text-warn',
  danger: 'border-bad bg-surface text-bad',
};

export default function Badge({ tone = 'neutral', icon, children, className }) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-semibold',
        TONES[tone],
        className,
      )}
    >
      {icon}
      {children}
    </span>
  );
}
