import { forwardRef } from 'react';
import { cn } from '../../lib/utils.js';

function FieldShell({ label, id, description, error, disabledReason, disabled, children, className }) {
  const descId = description ? `${id}-desc` : undefined;
  const errId = error ? `${id}-error` : undefined;
  return (
    <div className={cn('flex flex-col gap-1.5', className)}>
      {label && (
        <label htmlFor={id} className="text-sm font-semibold text-ink">
          {label}
        </label>
      )}
      {children({ descId, errId })}
      {description && !error && (
        <p id={descId} className="text-xs text-ink-muted">
          {description}
        </p>
      )}
      {error && (
        <p id={errId} role="alert" className="text-xs font-medium text-bad">
          {error}
        </p>
      )}
      {disabled && disabledReason && (
        <p className="text-xs text-ink-muted">{disabledReason}</p>
      )}
    </div>
  );
}

const baseInput =
  'h-10 w-full rounded-lg border border-line-strong bg-surface px-3 text-sm text-ink placeholder:text-ink-muted transition-colors duration-150 hover:border-ink-muted focus-visible:border-action focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-60';

export const Input = forwardRef(function Input(
  { id, label, description, error, disabledReason, className, ...rest },
  ref,
) {
  return (
    <FieldShell id={id} label={label} description={description} error={error} disabledReason={disabledReason} disabled={rest.disabled}>
      {({ descId, errId }) => (
        <input
          ref={ref}
          id={id}
          aria-describedby={[descId, errId].filter(Boolean).join(' ') || undefined}
          aria-invalid={error ? true : undefined}
          className={cn(baseInput, error && 'border-bad', className)}
          {...rest}
        />
      )}
    </FieldShell>
  );
});

export const Textarea = forwardRef(function Textarea(
  { id, label, description, error, disabledReason, className, rows = 4, ...rest },
  ref,
) {
  return (
    <FieldShell id={id} label={label} description={description} error={error} disabledReason={disabledReason} disabled={rest.disabled}>
      {({ descId, errId }) => (
        <textarea
          ref={ref}
          id={id}
          rows={rows}
          aria-describedby={[descId, errId].filter(Boolean).join(' ') || undefined}
          aria-invalid={error ? true : undefined}
          className={cn(baseInput, 'h-auto min-h-24 py-2', error && 'border-bad', className)}
          {...rest}
        />
      )}
    </FieldShell>
  );
});

export const Select = forwardRef(function Select(
  { id, label, description, error, disabledReason, className, children, ...rest },
  ref,
) {
  return (
    <FieldShell id={id} label={label} description={description} error={error} disabledReason={disabledReason} disabled={rest.disabled}>
      {({ descId, errId }) => (
        <select
          ref={ref}
          id={id}
          aria-describedby={[descId, errId].filter(Boolean).join(' ') || undefined}
          aria-invalid={error ? true : undefined}
          className={cn(baseInput, error && 'border-bad', className)}
          {...rest}
        >
          {children}
        </select>
      )}
    </FieldShell>
  );
});
