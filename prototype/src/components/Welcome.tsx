import React, { useState } from "react";
import { Shield, Check, ArrowRight } from "lucide-react";

interface WelcomeProps {
  onNext: () => void;
}

export default function Welcome({ onNext }: WelcomeProps) {
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [agreeData, setAgreeData] = useState(false);

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col items-center justify-between py-8 px-5 select-none font-sans">
      {/* Header Logo */}
      <div className="flex flex-col items-center gap-1 mt-2">
        <div className="p-2.5 bg-[#bfe9ff] text-[#006685] rounded-xl shadow-sm">
          <Shield className="w-7 h-7" />
        </div>
        <span className="text-xl font-bold tracking-tight text-[#006685]">
          ScamGuard
        </span>
      </div>

      {/* Device Mockup with Laser scanning animation */}
      <div className="my-6 relative w-72 h-72 bg-[#162230] rounded-[36px] overflow-hidden shadow-2xl border-4 border-[#cbd5e1] flex items-center justify-center p-4">
        {/* Glowing visual scan lines */}
        <div className="absolute top-0 inset-x-0 h-1/2 bg-gradient-to-b from-[#00a6d6]/10 to-[#00a6d6]/40 border-b-2 border-[#00a6d6] animate-[scan_3s_infinite_ease-in-out]" />

        {/* Mock content representing a receipt slip scan */}
        <div className="w-full h-full bg-[#121c26]/80 rounded-[28px] p-4 flex flex-col justify-between border border-white/10 relative overflow-hidden">
          <div className="flex justify-between items-center text-[10px] text-gray-400 font-mono">
            <span>E-SLIP SCANNER</span>
            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
          </div>

          {/* Central receipt shape */}
          <div className="bg-white/5 rounded-xl p-3 border border-white/5 flex flex-col gap-1 text-[9px] text-gray-300 font-sans shadow-lg">
            <div className="border-b border-white/10 pb-1 text-center font-bold text-white tracking-wide">
              สลิปโอนเงิน (SLIP RECORD)
            </div>
            <div className="flex justify-between">
              <span>ผู้รับ:</span>
              <span className="text-white">นาย มิจฉาชีพ</span>
            </div>
            <div className="flex justify-between">
              <span>จำนวนเงิน:</span>
              <span className="text-[#00a6d6] font-bold">50,000 บาท</span>
            </div>
            <div className="flex justify-between text-[7px] text-gray-400">
              <span>REF NO:</span>
              <span>202310241420</span>
            </div>
          </div>

          {/* Security badge overlay */}
          <div className="mx-auto px-3 py-1.5 bg-white text-gray-800 text-[10px] font-bold rounded-full shadow-md flex items-center gap-1.5 border border-gray-100">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
            <Check className="w-3.5 h-3.5 text-emerald-500" strokeWidth={3} />
            <span>ตรวจสอบความปลอดภัย</span>
          </div>
        </div>
      </div>

      {/* Main text message */}
      <div className="w-full max-w-sm text-center px-2">
        <h2 className="text-xl font-extrabold text-[#121c26] mb-2 font-sans tracking-tight">
          ตรวจสอบรูปภาพเพื่อความปลอดภัย
        </h2>
        <p className="text-xs text-[#5e6b78] leading-relaxed">
          แอปพลิเคชันนี้ถูกออกแบบมาเพื่อช่วยประเมินความเสี่ยงเบื้องต้นของรูปภาพ
          ผลลัพธ์ที่ได้เป็นการวิเคราะห์ทางเทคนิคเท่านั้น
          ไม่ใช่คำตัดสินทางกฎหมาย โปรดใช้วิจารณญาณในการใช้งาน
        </p>
      </div>

      {/* Consent form and checkboxes */}
      <div className="w-full max-w-sm flex flex-col gap-3 mt-4">
        {/* Checkbox 1 */}
        <label
          onClick={() => setAgreeTerms(!agreeTerms)}
          className={`flex items-start gap-3 p-3.5 rounded-2xl border transition-all cursor-pointer select-none ${
            agreeTerms
              ? "bg-[#edf4ff] border-[#00a6d6] shadow-sm"
              : "bg-white border-[#d8e0ea] hover:bg-gray-50"
          }`}
        >
          <div
            className={`w-5 h-5 rounded-md border flex items-center justify-center transition-colors ${
              agreeTerms ? "bg-[#00a6d6] border-[#00a6d6] text-white" : "border-[#cbd5e1] bg-white"
            }`}
          >
            {agreeTerms && <Check className="w-3.5 h-3.5" strokeWidth={3} />}
          </div>
          <div className="flex-1 -mt-0.5">
            <span className="text-sm font-bold text-[#121c26] block">
              ยอมรับเงื่อนไขการใช้งาน
            </span>
            <span className="text-[11px] text-[#5e6b78] block mt-0.5">
              อ่านข้อกำหนดและนโยบายความเป็นส่วนตัว
            </span>
          </div>
        </label>

        {/* Checkbox 2 */}
        <label
          onClick={() => setAgreeData(!agreeData)}
          className={`flex items-start gap-3 p-3.5 rounded-2xl border transition-all cursor-pointer select-none ${
            agreeData
              ? "bg-[#edf4ff] border-[#00a6d6] shadow-sm"
              : "bg-white border-[#d8e0ea] hover:bg-gray-50"
          }`}
        >
          <div
            className={`w-5 h-5 rounded-md border flex items-center justify-center transition-colors ${
              agreeData ? "bg-[#00a6d6] border-[#00a6d6] text-white" : "border-[#cbd5e1] bg-white"
            }`}
          >
            {agreeData && <Check className="w-3.5 h-3.5" strokeWidth={3} />}
          </div>
          <div className="flex-1 -mt-0.5">
            <span className="text-sm font-bold text-[#121c26] block">
              ยินยอมให้นำข้อมูลไปปรับปรุงระบบ
            </span>
            <span className="text-[11px] text-[#5e6b78] block mt-0.5">
              ข้อมูลของคุณจะถูกเก็บเป็นความลับเพื่อใช้พัฒนาความแม่นยำของ AI
            </span>
          </div>
        </label>

        {/* Start button */}
        <button
          disabled={!agreeTerms}
          onClick={onNext}
          className={`w-full py-3.5 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all shadow-md text-base mt-2 ${
            agreeTerms
              ? "bg-[#006685] text-white hover:bg-[#004d65] cursor-pointer"
              : "bg-gray-300 text-gray-500 cursor-not-allowed shadow-none"
          }`}
        >
          <span>เริ่มใช้งาน</span>
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>

      {/* Footer copyright */}
      <span className="text-[11px] text-[#5e6b78]/70 mt-4 text-center">
        เวอร์ชัน 1.0.0 • ความปลอดภัยของคุณคือสิ่งสำคัญ
      </span>
    </div>
  );
}
