import { createContext, useCallback, useContext, useMemo, useRef, useState } from 'react';
import { CheckCircle2, Info, TriangleAlert, X } from 'lucide-react';

const ToastContext = createContext(null);
let nextId = 1;

const ICONS = {
  success: <CheckCircle2 size={18} aria-hidden="true" className="text-ok" />,
  info: <Info size={18} aria-hidden="true" className="text-action" />,
  error: <TriangleAlert size={18} aria-hidden="true" className="text-bad" />,
};

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const timers = useRef(new Map());

  const dismiss = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
    const timer = timers.current.get(id);
    if (timer) {
      clearTimeout(timer);
      timers.current.delete(id);
    }
  }, []);

  const push = useCallback(
    (message, tone = 'info', duration = 4000) => {
      const id = nextId++;
      setToasts((prev) => [...prev.slice(-3), { id, message, tone }]);
      if (duration > 0) {
        timers.current.set(id, setTimeout(() => dismiss(id), duration));
      }
      return id;
    },
    [dismiss],
  );

  const api = useMemo(
    () => ({
      success: (message) => push(message, 'success'),
      info: (message) => push(message, 'info'),
      error: (message) => push(message, 'error', 6000),
      dismiss,
    }),
    [push, dismiss],
  );

  return (
    <ToastContext.Provider value={api}>
      {children}
      <div aria-live="polite" className="pointer-events-none fixed bottom-4 right-4 z-[60] flex w-full max-w-sm flex-col gap-2">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            role="status"
            className="pointer-events-auto flex items-start gap-2.5 rounded-xl border border-line bg-elevated px-4 py-3 text-sm shadow-lg"
          >
            {ICONS[toast.tone] ?? ICONS.info}
            <span className="min-w-0 flex-1">{toast.message}</span>
            <button
              type="button"
              onClick={() => dismiss(toast.id)}
              aria-label="ปิดการแจ้งเตือน"
              className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-ink-muted hover:text-ink"
            >
              <X size={14} aria-hidden="true" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used within ToastProvider');
  return ctx;
}
