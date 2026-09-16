import { useState } from 'react';
import { ImageOff, SplitSquareHorizontal } from 'lucide-react';

/**
 * Before/after evidence comparator: original scan vs model heatmap.
 * Pointer + keyboard operable; slider carries an accessible name and value text.
 */
export default function HeatmapComparator({ originalUrl, heatmapUrl, reportId }) {
  const [position, setPosition] = useState(50);
  const [originalFailed, setOriginalFailed] = useState(false);
  const [heatmapFailed, setHeatmapFailed] = useState(false);

  if (!originalUrl || originalFailed) {
    return (
      <div className="flex aspect-video flex-col items-center justify-center gap-2 rounded-lg border border-line bg-surface-2 text-ink-muted" role="img" aria-label="ไม่มีภาพหลักฐาน">
        <ImageOff size={28} aria-hidden="true" />
        <p className="text-[13px]">ไม่มีภาพหลักฐาน</p>
      </div>
    );
  }

  const showHeatmap = heatmapUrl && !heatmapFailed;

  return (
    <div>
      <div className="relative aspect-video select-none overflow-hidden rounded-lg border border-line bg-surface-2">
        <img
          src={originalUrl}
          alt={`ภาพต้นฉบับของรายงาน #R-${reportId}`}
          loading="lazy"
          draggable={false}
          onError={() => setOriginalFailed(true)}
          className="absolute inset-0 h-full w-full object-contain"
        />
        {showHeatmap && (
          <img
            src={heatmapUrl}
            alt={`ภาพ heatmap ของรายงาน #R-${reportId}`}
            loading="lazy"
            draggable={false}
            onError={() => setHeatmapFailed(true)}
            aria-hidden="true"
            className="absolute inset-0 h-full w-full object-contain"
            style={{ clipPath: `inset(0 calc(100% - ${position}%) 0 0)` }}
          />
        )}
        {showHeatmap && (
          <div className="absolute inset-y-0 w-0.5 bg-focus" style={{ left: `${position}%` }} aria-hidden="true" />
        )}
      </div>
      {showHeatmap ? (
        <div className="mt-2.5 flex items-center gap-2.5">
          <SplitSquareHorizontal size={16} aria-hidden="true" className="shrink-0 text-ink-muted" />
          <label htmlFor="heatmap-compare" className="shrink-0 text-[13px] font-medium">
            เปรียบเทียบ heatmap
          </label>
          <input
            id="heatmap-compare"
            type="range"
            min={0}
            max={100}
            value={position}
            onChange={(e) => setPosition(Number(e.target.value))}
            aria-valuetext={`แสดง heatmap ${position}%`}
            className="h-10 flex-1 accent-[#0E7490]"
          />
          <span className="tnum w-11 shrink-0 text-right text-[13px]" aria-hidden="true">{position}%</span>
        </div>
      ) : (
        <p className="mt-2 text-xs text-ink-muted">ไม่มีภาพ heatmap — แสดงภาพต้นฉบับอย่างเดียว</p>
      )}
    </div>
  );
}
