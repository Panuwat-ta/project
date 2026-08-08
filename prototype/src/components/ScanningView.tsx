import React, { useEffect, useState } from "react";
import { Shield, Check, Search, MessageSquare, AlertTriangle, ShieldAlert } from "lucide-react";

interface ScanningViewProps {
  imageDataUrl: string;
  onFinished: () => void;
}

export default function ScanningView({ imageDataUrl, onFinished }: ScanningViewProps) {
  const [progress, setProgress] = useState(0);
  const [step, setStep] = useState(1); // 1, 2, 3

  useEffect(() => {
    // Progress increment timer
    const progressTimer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(progressTimer);
          return 100;
        }
        return prev + 1;
      });
    }, 40);

    return () => clearInterval(progressTimer);
  }, []);

  useEffect(() => {
    // Sequential step checklist updates
    if (progress >= 35 && progress < 75) {
      setStep(2);
    } else if (progress >= 75 && progress < 100) {
      setStep(3);
    } else if (progress === 100) {
      const finishTimeout = setTimeout(() => {
        onFinished();
      }, 800);
      return () => clearTimeout(finishTimeout);
    }
  }, [progress, onFinished]);

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between p-5 font-sans select-none">
      {/* Top Header bar */}
      <div className="flex items-center justify-between py-4 border-b border-[#cbd5e1] max-w-md mx-auto w-full px-2">
        <div className="flex items-center gap-1.5">
          <Shield className="w-5.5 h-5.5 text-[#006685]" />
          <span className="text-lg font-black text-[#006685]">ScamGuard</span>
        </div>
        <div className="w-5 h-5 rounded-full bg-emerald-500 animate-ping" />
      </div>

      {/* Main progress spinner ring layout */}
      <div className="flex-1 flex flex-col items-center justify-center gap-8 p-4 max-w-md mx-auto w-full">
        {/* Dynamic circular radial indicator */}
        <div className="relative w-56 h-56 flex items-center justify-center">
          {/* Rotating outer track */}
          <svg className="absolute w-full h-full -rotate-90">
            <circle
              cx="112"
              cy="112"
              r="90"
              className="stroke-gray-200 fill-none"
              strokeWidth="8"
            />
            <circle
              cx="112"
              cy="112"
              r="90"
              className="stroke-[#006685] fill-none transition-all duration-100 ease-out"
              strokeWidth="8"
              strokeDasharray={2 * Math.PI * 90}
              strokeDashoffset={2 * Math.PI * 90 * (1 - progress / 100)}
              strokeLinecap="round"
            />
          </svg>

          {/* Central image thumbnail clip */}
          <div className="w-40 h-40 rounded-full overflow-hidden border-4 border-white shadow-xl bg-gray-50 flex items-center justify-center relative">
            {imageDataUrl ? (
              <img
                referrerPolicy="no-referrer"
                src={imageDataUrl}
                alt="Analyzing file preview"
                className="w-full h-full object-cover blur-[1px] opacity-80"
              />
            ) : (
              <Shield className="w-16 h-16 text-gray-300" />
            )}

            {/* Glowing scanner center pulse */}
            <div className="absolute inset-x-0 h-1 bg-gradient-to-r from-transparent via-[#00a6d6] to-transparent shadow-lg shadow-[#00a6d6] animate-[pulse_1.5s_infinite]" />
          </div>

          {/* Core progress badge bubble at the bottom of the circle */}
          <div className="absolute bottom-1 bg-[#006685] text-white font-extrabold text-xs px-3.5 py-1.5 rounded-full shadow-md tracking-wider border border-[#bfe9ff] font-sans">
            {progress}%
          </div>
        </div>

        {/* Informative Scanner Status Title */}
        <div className="text-center px-4">
          <h2 className="text-xl font-black text-[#121c26]">
            กำลังวิเคราะห์ความปลอดภัย
          </h2>
          <p className="text-xs text-[#5e6b78] mt-2 leading-relaxed">
            กรุณารอสักครู่ ระบบกำลังประมวลผลความถูกต้องและแบล็คลิสต์ด้วย AI
          </p>
        </div>

        {/* Live scanning progress checkpoints bento */}
        <div className="w-full bg-white border border-[#cbd5e1] rounded-3xl p-5 flex flex-col gap-4 shadow-sm">
          {/* Step 1: Read image text */}
          <div className="flex items-start gap-3.5">
            <div
              className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 transition-all ${
                step > 1
                  ? "bg-emerald-500 text-white"
                  : "bg-blue-50 text-[#00a6d6] border border-[#00a6d6] animate-pulse"
              }`}
            >
              {step > 1 ? (
                <Check className="w-3.5 h-3.5" strokeWidth={3} />
              ) : (
                <Search className="w-3.5 h-3.5" />
              )}
            </div>
            <div>
              <span className="text-xs font-black text-[#121c26] block">
                กำลังอ่านข้อความในภาพ (OCR Checking)
              </span>
              <span className={`text-[10px] mt-0.5 block ${step > 1 ? "text-emerald-500 font-bold" : "text-gray-400"}`}>
                {step > 1 ? "เสร็จสิ้น" : "กำลังอ่านสัญลักษณ์และข้อมูลตัวอักษร..."}
              </span>
            </div>
          </div>

          {/* Step 2: Source lookup */}
          <div className="flex items-start gap-3.5">
            <div
              className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 transition-all ${
                step > 2
                  ? "bg-emerald-500 text-white"
                  : step === 2
                  ? "bg-blue-50 text-[#00a6d6] border border-[#00a6d6] animate-pulse"
                  : "bg-gray-100 text-gray-400"
              }`}
            >
              {step > 2 ? (
                <Check className="w-3.5 h-3.5" strokeWidth={3} />
              ) : (
                <Shield className="w-3.5 h-3.5" />
              )}
            </div>
            <div>
              <span className={`text-xs font-black block ${step >= 2 ? "text-[#121c26]" : "text-gray-400"}`}>
                กำลังตรวจสอบแหล่งที่มา (Blacklist Checking)
              </span>
              <span className={`text-[10px] mt-0.5 block ${step > 2 ? "text-emerald-500 font-bold" : step === 2 ? "text-[#00a6d6]" : "text-gray-400"}`}>
                {step > 2 ? "เสร็จสิ้น" : step === 2 ? "กำลังตรวจสอบข้อมูลผู้ส่งและบัญชีปลายทาง..." : "รอการประมวลผล"}
              </span>
            </div>
          </div>

          {/* Step 3: Anomaly detection */}
          <div className="flex items-start gap-3.5">
            <div
              className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 transition-all ${
                step === 3 && progress === 100
                  ? "bg-emerald-500 text-white"
                  : step === 3
                  ? "bg-blue-50 text-[#00a6d6] border border-[#00a6d6] animate-pulse"
                  : "bg-gray-100 text-gray-400"
              }`}
            >
              {step === 3 && progress === 100 ? (
                <Check className="w-3.5 h-3.5" strokeWidth={3} />
              ) : (
                <MessageSquare className="w-3.5 h-3.5" />
              )}
            </div>
            <div>
              <span className={`text-xs font-black block ${step >= 3 ? "text-[#121c26]" : "text-gray-400"}`}>
                กำลังวิเคราะห์พิกเซลและการตัดต่อ (Anomaly Detection)
              </span>
              <span className={`text-[10px] mt-0.5 block ${progress === 100 ? "text-emerald-500 font-bold" : step === 3 ? "text-[#00a6d6]" : "text-gray-400"}`}>
                {progress === 100 ? "เสร็จสิ้น" : step === 3 ? "ระบบตรวจจับสิ่งดัดแปลงทางพิกเซล..." : "รอการประมวลผล"}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Security warning footnote */}
      <div className="p-4 flex justify-center mb-2 max-w-md mx-auto w-full">
        <div className="px-4 py-2 bg-[#edf4ff] text-[#006685] border border-[#bfe9ff] rounded-2xl text-[10.5px] font-bold flex items-center gap-2 shadow-sm leading-snug">
          <ShieldAlert className="w-4.5 h-4.5 text-[#00a6d6]" />
          <span>การวิเคราะห์แบบเข้ารหัส ข้อมูลของคุณจะถูกเก็บเป็นความลับสูงสุด</span>
        </div>
      </div>
    </div>
  );
}
