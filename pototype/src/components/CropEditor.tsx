import React, { useState } from "react";
import { ArrowLeft, RotateCw, RotateCcw, Crop, ZoomIn, ShieldCheck, ChevronRight, RefreshCw } from "lucide-react";

interface CropEditorProps {
  imageDataUrl: string;
  fileName: string;
  onBack: () => void;
  onStartScan: (rotation: number, zoom: number) => void;
  onCancel: () => void;
}

export default function CropEditor({
  imageDataUrl,
  fileName,
  onBack,
  onStartScan,
  onCancel
}: CropEditorProps) {
  const [rotation, setRotation] = useState(0); // in degrees (0, 90, 180, 270)
  const [zoom, setZoom] = useState(1);
  const [aspect, setAspect] = useState("free");

  const rotateRight = () => {
    setRotation((prev) => (prev + 90) % 360);
  };

  const rotateLeft = () => {
    setRotation((prev) => (prev + 270) % 360);
  };

  const toggleZoom = () => {
    setZoom((prev) => (prev === 1 ? 1.3 : prev === 1.3 ? 1.6 : 1));
  };

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Top Header */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <span className="text-base font-extrabold text-[#121c26]">
          ตรวจสอบรูปภาพ
        </span>
        <div className="w-10" /> {/* Balance placeholder */}
      </div>

      {/* Editor Main Canvas Content */}
      <div className="flex-1 flex flex-col items-center justify-center p-5 max-w-md mx-auto w-full">
        <div className="w-full text-center mb-4">
          <h2 className="text-lg font-black text-[#121c26]">ตรวจสอบรูปภาพ</h2>
          <p className="text-xs text-[#5e6b78] mt-1">
            ปรับแต่งรูปภาพของคุณให้เห็นส่วนที่ต้องการวิเคราะห์ได้ชัดเจนที่สุด
          </p>
        </div>

        {/* Adjusting View Box */}
        <div className="w-full aspect-square max-w-[340px] bg-[#162230] rounded-3xl relative overflow-hidden border-2 border-slate-300 shadow-xl flex items-center justify-center p-4">
          {/* Simulated Grid overlay lines */}
          <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none z-10">
            <div className="border-r border-b border-white/20" />
            <div className="border-r border-b border-white/20" />
            <div className="border-b border-white/20" />
            <div className="border-r border-b border-white/20" />
            <div className="border-r border-b border-white/20" />
            <div className="border-b border-white/20" />
            <div className="border-r border-white/20" />
            <div className="border-r border-white/20" />
            <div className="pointer-events-none" />
          </div>

          {/* Glowing corners */}
          <div className="absolute top-4 left-4 w-6 h-6 border-t-4 border-l-4 border-[#00a6d6] z-10 rounded-tl-md" />
          <div className="absolute top-4 right-4 w-6 h-6 border-t-4 border-r-4 border-[#00a6d6] z-10 rounded-tr-md" />
          <div className="absolute bottom-4 left-4 w-6 h-6 border-b-4 border-l-4 border-[#00a6d6] z-10 rounded-bl-md" />
          <div className="absolute bottom-4 right-4 w-6 h-6 border-b-4 border-r-4 border-[#00a6d6] z-10 rounded-br-md" />

          {/* Image source scaled and rotated with classes */}
          <div
            className="w-full h-full flex items-center justify-center transition-all duration-300 overflow-hidden"
            style={{
              transform: `rotate(${rotation}deg) scale(${zoom})`,
            }}
          >
            <img
              referrerPolicy="no-referrer"
              src={imageDataUrl}
              alt="Uploaded file to analyze"
              className="max-w-full max-h-full object-contain shadow-2xl rounded-lg"
            />
          </div>
        </div>

        {/* Adjustments Panel Control Bar */}
        <div className="w-full bg-white border border-[#cbd5e1] rounded-2xl p-4 mt-5 flex items-center justify-around shadow-sm max-w-[340px]">
          {/* Left rotate */}
          <button
            onClick={rotateLeft}
            className="flex flex-col items-center gap-1.5 hover:text-[#006685] transition-colors cursor-pointer text-gray-500"
          >
            <RotateCcw className="w-5.5 h-5.5" />
            <span className="text-[10px] font-bold">หมุนซ้าย</span>
          </button>

          {/* Right rotate */}
          <button
            onClick={rotateRight}
            className="flex flex-col items-center gap-1.5 hover:text-[#006685] transition-colors cursor-pointer text-gray-500"
          >
            <RotateCw className="w-5.5 h-5.5" />
            <span className="text-[10px] font-bold">หมุนขวา</span>
          </button>

          {/* Aspect ratios */}
          <button
            onClick={() => setAspect((prev) => (prev === "free" ? "1:1" : "free"))}
            className={`flex flex-col items-center gap-1.5 transition-colors cursor-pointer ${
              aspect === "1:1" ? "text-[#006685]" : "text-gray-500 hover:text-[#006685]"
            }`}
          >
            <Crop className="w-5.5 h-5.5" />
            <span className="text-[10px] font-bold">สัดส่วน {aspect === "1:1" ? "(1:1)" : ""}</span>
          </button>

          {/* Zoom toggle */}
          <button
            onClick={toggleZoom}
            className={`flex flex-col items-center gap-1.5 transition-colors cursor-pointer ${
              zoom > 1 ? "text-[#006685]" : "text-gray-500 hover:text-[#006685]"
            }`}
          >
            <ZoomIn className="w-5.5 h-5.5" />
            <span className="text-[10px] font-bold">ขยาย {zoom > 1 ? `(${zoom}x)` : ""}</span>
          </button>
        </div>

        {/* Security disclosure note card */}
        <div className="w-full bg-[#edf4ff] border border-[#bfe9ff] rounded-2xl p-4 mt-4 flex gap-3 text-[#006685] text-xs font-semibold leading-relaxed max-w-[340px] shadow-sm">
          <ShieldCheck className="w-6 h-6 shrink-0 text-[#006685]" />
          <p className="text-[10.5px]">
            รูปภาพจะถูกส่งไปวิเคราะห์บนระบบคลาวด์อย่างปลอดภัย ข้อมูลของคุณจะได้รับการเข้ารหัสและไม่มีการเปิดเผยต่อสาธารณะ
          </p>
        </div>
      </div>

      {/* Buttons at bottom */}
      <div className="p-5 border-t border-[#cbd5e1] bg-white sticky bottom-0 z-10">
        <div className="max-w-xs mx-auto flex flex-col gap-3">
          <button
            onClick={() => onStartScan(rotation, zoom)}
            className="w-full py-4 bg-[#006685] hover:bg-[#004d65] text-white font-extrabold rounded-2xl shadow-md flex items-center justify-center gap-2 cursor-pointer transition-colors text-sm"
          >
            <ShieldCheck className="w-5 h-5" />
            <span>เริ่มวิเคราะห์</span>
          </button>

          <button
            onClick={onCancel}
            className="w-full py-3.5 bg-white hover:bg-gray-50 border border-[#cbd5e1] text-gray-600 font-extrabold rounded-2xl flex items-center justify-center gap-2 cursor-pointer transition-colors text-xs"
          >
            <RefreshCw className="w-4 h-4" />
            <span>เปลี่ยนรูป</span>
          </button>
        </div>
      </div>
    </div>
  );
}
