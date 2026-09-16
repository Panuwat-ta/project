import { forwardRef } from 'react';
import { cn } from '../../lib/utils.js';

const IconButton = forwardRef(function IconButton({ label, title, className, children, ...rest }, ref) {
  if (!label && import.meta.env?.DEV) {
    // eslint-disable-next-line no-console
    console.warn('IconButton requires a `label` for accessibility.');
  }
  return (
    <button
      ref={ref}
      type="button"
      aria-label={label}
      title={title ?? label}
      className={cn(
        'inline-flex h-10 w-10 items-center justify-center rounded-lg border border-line-strong bg-surface text-ink',
        'transition-colors duration-150 hover:bg-surface-2',
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus',
        'disabled:cursor-not-allowed disabled:opacity-60',
        className,
      )}
      {...rest}
    >
      {children}
    </button>
  );
});

export default IconButton;
