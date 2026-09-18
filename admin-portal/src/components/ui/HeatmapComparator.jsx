import { useState } from "react";
import { Sliders, Columns, Layers, ZoomIn, ZoomOut, RotateCcw } from "lucide-react";
import { cn } from "@/lib/utils";

export function HeatmapComparator({
  originalUrl,
  heatmapUrl,
  title = "เปรียบเทียบผลการตรวจภาพ",
  className,
}) {
  const [mode, setMode] = useState("slider"); // 'slider' | 'side-by-side' | 'overlay'
  const [sliderPosition, setSliderPosition] = useState(50); // percentage
  const [overlayOpacity, setOverlayOpacity] = useState(70); // percentage
  const [zoom, setZoom] = useState(1);

  const handleZoomIn = () => setZoom((prev) => Math.min(prev + 0.25, 2.5));
  const handleZoomOut = () => setZoom((prev) => Math.max(prev - 0.25, 0.75));
  const handleZoomReset = () => setZoom(1);

  return (
    <div className={cn("flex flex-col rounded-xl border border-border bg-card text-card-foreground overflow-hidden shadow-sm", className)}>
      {/* Control Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-3 p-3.5 border-b border-border bg-muted/50">
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold text-foreground">
            {title}
          </span>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {/* Mode Switcher */}
          <div className="flex p-0.5 rounded-lg bg-muted border border-border">
            <button
              type="button"
              onClick={() => setMode("slider")}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-all flex items-center gap-1.5",
                mode === "slider"
                  ? "bg-card text-primary shadow-sm font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
              title="เลื่อนเปรียบเทียบ"
            >
              <Sliders className="size-3.5" />
              <span>เลื่อนเปรียบเทียบ</span>
            </button>

            <button
              type="button"
              onClick={() => setMode("side-by-side")}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-all flex items-center gap-1.5",
                mode === "side-by-side"
                  ? "bg-card text-primary shadow-sm font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
              title="เทียบข้างกัน"
            >
              <Columns className="size-3.5" />
              <span>เทียบข้างกัน</span>
            </button>

            <button
              type="button"
              onClick={() => setMode("overlay")}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-all flex items-center gap-1.5",
                mode === "overlay"
                  ? "bg-card text-primary shadow-sm font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
              title="ซ้อนภาพ"
            >
              <Layers className="size-3.5" />
              <span>ซ้อนภาพ</span>
            </button>
          </div>

          {/* Zoom Controls */}
          <div className="flex items-center gap-1 pl-2 border-l border-border">
            <button
              type="button"
              onClick={handleZoomOut}
              className="p-1 rounded text-muted-foreground hover:bg-muted transition-colors"
              title="ย่อภาพ"
            >
              <ZoomOut className="size-3.5" />
            </button>
            <span className="text-[11px] font-mono text-muted-foreground min-w-10 text-center">
              {Math.round(zoom * 100)}%
            </span>
            <button
              type="button"
              onClick={handleZoomIn}
              className="p-1 rounded text-muted-foreground hover:bg-muted transition-colors"
              title="ขยายภาพ"
            >
              <ZoomIn className="size-3.5" />
            </button>
            {zoom !== 1 && (
              <button
                type="button"
                onClick={handleZoomReset}
                className="p-1 rounded text-muted-foreground hover:bg-muted transition-colors"
                title="คืนขนาดเดิม"
              >
                <RotateCcw className="size-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main View Area */}
      <div className="relative min-h-[380px] bg-black/90 flex items-center justify-center overflow-hidden select-none p-4">
        {mode === "slider" && (
          <div
            className="relative overflow-hidden rounded-lg border border-border max-h-[500px] flex items-center justify-center cursor-ew-resize"
            style={{ transform: `scale(${zoom})`, transformOrigin: "center center", transition: "transform 0.15s ease" }}
            onMouseMove={(e) => {
              const rect = e.currentTarget.getBoundingClientRect();
              const x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
              setSliderPosition((x / rect.width) * 100);
            }}
          >
            {/* Heatmap Base (Right/Background) */}
            <img
              src={heatmapUrl || originalUrl}
              alt="ผลการวิเคราะห์ฮีตแมป"
              className="max-h-[480px] w-auto object-contain block pointer-events-none"
            />

            {/* Original Overlay (Left/Foreground clipped) */}
            <div
              className="absolute inset-0 overflow-hidden pointer-events-none"
              style={{ clipPath: `inset(0 ${100 - sliderPosition}% 0 0)` }}
            >
              <img
                src={originalUrl}
                alt="ภาพต้นฉบับ"
                className="max-h-[480px] w-auto object-contain block"
              />
            </div>

            {/* Divider Line */}
            <div
              className="absolute inset-y-0 w-0.5 bg-primary shadow-[0_0_10px_color-mix(in_srgb,var(--primary)_70%,transparent)] pointer-events-none"
              style={{ left: `${sliderPosition}%` }}
            >
              <div className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 size-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-lg font-bold text-[9px]">
                ↔
              </div>
            </div>

            {/* Labels */}
            <div className="absolute bottom-2 left-2 px-2 py-0.5 rounded bg-black/80 text-xs font-medium text-white pointer-events-none">
              ภาพต้นฉบับ
            </div>
            <div className="absolute bottom-2 right-2 px-2 py-0.5 rounded bg-black/80 text-xs font-medium text-primary pointer-events-none">
              ผลตรวจของโมเดล
            </div>
          </div>
        )}

        {mode === "side-by-side" && (
          <div
            className="grid grid-cols-1 md:grid-cols-2 gap-4 w-full max-w-5xl"
            style={{ transform: `scale(${zoom})`, transformOrigin: "center center", transition: "transform 0.15s ease" }}
          >
            <div className="flex flex-col items-center gap-2">
              <span className="text-xs text-muted-foreground">ภาพต้นฉบับ</span>
              <div className="rounded-lg border border-border overflow-hidden bg-card/50 p-1">
                <img
                  src={originalUrl}
                  alt="ภาพต้นฉบับ"
                  className="max-h-[420px] w-full object-contain rounded"
                />
              </div>
            </div>

            <div className="flex flex-col items-center gap-2">
              <span className="text-xs text-primary">ผลตรวจของโมเดล</span>
              <div className="rounded-lg border border-primary-border overflow-hidden bg-card/50 p-1">
                <img
                  src={heatmapUrl || originalUrl}
                  alt="ผลตรวจฮีตแมป"
                  className="max-h-[420px] w-full object-contain rounded"
                />
              </div>
            </div>
          </div>
        )}

        {mode === "overlay" && (
          <div
            className="relative rounded-lg border border-border overflow-hidden max-h-[500px]"
            style={{ transform: `scale(${zoom})`, transformOrigin: "center center", transition: "transform 0.15s ease" }}
          >
            {/* Base Original Image */}
            <img
              src={originalUrl}
              alt="ภาพต้นฉบับ"
              className="max-h-[480px] w-auto object-contain block"
            />

            {/* Heatmap with Opacity */}
            <img
              src={heatmapUrl || originalUrl}
              alt="ผลตรวจฮีตแมปแบบซ้อนภาพ"
              className="absolute inset-0 max-h-[480px] w-full h-full object-contain transition-opacity duration-150 mix-blend-screen pointer-events-none"
              style={{ opacity: overlayOpacity / 100 }}
            />
          </div>
        )}
      </div>

      {/* Sub-toolbar: Opacity Slider (if in overlay mode) & Legend */}
      <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-2.5 bg-muted/40 border-t border-border text-xs text-muted-foreground">
        {mode === "overlay" ? (
          <div className="flex items-center gap-3 w-full sm:w-72">
            <span className="text-xs font-semibold text-foreground">ความโปร่งแสง:</span>
            <input
              type="range"
              min="0"
              max="100"
              value={overlayOpacity}
              onChange={(e) => setOverlayOpacity(Number(e.target.value))}
              className="w-full accent-primary cursor-pointer"
            />
            <span className="font-mono text-xs w-9 text-right font-bold text-foreground">{overlayOpacity}%</span>
          </div>
        ) : (
          <div className="text-xs text-muted-foreground font-medium">
            เลื่อนเมาส์บนภาพเพื่อเปรียบเทียบผล
          </div>
        )}

        {/* Heatmap Legend */}
        <div className="flex flex-wrap items-center gap-4 text-xs">
          <span className="font-semibold text-muted-foreground">ระดับความเสี่ยง:</span>
          <div className="flex items-center gap-1.5 text-foreground font-medium">
            <span className="size-2 rounded-full bg-risk-low" />
            <span>ต่ำ (0–39)</span>
          </div>
          <div className="flex items-center gap-1.5 text-foreground font-medium">
            <span className="size-2 rounded-full bg-risk-medium" />
            <span>กลาง (40–69)</span>
          </div>
          <div className="flex items-center gap-1.5 text-foreground font-medium">
            <span className="size-2 rounded-full bg-risk-high" />
            <span>สูง (70–100)</span>
          </div>
        </div>
      </div>
    </div>
  );
}
