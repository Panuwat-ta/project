import { useEffect, useId, useRef } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import IconButton from './IconButton.jsx';
import { cn } from '../../lib/utils.js';

function useFocusTrap(containerRef, active) {
  useEffect(() => {
    if (!active || !containerRef.current) return undefined;
    const container = containerRef.current;
    const selector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
    const keyHandler = (event) => {
      if (event.key !== 'Tab') return;
      const focusables = Array.from(container.querySelectorAll(selector)).filter(
        (el) => !el.disabled && el.offsetParent !== null,
      );
      if (focusables.length === 0) return;
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    document.addEventListener('keydown', keyHandler);
    return () => document.removeEventListener('keydown', keyHandler);
  }, [containerRef, active]);
}

export default function Dialog({ open, onClose, title, description, children, footer, danger = false, labelledBy }) {
  const titleId = useId();
  const descId = useId();
  const panelRef = useRef(null);
  const triggerRef = useRef(document.activeElement);

  useFocusTrap(panelRef, open);

  useEffect(() => {
    if (!open) return undefined;
    triggerRef.current = document.activeElement;
    panelRef.current?.querySelector('button, input, select, textarea')?.focus();
    const keyHandler = (event) => {
      if (event.key === 'Escape') onClose?.();
    };
    document.addEventListener('keydown', keyHandler);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', keyHandler);
      document.body.style.overflow = '';
      if (triggerRef.current instanceof HTMLElement) triggerRef.current.focus();
    };
  }, [open, onClose]);

  if (!open) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose?.();
      }}
    >
      <div
        ref={panelRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={labelledBy ?? titleId}
        aria-describedby={description ? descId : undefined}
        className="w-full max-w-md rounded-xl border border-line bg-surface p-5 shadow-lg"
      >
        <div className="mb-1 flex items-start gap-3">
          <div className="min-w-0 flex-1">
            <h2 id={titleId} className={cn('text-base font-bold', danger ? 'text-bad' : 'text-ink')}>
              {title}
            </h2>
            {description && (
              <p id={descId} className="mt-1 text-sm text-ink-2">
                {description}
              </p>
            )}
          </div>
          <IconButton label="ปิดหน้าต่าง" onClick={onClose} className="h-9 w-9 shrink-0 border-transparent">
            <X size={18} aria-hidden="true" />
          </IconButton>
        </div>
        <div className="mt-3">{children}</div>
        {footer && <div className="mt-4 flex justify-end gap-2.5">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}
