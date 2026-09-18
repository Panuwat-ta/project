import { forwardRef } from "react";
import { Search } from "lucide-react";
import { cn } from "@/lib/utils";

export const Input = forwardRef(
  ({ className, containerClassName, type = "text", error, label, helperText, icon: Icon, ...props }, ref) => {
    return (
      <div className={cn("w-full space-y-1.5", containerClassName)}>
        {label && (
          <label className="block text-[13px] font-semibold text-foreground">
            {label}
          </label>
        )}
        <div className="relative">
          {Icon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-muted-foreground">
              <Icon className="size-4" />
            </div>
          )}
          <input
            ref={ref}
            type={type}
            className={cn(
              "w-full h-10 rounded-md border border-input bg-card px-3 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35 disabled:opacity-50 disabled:bg-muted",
              Icon && "pl-9",
              error && "border-danger focus-visible:border-danger focus-visible:ring-danger/35",
              className
            )}
            {...props}
          />
        </div>
        {error && <p className="text-xs text-danger">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-muted-foreground">{helperText}</p>
        )}
      </div>
    );
  }
);
Input.displayName = "Input";

export const SearchInput = forwardRef(
  ({ className, containerClassName, value, onChange, placeholder = "Search...", ...props }, ref) => {
    return (
      <div className={cn("relative w-full", containerClassName)}>
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
        <input
          ref={ref}
          type="search"
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          className={cn(
            "w-full h-9 rounded-md border border-input bg-card pl-9 pr-3 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35",
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
  ({ className, containerClassName, label, error, helperText, children, ...props }, ref) => {
    return (
      <div className={cn("w-full space-y-1.5", containerClassName)}>
        {label && (
          <label className="block text-[13px] font-semibold text-foreground">
            {label}
          </label>
        )}
        <select
          ref={ref}
          className={cn(
            "w-full h-9 rounded-md border border-input bg-card px-3 text-sm text-foreground transition-colors outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35 disabled:opacity-50",
            error && "border-danger focus-visible:border-danger focus-visible:ring-danger/35",
            className
          )}
          {...props}
        >
          {children}
        </select>
        {error && <p className="text-xs text-danger">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-muted-foreground">{helperText}</p>
        )}
      </div>
    );
  }
);
Select.displayName = "Select";

export const Textarea = forwardRef(
  ({ className, containerClassName, label, error, helperText, rows = 3, ...props }, ref) => {
    return (
      <div className={cn("w-full space-y-1.5", containerClassName)}>
        {label && (
          <label className="block text-[13px] font-semibold text-foreground">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          rows={rows}
          className={cn(
            "w-full rounded-md border border-input bg-card px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/35 disabled:opacity-50",
            error && "border-danger focus-visible:border-danger focus-visible:ring-danger/35",
            className
          )}
          {...props}
        />
        {error && <p className="text-xs text-danger">{error}</p>}
        {helperText && !error && (
          <p className="text-xs text-muted-foreground">{helperText}</p>
        )}
      </div>
    );
  }
);
Textarea.displayName = "Textarea";
