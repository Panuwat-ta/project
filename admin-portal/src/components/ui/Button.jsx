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
        "bg-primary hover:bg-primary/90 text-primary-foreground font-semibold shadow-sm focus-visible:ring-ring active:scale-[0.98]",
      secondary:
        "bg-secondary text-secondary-foreground hover:bg-secondary/80 focus-visible:ring-ring active:scale-[0.98]",
      outline:
        "border border-border bg-transparent text-foreground hover:bg-muted focus-visible:ring-ring",
      ghost:
        "bg-transparent text-muted-foreground hover:text-foreground hover:bg-muted focus-visible:ring-ring",
      danger:
        "bg-danger hover:bg-danger/90 text-danger-foreground font-medium shadow-sm focus-visible:ring-danger active:scale-[0.98]",
      dangerOutline:
        "border border-danger-border text-danger hover:bg-danger-subtle focus-visible:ring-danger",
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
