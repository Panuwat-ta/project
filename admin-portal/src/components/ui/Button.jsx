import { forwardRef } from 'react';
import { Loader2 } from 'lucide-react';
import { cn } from '../../lib/utils.js';

const VARIANTS = {
  primary: 'bg-action text-white hover:bg-action-hover border border-transparent',
  secondary: 'bg-surface text-ink hover:bg-surface-2 border border-line-strong',
  ghost: 'bg-transparent text-ink-2 hover:bg-surface-2 border border-transparent',
  danger: 'bg-bad text-white hover:brightness-95 border border-transparent',
};

const SIZES = {
  sm: 'h-9 px-3 text-[13px]',
  md: 'h-10 px-4 text-sm',
};

const Button = forwardRef(function Button(
  { variant = 'primary', size = 'md', loading = false, disabled, className, children, type = 'button', ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        'inline-flex min-w-10 items-center justify-center gap-2 rounded-lg font-semibold transition-colors duration-150',
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus',
        'disabled:cursor-not-allowed disabled:opacity-60',
        VARIANTS[variant],
        SIZES[size],
        loading && 'min-w-24',
        className,
      )}
      {...rest}
    >
      {loading && <Loader2 size={16} className="animate-spin" aria-hidden="true" />}
      {children}
    </button>
  );
});

export default Button;
