import { forwardRef } from "react";
import { Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";

export const Button = forwardRef(
  (
    {
      className,
      variant = "primary",
      size = "md",
      isLoading = false,
      disabled = false,
      icon: Icon,
      children,
      type = "button",
      ...props
    },
    ref
  ) => {
    const baseStyles =
      "inline-flex items-center justify-center font-medium rounded-md transition-all duration-150 outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed select-none";

    const variants = {
      primary:
        "bg-cyan-500 hover:bg-cyan-400 text-cyan-950 font-semibold shadow-sm focus-visible:ring-cyan-400 dark:focus-visible:ring-offset-slate-950 active:scale-[0.98]",
      secondary:
        "bg-slate-200 dark:bg-slate-800 text-slate-900 dark:text-slate-100 hover:bg-slate-300 dark:hover:bg-slate-700 focus-visible:ring-slate-400 active:scale-[0.98]",
      outline:
        "border border-slate-300 dark:border-slate-700 bg-transparent text-slate-800 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 focus-visible:ring-cyan-500",
      ghost:
        "bg-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 focus-visible:ring-slate-400",
      danger:
        "bg-rose-600 hover:bg-rose-500 text-white font-medium shadow-sm focus-visible:ring-rose-500 active:scale-[0.98]",
      dangerOutline:
        "border border-rose-500/30 text-rose-500 hover:bg-rose-500/10 focus-visible:ring-rose-500",
    };

    const sizes = {
      xs: "text-xs px-2.5 py-1 gap-1.5",
      sm: "text-xs px-3 py-1.5 gap-1.5",
      md: "text-sm px-4 py-2 gap-2",
      lg: "text-base px-5 py-2.5 gap-2.5",
    };

    return (
      <button
        ref={ref}
        type={type}
        disabled={disabled || isLoading}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        {...props}
      >
        {isLoading ? (
          <Loader2 className="size-4 animate-spin shrink-0" />
        ) : Icon ? (
          <Icon className="size-4 shrink-0" />
        ) : null}
        {children}
      </button>
    );
  }
);

Button.displayName = "Button";
