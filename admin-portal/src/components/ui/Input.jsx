import { forwardRef } from "react";
import { Search } from "lucide-react";
import { cn } from "@/lib/utils";

export const Input = forwardRef(
  ({ className, type = "text", error, label, helperText, icon: Icon, ...props }, ref) => {
    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label className="block text-xs font-semibold text-slate-800 dark:text-slate-300">
            {label}
          </label>
        )}
        <div className="relative">
          {Icon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500 dark:text-slate-400">
              <Icon className="size-4" />
            </div>
          )}
          <input
            ref={ref}
            type={type}
            className={cn(
              "w-full rounded-md border border-slate-300 dark:border-slate-700/80 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 placeholder-slate-500 dark:placeholder-slate-400 transition-colors outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 disabled:opacity-50 disabled:bg-slate-100 dark:disabled:bg-slate-800/50",
              Icon && "pl-9",
              error && "border-rose-500 focus:border-rose-500 focus:ring-rose-500",
              className
            )}
            {...props}
          />
        </div>
        {error && <p className="text-xs text-rose-500">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-slate-600 dark:text-slate-400">{helperText}</p>
        )}
      </div>
    );
  }
);
Input.displayName = "Input";

export const SearchInput = forwardRef(
  ({ className, value, onChange, placeholder = "Search...", ...props }, ref) => {
    return (
      <div className="relative w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-slate-500 dark:text-slate-400 pointer-events-none" />
        <input
          ref={ref}
          type="search"
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          className={cn(
            "w-full rounded-md border border-slate-300 dark:border-slate-700/80 bg-white dark:bg-slate-900/80 pl-9 pr-3 py-1.5 text-sm text-slate-900 dark:text-slate-100 placeholder-slate-500 dark:placeholder-slate-400 transition-colors outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500",
            className
          )}
          {...props}
        />
      </div>
    );
  }
);
SearchInput.displayName = "SearchInput";

export const Select = forwardRef(
  ({ className, label, error, helperText, children, ...props }, ref) => {
    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label className="block text-xs font-semibold text-slate-800 dark:text-slate-300">
            {label}
          </label>
        )}
        <select
          ref={ref}
          className={cn(
            "w-full rounded-md border border-slate-300 dark:border-slate-700/80 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 transition-colors outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 disabled:opacity-50",
            error && "border-rose-500 focus:border-rose-500 focus:ring-rose-500",
            className
          )}
          {...props}
        >
          {children}
        </select>
        {error && <p className="text-xs text-rose-500">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-slate-600 dark:text-slate-400">{helperText}</p>
        )}
      </div>
    );
  }
);
Select.displayName = "Select";

export const Textarea = forwardRef(
  ({ className, label, error, helperText, rows = 3, ...props }, ref) => {
    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label className="block text-xs font-semibold text-slate-800 dark:text-slate-300">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          rows={rows}
          className={cn(
            "w-full rounded-md border border-slate-300 dark:border-slate-700/80 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 placeholder-slate-500 dark:placeholder-slate-400 transition-colors outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 disabled:opacity-50",
            error && "border-rose-500 focus:border-rose-500 focus:ring-rose-500",
            className
          )}
          {...props}
        />
        {error && <p className="text-xs text-rose-500">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-slate-600 dark:text-slate-400">{helperText}</p>
        )}
      </div>
    );
  }
);
Textarea.displayName = "Textarea";
