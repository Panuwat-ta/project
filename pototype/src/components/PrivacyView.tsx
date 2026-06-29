import React, { useState } from "react";
import { ArrowLeft, Shield, ShieldCheck, Lock, ChevronRight, Check } from "lucide-react";

interface PrivacyViewProps {
  onBack: () => void;
}

export default function PrivacyView({ onBack }: PrivacyViewProps) {
  const [saveToCloud, setSaveToCloud] = useState(true);
  const [dataDonation, setDataDonation] = useState(false);
  const [tempCache, setTempCache] = useState(true);

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Header */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors cursor-pointer"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <span className="text-base font-extrabold text-[#121c26]">
          การจัดการความเป็นส่วนตัว
        </span>
        <div className="w-10" />
      </div>

      {/* PDPA Core Statements */}
      <div className="flex-1 max-w-md mx-auto w-full p-5 flex flex-col gap-5">
        
        {/* Shield graphic illustration card */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-6 text-center shadow-sm flex flex-col items-center gap-3">
          <div className="p-4 bg-[#edf4ff] text-[#006685] rounded-full shadow-inner animate-pulse">
            <ShieldCheck className="w-10 h-10" />
          </div>
          <h2 className="text-base font-black text-[#121c26]">การคุ้มครองข้อมูลส่วนบุคคล (PDPA)</h2>
          <p className="text-xs text-[#5e6b78] leading-relaxed max-w-[280px] mx-auto">
            ความลับของท่านคือสิ่งสูงสุด ข้อมูลใบหน้า รหัสผ่าน และยอดเงินที่ถูกสแกนจะถูกย่อยสลายทันทีหลังการตรวจสอบความเสี่ยง
          </p>
        </div>

        {/* List of Settings Toggles */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-5">
          <h3 className="text-xs font-black text-gray-400 uppercase tracking-wider">
            สิทธิ์การจัดเก็บข้อมูล
          </h3>

          {/* Toggle Item 1: Save history to Cloud */}
          <div className="flex items-center justify-between">
            <div className="flex-1 pr-4">
              <span className="text-xs font-black text-[#121c26] block">บันทึกประวัติบนคลาวด์</span>
              <span className="text-[10px] text-gray-400 block mt-0.5 leading-relaxed">
                บันทึกภาพและคะแนนบนฐานข้อมูลระบบเพื่อเข้าดูจากอุปกรณ์อื่น
              </span>
            </div>
            <button
              onClick={() => setSaveToCloud(!saveToCloud)}
              className={`w-12 h-6 rounded-full transition-colors relative flex items-center p-1 cursor-pointer ${
                saveToCloud ? "bg-[#006685]" : "bg-gray-200"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow transition-transform ${
                  saveToCloud ? "translate-x-6" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Toggle Item 2: Data donation */}
          <div className="flex items-center justify-between border-t border-gray-100 pt-4">
            <div className="flex-1 pr-4">
              <span className="text-xs font-black text-[#121c26] block">บริจาคข้อมูลเพื่อสอนโมเดล</span>
              <span className="text-[10px] text-gray-400 block mt-0.5 leading-relaxed">
                อนุญาตให้ทีมงานใช้รูปภาพทุจริตของท่านไปพัฒนาความแม่นยำของ AI
              </span>
            </div>
            <button
              onClick={() => setDataDonation(!dataDonation)}
              className={`w-12 h-6 rounded-full transition-colors relative flex items-center p-1 cursor-pointer ${
                dataDonation ? "bg-[#006685]" : "bg-gray-200"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow transition-transform ${
                  dataDonation ? "translate-x-6" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Toggle Item 3: Delete cache on logout */}
          <div className="flex items-center justify-between border-t border-gray-100 pt-4">
            <div className="flex-1 pr-4">
              <span className="text-xs font-black text-[#121c26] block">ล้างไฟล์ประวัติเมื่อปิดแอป</span>
              <span className="text-[10px] text-gray-400 block mt-0.5 leading-relaxed">
                ทำลายประวัติการวิเคราะห์ทั้งหมดบนแคชเครื่องของท่านเพื่อความปลอดภัยสูงสุด
              </span>
            </div>
            <button
              onClick={() => setTempCache(!tempCache)}
              className={`w-12 h-6 rounded-full transition-colors relative flex items-center p-1 cursor-pointer ${
                tempCache ? "bg-[#006685]" : "bg-gray-200"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow transition-transform ${
                  tempCache ? "translate-x-6" : "translate-x-0"
                }`}
              />
            </button>
          </div>
        </div>

        {/* Security guidelines note */}
        <div className="bg-[#edf4ff] border border-[#bfe9ff] rounded-2xl p-4 flex gap-3 text-[#006685] text-xs font-semibold leading-relaxed">
          <Lock className="w-5.5 h-5.5 shrink-0 text-[#006685]" />
          <p className="text-[10.5px]">
            สอดคล้องตามมาตรฐานพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA Compliant) ข้อมูลประวัติการวิเคราะห์ถูกเข้ารหัสด้วย SHA-256
          </p>
        </div>
      </div>

      {/* Return button */}
      <div className="p-5 border-t border-[#cbd5e1] bg-white sticky bottom-0 z-10 shadow-inner">
        <button
          onClick={onBack}
          className="w-full max-w-xs mx-auto py-3.5 bg-[#006685] text-white hover:bg-[#004d65] font-extrabold rounded-2xl shadow-md flex items-center justify-center cursor-pointer transition-colors text-xs"
        >
          <span>บันทึกความต้องการและกลับ</span>
        </button>
      </div>
    </div>
  );
}
