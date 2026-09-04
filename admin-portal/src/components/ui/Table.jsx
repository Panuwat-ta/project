import { ChevronLeft, ChevronRight, Inbox } from "lucide-react";
import { cn } from "@/lib/utils";

export function Table({ className, children, ...props }) {
  return (
    <div className="w-full overflow-x-auto">
      <table
        className={cn(
          "w-full caption-bottom text-sm text-left text-foreground",
          className
        )}
        {...props}
      >
        {children}
      </table>
    </div>
  );
}

export function TableHeader({ className, children, ...props }) {
  return (
    <thead
      className={cn(
        "bg-muted/60 border-b border-border text-xs font-semibold uppercase tracking-wider text-muted-foreground",
        className
      )}
      {...props}
    >
      {children}
    </thead>
  );
}

export function TableBody({ className, children, ...props }) {
  return (
    <tbody
      className={cn("divide-y divide-border-subtle", className)}
      {...props}
    >
      {children}
    </tbody>
  );
}

export function TableRow({ className, children, isHoverable = true, ...props }) {
  return (
    <tr
      className={cn(
        "transition-colors",
        isHoverable && "hover:bg-muted/40",
        className
      )}
      {...props}
    >
      {children}
    </tr>
  );
}

export function TableHead({ className, children, ...props }) {
  return (
    <th className={cn("px-4 py-3 align-middle font-medium", className)} {...props}>
      {children}
    </th>
  );
}

export function TableCell({ className, children, ...props }) {
  return (
    <td className={cn("px-4 py-3 align-middle tabular-nums", className)} {...props}>
      {children}
    </td>
  );
}

export function TableEmpty({ message = "ไม่พบรายการข้อมูล", colSpan = 6, children }) {
  return (
    <TableRow isHoverable={false}>
      <TableCell colSpan={colSpan} className="py-12 text-center">
        <div className="flex flex-col items-center justify-center gap-2">
          <div className="size-10 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
            <Inbox className="size-5" />
          </div>
          <p className="text-sm font-medium text-foreground">{message}</p>
          {children}
        </div>
      </TableCell>
    </TableRow>
  );
}

export function Pagination({ page, totalPages, totalItems, onPageChange, limit = 10 }) {
  if (totalPages <= 1 && (!totalItems || totalItems <= limit)) return null;

  const startItem = totalItems === 0 ? 0 : (page - 1) * limit + 1;
  const endItem = Math.min(page * limit, totalItems);

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-3 px-4 py-3 border-t border-border bg-muted/30 text-xs text-muted-foreground">
      <div>
        แสดง <span className="font-bold text-foreground">{startItem}</span> -{" "}
        <span className="font-bold text-foreground">{endItem}</span> จากทั้งหมด{" "}
        <span className="font-bold text-foreground">{totalItems?.toLocaleString() || 0}</span> รายการ
      </div>

      <div className="flex items-center gap-1.5">
        <button
          type="button"
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
          className="p-1.5 rounded-md border border-border text-foreground hover:bg-card disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          aria-label="Previous page"
        >
          <ChevronLeft className="size-4" />
        </button>

        <span className="px-3 py-1 font-mono text-xs font-semibold text-foreground">
          หน้า {page} / {totalPages || 1}
        </span>

        <button
          type="button"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages}
          className="p-1.5 rounded-md border border-border text-foreground hover:bg-card disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          aria-label="Next page"
        >
          <ChevronRight className="size-4" />
        </button>
      </div>
    </div>
  );
}
