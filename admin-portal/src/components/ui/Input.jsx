import { forwardRef } from "react";
import { Search } from "lucide-react";
import { cn } from "@/lib/utils";

export const Input = forwardRef(
  ({ className, type = "text", error, label, helperText, icon: Icon, ...props }, ref) => {
    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label className="block text-xs font-semibold text-foreground">
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
              "w-full rounded-md border border-input bg-card px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus:border-ring focus:ring-1 focus:ring-ring disabled:opacity-50 disabled:bg-muted",
              Icon && "pl-9",
              error && "border-danger focus:border-danger focus:ring-danger",
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
  ({ className, value, onChange, placeholder = "Search...", ...props }, ref) => {
    return (
      <div className="relative w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
        <input
          ref={ref}
          type="search"
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          className={cn(
            "w-full rounded-md border border-input bg-card pl-9 pr-3 py-1.5 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus:border-ring focus:ring-1 focus:ring-ring",
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
          <label className="block text-xs font-semibold text-foreground">
            {label}
          </label>
        )}
        <select
          ref={ref}
          className={cn(
            "w-full rounded-md border border-input bg-card px-3 py-2 text-sm text-foreground transition-colors outline-none focus:border-ring focus:ring-1 focus:ring-ring disabled:opacity-50",
            error && "border-danger focus:border-danger focus:ring-danger",
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
  ({ className, label, error, helperText, rows = 3, ...props }, ref) => {
    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label className="block text-xs font-semibold text-foreground">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          rows={rows}
          className={cn(
            "w-full rounded-md border border-input bg-card px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground transition-colors outline-none focus:border-ring focus:ring-1 focus:ring-ring disabled:opacity-50",
            error && "border-danger focus:border-danger focus:ring-danger",
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
