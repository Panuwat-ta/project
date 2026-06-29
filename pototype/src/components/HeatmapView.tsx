import React, { useState } from "react";
import { ArrowLeft, ZoomIn, ZoomOut, RotateCcw, Sliders, ShieldAlert, Eye, EyeOff } from "lucide-react";
import { ScanResult } from "../types";

interface HeatmapViewProps {
  scan: ScanResult;
  onBack: () => void;
}

export default function HeatmapView({ scan, onBack }: HeatmapViewProps) {
  const [showHeatmap, setShowHeatmap] = useState(true);
  const [intensity, setIntensity] = useState(0.85); // transparency slider (0.00 to 1.00)
  const [scale, setScale] = useState(1); // zoom tracker

  const handleZoomIn = () => {
    setScale((prev) => Math.min(prev + 0.2, 2.5));
  };

  const handleZoomOut = () => {
    setScale((prev) => Math.max(prev - 0.2, 0.6));
  };

  const handleReset = () => {
    setScale(1);
    setIntensity(0.85);
  };

  return (
    <div className="min-h-screen bg-[#0f1720] text-white flex flex-col justify-between font-sans select-none">
      {/* Top Header Bar */}
      <div className="bg-[#162230] border-b border-white/10 px-5 py-4 flex items-center justify-between shadow-lg sticky top-0 z-20">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 hover:bg-white/10 rounded-full text-white transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-sm font-extrabold text-white tracking-tight">Visual Heatmap</h1>
            <span className="text-[10px] text-gray-400 font-medium font-mono">{scan.name}</span>
          </div>
        </div>

        {/* Toggle between Raw image and Heatmap overlay */}
        <button
          onClick={() => setShowHeatmap(!showHeatmap)}
          className={`px-3.5 py-1.5 rounded-full text-[10px] font-black tracking-wide flex items-center gap-1.5 transition-all cursor-pointer ${
            showHeatmap ? "bg-[#00a6d6] text-white" : "bg-white/10 text-gray-300"
          }`}
        >
          {showHeatmap ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
          <span>{showHeatmap ? "ซ่อนพิกเซลเสี่ยง" : "ภาพต้นฉบับ"}</span>
        </button>
      </div>

      {/* Warning instruction box */}
      <div className="bg-red-500/10 border-b border-red-500/20 px-4 py-2 text-[10px] font-bold text-red-400 flex items-center justify-center gap-2 text-center">
        <ShieldAlert className="w-4 h-4 text-red-400 shrink-0" />
        <span>พื้นที่สีแดงสว่าง บ่งบอกถึงการแก้ไขพิกเซลหรือค่าตัวอักษรที่ไม่สมมาตร</span>
      </div>

      {/* Interactive Dark Canvas Studio Block */}
      <div className="flex-1 flex items-center justify-center p-6 relative overflow-hidden bg-black/90">
        
        {/* Background Grid scanner matrix lines */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#1e293b_1px,transparent_1px),linear-gradient(to_bottom,#1e293b_1px,transparent_1px)] bg-[size:30px_30px] opacity-20 pointer-events-none" />

        {/* Image holder frame supporting transforms */}
        <div
          className="relative max-w-full max-h-[420px] bg-[#1e2d3b] border border-white/10 rounded-3xl overflow-hidden shadow-2xl transition-transform duration-300 select-none"
          style={{
            transform: `scale(${scale})`,
          }}
        >
          {scan.imageUrl ? (
            <img
              referrerPolicy="no-referrer"
              src={scan.imageUrl}
              alt="Heatmap source scan"
              className="max-w-full max-h-[420px] object-contain block"
            />
          ) : (
            <div className="w-80 h-96 bg-[#162230] flex items-center justify-center text-gray-400">
              ไม่มีรูปภาพต้นฉบับ
            </div>
          )}

          {/* Absolute Heatmap Overlay points mapping coordinates dynamic */}
          {showHeatmap &&
            scan.visualCheck.heatmapBoxes.map((box, index) => (
              <div
                key={index}
                className="absolute bg-red-500/40 rounded-full blur-md border-2 border-red-400 mix-blend-screen shadow-lg shadow-red-500/50 animate-pulse pointer-events-none"
                style={{
                  left: `${box.x}%`,
                  top: `${box.y}%`,
                  width: `${box.w}%`,
                  height: `${box.h}%`,
                  opacity: (box.intensity / 100) * intensity,
                }}
              />
            ))}
        </div>
      </div>

      {/* Controls panel dashboard */}
      <div className="bg-[#162230] border-t border-white/10 p-5 rounded-t-[32px] flex flex-col gap-4 shadow-2xl sticky bottom-0 z-20">
        
        {/* Heatmap intensity slider */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between text-[11px] font-bold text-gray-300">
            <span className="flex items-center gap-1.5">
              <Sliders className="w-4 h-4 text-[#00a6d6]" />
              <span>ความเข้มของ Heatmap</span>
            </span>
            <span className="font-mono text-[#00a6d6]">{Math.round(intensity * 100)}%</span>
          </div>
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            value={intensity}
            onChange={(e) => setIntensity(parseFloat(e.target.value))}
            className="w-full h-1.5 bg-white/10 rounded-lg appearance-none cursor-pointer accent-[#00a6d6]"
          />
        </div>

        {/* Action Button cluster */}
        <div className="flex items-center justify-between mt-1">
          {/* Zoom controls block */}
          <div className="flex items-center gap-1.5 bg-white/5 rounded-2xl p-1 border border-white/10 shadow-inner">
            <button
              onClick={handleZoomOut}
              className="p-2.5 hover:bg-white/10 rounded-xl text-gray-300 cursor-pointer"
            >
              <ZoomOut className="w-4.5 h-4.5" />
            </button>
            <span className="text-xs font-mono font-bold px-1.5 min-w-[50px] text-center">
              {Math.round(scale * 100)}%
            </span>
            <button
              onClick={handleZoomIn}
              className="p-2.5 hover:bg-white/10 rounded-xl text-gray-300 cursor-pointer"
            >
              <ZoomIn className="w-4.5 h-4.5" />
            </button>
          </div>

          {/* Reset position trigger */}
          <button
            onClick={handleReset}
            className="px-4 py-2.5 bg-white/5 hover:bg-white/10 border border-white/10 rounded-2xl text-xs font-bold flex items-center gap-2 cursor-pointer transition-all"
          >
            <RotateCcw className="w-4 h-4" />
            <span>รีเซ็ตมุมมอง</span>
          </button>
        </div>

        {/* Informative footnote text */}
        <span className="text-[10px] text-center text-gray-500 font-sans mt-1 block">
          ใช้สองนิ้วย่อขยายเพื่อซูมดูร่องรอยการตัดต่อ (Pinch to zoom supported)
        </span>
      </div>
    </div>
  );
}
