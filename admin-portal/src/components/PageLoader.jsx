import { Loader2 } from "lucide-react";

export function PageLoader({ text = "Loading..." }) {
  return (
    <div className="flex flex-col items-center justify-center w-full min-h-[400px] h-full text-muted-foreground gap-3">
      <Loader2 className="size-8 animate-spin text-primary" />
      <p className="text-sm font-medium animate-pulse">{text}</p>
    </div>
  );
}
