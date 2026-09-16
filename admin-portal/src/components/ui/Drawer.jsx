import { useEffect, useId, useRef } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import IconButton from './IconButton.jsx';

export default function Drawer({ open, onClose, title, children, side = 'right', label }) {
  const titleId = useId();
  const panelRef = useRef(null);
  const triggerRef = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    triggerRef.current = document.activeElement;
    panelRef.current?.querySelector('button')?.focus();
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
      className="fixed inset-0 z-50 bg-black/40"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose?.();
      }}
    >
      <aside
        ref={panelRef}
        role="dialog"
        aria-modal="true"
        aria-label={label ?? (typeof title === 'string' ? title : 'รายละเอียด')}
        className={`absolute top-0 flex h-full w-full max-w-md flex-col border-line bg-surface ${
          side === 'right' ? 'right-0 border-l' : 'left-0 border-r'
        }`}
      >
        <div className="flex items-center gap-3 border-b border-line px-5 py-4">
          <h2 id={titleId} className="min-w-0 flex-1 text-base font-bold">
            {title}
          </h2>
          <IconButton label="ปิดแผงรายละเอียด" onClick={onClose} className="h-9 w-9 shrink-0 border-transparent">
            <X size={18} aria-hidden="true" />
          </IconButton>
        </div>
        <div className="flex-1 overflow-y-auto px-5 py-4">{children}</div>
      </aside>
    </div>,
    document.body,
  );
}
