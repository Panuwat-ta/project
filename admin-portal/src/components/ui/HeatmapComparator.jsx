import { useState } from "react";
import { Sliders, Columns, Layers, ZoomIn, ZoomOut, RotateCcw } from "lucide-react";
import { cn } from "@/lib/utils";
import {
  pointerToPct,
  sliderClipStyle,
  dividerStyle,
  opacityFraction,
  zoomIn,
  zoomOut,
} from "@/lib/heatmap-math";

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
  const [isDragging, setIsDragging] = useState(false);

  const handleZoomIn = () => setZoom((prev) => zoomIn(prev));
  const handleZoomOut = () => setZoom((prev) => zoomOut(prev));
  const handleZoomReset = () => setZoom(1);

  const updateSliderFromPointer = (event) => {
    const rect = event.currentTarget.getBoundingClientRect();
    setSliderPosition(pointerToPct(event.clientX, rect.left, rect.width));
  };

  const handleSliderKeyDown = (event) => {
    let next = sliderPosition;
    if (event.key === "ArrowLeft" || event.key === "ArrowDown") next -= 1;
    else if (event.key === "ArrowRight" || event.key === "ArrowUp") next += 1;
    else if (event.key === "PageDown") next -= 10;
    else if (event.key === "PageUp") next += 10;
    else if (event.key === "Home") next = 0;
    else if (event.key === "End") next = 100;
    else return;
    event.preventDefault();
    setSliderPosition(Math.max(0, Math.min(100, next)));
  };

  if (!heatmapUrl) {
    return (
      <div className={cn("flex flex-col rounded-xl border border-border bg-card text-card-foreground overflow-hidden shadow-sm", className)}>
        <div className="p-3.5 border-b border-border bg-muted/50">
          <span className="text-sm font-semibold text-foreground">{title}</span>
        </div>
        <div className="min-h-[300px] bg-black/90 p-4 flex flex-col items-center justify-center gap-4">
          {originalUrl && (
            <img
              src={originalUrl}
              alt="ภาพต้นฉบับ"
              className="max-h-[360px] max-w-full object-contain rounded-lg border border-border"
            />
          )}
          <div className="max-w-lg rounded-lg border border-border bg-card px-4 py-3 text-center">
            <p className="text-sm font-semibold text-foreground">ไม่มี Heatmap จากระบบ</p>
            <p className="mt-1 text-xs text-muted-foreground">
              ยังไม่สามารถเปรียบเทียบหรือซ้อนผลโมเดลได้ ภาพที่แสดงด้านบนเป็นภาพต้นฉบับเท่านั้น
            </p>
          </div>
        </div>
      </div>
    );
  }

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
              aria-pressed={mode === "slider"}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5",
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
              aria-pressed={mode === "side-by-side"}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5",
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
              aria-pressed={mode === "overlay"}
              className={cn(
                "h-8 px-2.5 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5",
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
              className="size-8 inline-flex items-center justify-center rounded text-muted-foreground hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              title="ย่อภาพ"
              aria-label="ย่อภาพ"
            >
              <ZoomOut className="size-3.5" />
            </button>
            <span className="text-[11px] font-mono text-muted-foreground min-w-10 text-center">
              {Math.round(zoom * 100)}%
            </span>
            <button
              type="button"
              onClick={handleZoomIn}
              className="size-8 inline-flex items-center justify-center rounded text-muted-foreground hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              title="ขยายภาพ"
              aria-label="ขยายภาพ"
            >
              <ZoomIn className="size-3.5" />
            </button>
            {zoom !== 1 && (
              <button
                type="button"
                onClick={handleZoomReset}
                className="size-8 inline-flex items-center justify-center rounded text-muted-foreground hover:bg-muted transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                title="คืนขนาดเดิม"
                aria-label="คืนขนาดภาพเดิม"
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
            className="relative overflow-hidden rounded-lg border border-border max-h-[500px] flex items-center justify-center cursor-ew-resize focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            style={{ transform: `scale(${zoom})`, transformOrigin: "center center", transition: "transform 0.15s ease", touchAction: "none" }}
            role="slider"
            tabIndex={0}
            aria-label="ตำแหน่งเปรียบเทียบภาพต้นฉบับกับ Heatmap"
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={Math.round(sliderPosition)}
            aria-valuetext={`${Math.round(sliderPosition)} เปอร์เซ็นต์`}
            onKeyDown={handleSliderKeyDown}
            onPointerDown={(event) => {
              setIsDragging(true);
              event.currentTarget.setPointerCapture?.(event.pointerId);
              updateSliderFromPointer(event);
            }}
            onPointerMove={(event) => {
              if (isDragging) updateSliderFromPointer(event);
            }}
            onPointerUp={(event) => {
              setIsDragging(false);
              event.currentTarget.releasePointerCapture?.(event.pointerId);
            }}
            onPointerCancel={() => setIsDragging(false)}
          >
            {/* Heatmap Base (Right/Background) */}
            <img
              src={heatmapUrl}
              alt="ผลการวิเคราะห์ฮีตแมป"
              className="max-h-[480px] w-auto object-contain block pointer-events-none"
            />

            {/* Original Overlay (Left/Foreground clipped) */}
            <div
              className="absolute inset-0 overflow-hidden pointer-events-none"
              style={sliderClipStyle(sliderPosition)}
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
              style={dividerStyle(sliderPosition)}
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
                  src={heatmapUrl}
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
              src={heatmapUrl}
              alt="ผลตรวจฮีตแมปแบบซ้อนภาพ"
              className="absolute inset-0 max-h-[480px] w-full h-full object-contain transition-opacity duration-150 mix-blend-screen pointer-events-none"
              style={{ opacity: opacityFraction(overlayOpacity) }}
            />
          </div>
        )}
      </div>

      {/* Sub-toolbar: Opacity Slider (if in overlay mode) & Legend */}
      <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-2.5 bg-muted/40 border-t border-border text-xs text-muted-foreground">
        {mode === "overlay" ? (
          <div className="flex items-center gap-3 w-full sm:w-72">
            <label htmlFor="heatmap-opacity" className="text-xs font-semibold text-foreground">ความโปร่งแสง:</label>
            <input
              id="heatmap-opacity"
              type="range"
              min="0"
              max="100"
              value={overlayOpacity}
              onChange={(e) => setOverlayOpacity(Number(e.target.value))}
              aria-valuetext={`${overlayOpacity} เปอร์เซ็นต์`}
              className="w-full accent-primary cursor-pointer"
            />
            <span className="font-mono text-xs w-9 text-right font-bold text-foreground">{overlayOpacity}%</span>
          </div>
        ) : (
          <div className="text-xs text-muted-foreground font-medium">
            ลากตัวแบ่งหรือใช้ปุ่มลูกศรบนคีย์บอร์ดเพื่อเปรียบเทียบผล
          </div>
        )}

        {/* Heatmap probability legend mirrors the backend Green → Blue → Yellow → Red colormap. */}
        <div className="min-w-64 flex-1 sm:max-w-md" aria-label="สเกลความน่าจะเป็นของความผิดปกติ 0 ถึง 100 เปอร์เซ็นต์">
          <div className="flex items-center justify-between gap-3 text-xs">
            <span className="font-semibold text-muted-foreground">ความน่าจะเป็นของความผิดปกติ</span>
            <span className="font-mono text-foreground">0–100%</span>
          </div>
          <div
            className="mt-1.5 h-2 w-full rounded-full border border-border"
            style={{ backgroundImage: "linear-gradient(90deg, rgb(0 255 0) 0%, rgb(0 0 255) 33.3%, rgb(255 255 0) 66.7%, rgb(255 0 0) 100%)" }}
          />
          <div className="mt-1 flex justify-between text-[11px] text-muted-foreground font-mono">
            <span>0%</span><span>33%</span><span>67%</span><span>100%</span>
          </div>
        </div>
      </div>
    </div>
  );
}
