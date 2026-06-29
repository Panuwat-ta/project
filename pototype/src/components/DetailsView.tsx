import React from "react";
import { ArrowLeft, ShieldCheck, AlertTriangle, Cpu, Globe, Key, FileText, ChevronRight, Check } from "lucide-react";
import { ScanResult } from "../types";

interface DetailsViewProps {
  scan: ScanResult;
  onBack: () => void;
  onReportToOfficials: () => void;
  onReset: () => void;
}

export default function DetailsView({
  scan,
  onBack,
  onReportToOfficials,
  onReset
}: DetailsViewProps) {
  const { ocrText, ocrAnalysis, sourceCheck, visualCheck } = scan;

  // Determine severity style helper
  const getStatusBadge = (status: "SAFE" | "WARNING" | "DANGER") => {
    switch (status) {
      case "DANGER":
        return "bg-red-50 text-red-600 border border-red-100";
      case "WARNING":
        return "bg-amber-50 text-amber-600 border border-amber-100";
      default:
        return "bg-emerald-50 text-emerald-600 border border-emerald-100";
    }
  };

  // Helper function to render text with highlighted danger keyword tokens
  const renderHighlightedOcr = (text: string) => {
    if (!text) return "ไม่พบข้อความตัวอักษร";
    const keywords = ["รางวัล", "ด่วน", "คลิก", "โอนเงิน", "มิจฉาชีพ", "เงินกู้", "หลอกลวง", "http", "www", "บัญชีม้า"];
    
    const lines = text.split("\n");
    return lines.map((line, lIdx) => {
      let elements: React.ReactNode[] = [line];
      
      keywords.forEach((keyword) => {
        const temp: React.ReactNode[] = [];
        elements.forEach((elem) => {
          if (typeof elem === "string") {
            const parts = elem.split(keyword);
            if (parts.length > 1) {
              parts.forEach((part, pIdx) => {
                temp.push(part);
                if (pIdx < parts.length - 1) {
                  temp.push(
                    <mark key={`${lIdx}-${pIdx}-${keyword}`} className="bg-red-100 text-red-700 font-extrabold px-1 rounded border border-red-200">
                      {keyword}
                    </mark>
                  );
                }
              });
            } else {
              temp.push(elem);
            }
          } else {
            temp.push(elem);
          }
        });
        elements = temp;
      });

      return <div key={lIdx} className="my-1 text-xs leading-relaxed">{elements}</div>;
    });
  };

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Navigation Header */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <span className="text-base font-extrabold text-[#121c26]">
          รายละเอียดผลการตรวจ
        </span>
        <div className="w-10" /> {/* Balance spacer */}
      </div>

      {/* Main Details Body */}
      <div className="flex-1 max-w-md mx-auto w-full p-5 flex flex-col gap-5">
        
        {/* Upper radial ring score card */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 flex items-center justify-between shadow-sm">
          <div className="flex-1">
            <h2 className="text-sm font-black text-[#121c26]">คะแนนรวมความเสี่ยง</h2>
            <p className="text-[11px] text-[#5e6b78] mt-1 leading-normal">
              วิเคราะห์ประมวลผลจากการตรวจสอบข้อมูลตัวอักษร แหล่งอ้างอิง และรูปภาพโดยรวม
            </p>
          </div>
          <div className="relative w-18 h-18 flex items-center justify-center bg-[#f0f4f8] rounded-full border border-gray-200">
            <span className="text-xl font-black text-[#006685]">{scan.score}%</span>
          </div>
        </div>

        {/* 1. OCR TEXT ANALYSIS CARD */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-3.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText className="w-5 h-5 text-[#006685]" />
              <h3 className="text-xs font-black text-[#121c26] tracking-tight">
                ผลการอ่านข้อความในภาพ (OCR Checking)
              </h3>
            </div>
            <span className={`text-[9px] font-black px-2 py-1 rounded-full ${getStatusBadge(ocrAnalysis.status)}`}>
              {ocrAnalysis.status === "DANGER" ? "อันตราย" : ocrAnalysis.status === "WARNING" ? "เฝ้าระวัง" : "ปกติ"}
            </span>
          </div>

          <p className="text-xs text-[#5e6b78] leading-relaxed">
            {ocrAnalysis.details}
          </p>

          {/* List of flag badges */}
          <div className="flex flex-wrap gap-1.5 mt-1">
            {ocrAnalysis.flags.map((flag, idx) => (
              <span
                key={idx}
                className="px-2.5 py-1 bg-red-50 text-red-600 rounded-full text-[9px] font-bold border border-red-100 flex items-center gap-1 shrink-0"
              >
                <AlertTriangle className="w-3 h-3 text-red-500 animate-pulse" />
                <span>{flag}</span>
              </span>
            ))}
          </div>

          {/* Text OCR print console */}
          <div className="bg-gray-50 border border-gray-100 rounded-2xl p-4 mt-2 max-h-40 overflow-y-auto font-mono text-gray-700">
            <div className="flex justify-between border-b border-gray-200/60 pb-1.5 mb-2 text-[10px] text-gray-400 font-bold">
              <span>RAW OCR CONTENT</span>
              <span>ความถูกต้อง {ocrAnalysis.confidence}%</span>
            </div>
            {renderHighlightedOcr(ocrText)}
          </div>
        </div>

        {/* 2. SOURCE CHECKER ANALYSIS CARD */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-3.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Globe className="w-5 h-5 text-[#006685]" />
              <h3 className="text-xs font-black text-[#121c26] tracking-tight">
                ผลการวิเคราะห์แหล่งที่มา (Source Checking)
              </h3>
            </div>
            <span className={`text-[9px] font-black px-2 py-1 rounded-full ${getStatusBadge(sourceCheck.status)}`}>
              {sourceCheck.status === "DANGER" ? "อันตราย" : sourceCheck.status === "WARNING" ? "เฝ้าระวัง" : "ปกติ"}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-3.5 border-b border-gray-100 pb-3">
            <div>
              <span className="text-[10px] text-gray-400 font-bold block">วันที่ตรวจพบครั้งแรก</span>
              <span className="text-xs font-black text-[#121c26] block mt-0.5">{sourceCheck.firstSeen}</span>
            </div>
            <div>
              <span className="text-[10px] text-gray-400 font-bold block">อัตราการทำซ้ำ</span>
              <span className="text-xs font-black text-red-600 block mt-0.5">{sourceCheck.frequency} ครั้ง</span>
            </div>
          </div>

          {/* Blacklisted domains list */}
          <div>
            <span className="text-[10px] text-gray-400 font-bold block mb-2">ลิงก์ที่ตรงกับแบล็คลิสต์หลอกลวง</span>
            {sourceCheck.blacklistLinks.length === 0 ? (
              <div className="p-3.5 bg-emerald-50 text-emerald-700 rounded-2xl border border-emerald-100 text-xs font-bold flex items-center gap-2 shadow-sm">
                <Check className="w-4 h-4" strokeWidth={3} />
                <span>ไม่พบลิงก์หรือผู้ส่งติดบัญชีแบล็คลิสต์</span>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {sourceCheck.blacklistLinks.map((link, idx) => (
                  <div
                    key={idx}
                    className="p-3 bg-red-50 text-red-700 border border-red-100 rounded-2xl flex items-center justify-between text-xs font-semibold"
                  >
                    <span className="font-mono truncate max-w-[220px]">{link}</span>
                    <span className="text-[9px] font-bold bg-red-600 text-white px-2 py-0.5 rounded">
                      BLACKLISTED
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* 3. VISUAL CHECK METADATA CARD */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-3.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Cpu className="w-5 h-5 text-[#006685]" />
              <h3 className="text-xs font-black text-[#121c26] tracking-tight">
                วิเคราะห์พิกเซลและการตัดต่อ (Visual Checking)
              </h3>
            </div>
            <span className={`text-[9px] font-black px-2 py-1 rounded-full ${getStatusBadge(visualCheck.status)}`}>
              {visualCheck.status === "DANGER" ? "อันตราย" : visualCheck.status === "WARNING" ? "เฝ้าระวัง" : "ปกติ"}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-3.5 border-b border-gray-100 pb-3">
            <div>
              <span className="text-[10px] text-gray-400 font-bold block">โอกาสเป็น AI Generated</span>
              <span className="text-xs font-black text-[#121c26] block mt-0.5">{visualCheck.aiGeneratedProb}%</span>
            </div>
            <div>
              <span className="text-[10px] text-gray-400 font-bold block">ระดับความคลาดเคลื่อนพิกเซล</span>
              <span className="text-xs font-black text-amber-500 block mt-0.5">{visualCheck.anomalyScore}</span>
            </div>
          </div>

          <div>
            <span className="text-[10px] text-gray-400 font-bold block mb-1">คำอธิบายทางเทคนิค (XAI)</span>
            <p className="text-xs text-[#5e6b78] leading-relaxed">
              {visualCheck.explanation}
            </p>
          </div>
        </div>
      </div>

      {/* Buttons at the bottom */}
      <div className="p-5 border-t border-[#cbd5e1] bg-white sticky bottom-0 z-10 shadow-inner">
        <div className="max-w-xs mx-auto flex flex-col gap-3">
          <button
            onClick={onReportToOfficials}
            className="w-full py-4 bg-[#006685] hover:bg-[#004d65] text-white font-extrabold rounded-2xl shadow-md flex items-center justify-center gap-2 cursor-pointer transition-colors text-sm"
          >
            <ShieldCheck className="w-5 h-5" />
            <span>ส่งข้อมูลรายงานเจ้าหน้าที่</span>
          </button>

          <button
            onClick={onReset}
            className="w-full py-3.5 bg-white hover:bg-gray-50 border border-[#cbd5e1] text-gray-600 font-extrabold rounded-2xl flex items-center justify-center gap-2 cursor-pointer transition-colors text-xs shadow-sm"
          >
            <span>ตรวจสอบรูปภาพอื่น</span>
          </button>
        </div>
      </div>
    </div>
  );
}
