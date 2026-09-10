/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useCallback } from "react";
import { CheckCircle2, AlertTriangle, AlertCircle, Info, X } from "lucide-react";
import { cn } from "@/lib/utils";

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback((type, message, title = null, duration = 4000) => {
    const id = Date.now().toString() + Math.random().toString(36).substring(2, 6);
    const toast = { id, type, message, title, duration };
    setToasts((prev) => [...prev, toast]);

    if (duration > 0) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }
    return id;
  }, [removeToast]);

  const toast = {
    success: (msg, title) => addToast("success", msg, title),
    error: (msg, title) => addToast("error", msg, title, 5000),
    warning: (msg, title) => addToast("warning", msg, title),
    info: (msg, title) => addToast("info", msg, title),
    dismiss: removeToast,
  };

  return (
    <ToastContext.Provider value={toast}>
      {children}
      <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none p-2">
        {toasts.map((t) => {
          const icons = {
            success: <CheckCircle2 className="size-4 text-success shrink-0 mt-0.5" />,
            error: <AlertCircle className="size-4 text-danger shrink-0 mt-0.5" />,
            warning: <AlertTriangle className="size-4 text-warning shrink-0 mt-0.5" />,
            info: <Info className="size-4 text-info shrink-0 mt-0.5" />,
          };

          const borders = {
            success: "border-success-border/50 bg-card text-foreground",
            error: "border-danger-border/50 bg-card text-foreground",
            warning: "border-warning-border/50 bg-card text-foreground",
            info: "border-info-border/50 bg-card text-foreground",
          };

          return (
            <div
              key={t.id}
              className={cn(
                "pointer-events-auto flex items-start gap-3 p-3.5 rounded-lg border shadow-xl backdrop-blur-md transition-all animate-in slide-in-from-bottom-3 duration-200",
                borders[t.type] || "border-border bg-card text-foreground"
              )}
            >
              {icons[t.type]}
              <div className="flex-1 min-w-0">
                {t.title && <div className="text-xs font-semibold tracking-wide uppercase">{t.title}</div>}
                <div className="text-sm leading-snug">{t.message}</div>
              </div>
              <button
                onClick={() => removeToast(t.id)}
                className="opacity-70 hover:opacity-100 transition-opacity p-0.5"
                aria-label="Close notification"
              >
                <X className="size-3.5" />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error("useToast must be used within ToastProvider");
  }
  return ctx;
}
