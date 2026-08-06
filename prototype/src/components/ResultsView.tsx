import React from "react";
import { ArrowLeft, ShieldAlert, Eye, Map, Flag, Share2, ShieldCheck, ChevronRight } from "lucide-react";
import { ScanResult } from "../types";

interface ResultsViewProps {
  scan: ScanResult;
  onBack: () => void;
  onViewDetails: () => void;
  onViewHeatmap: () => void;
  onReportScam: () => void;
}

export default function ResultsView({
  scan,
  onBack,
  onViewDetails,
  onViewHeatmap,
  onReportScam
}: ResultsViewProps) {
  const { score, riskLevel, summary } = scan;

  // Determine colors based on risk level
  const isDanger = riskLevel === "DANGER";
  const isWarning = riskLevel === "WARNING";

  const meterColor = isDanger
    ? "stroke-red-500"
    : isWarning
    ? "stroke-amber-500"
    : "stroke-emerald-500";

  const textColor = isDanger
    ? "text-red-600"
    : isWarning
    ? "text-amber-600"
    : "text-emerald-600";

  const bgColor = isDanger
    ? "bg-red-50 border-red-100 text-red-700"
    : isWarning
    ? "bg-amber-50 border-amber-100 text-amber-700"
    : "bg-emerald-50 border-emerald-100 text-emerald-700";

  // Share functionality trigger
  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: "ผลการวิเคราะห์ความปลอดภัย ScamGuard",
        text: `ผลตรวจสอบภาพ ${scan.name}: ระดับความเสี่ยง ${scan.score}% (${scan.riskLevel})`,
        url: window.location.href
      }).catch(console.error);
    } else {
      navigator.clipboard.writeText(
        `[ScamGuard] ตรวจสอบรูปภาพ: ${scan.name} พบความเสี่ยงระดับ ${scan.riskLevel} (${scan.score}%)`
      );
      alert("คัดลอกลิงก์รายงานผลการวิเคราะห์ไปยังคลิปบอร์ดแล้ว!");
    }
  };

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Top sticky navigation bar */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <span className="text-base font-extrabold text-[#121c26]">
          ผลการวิเคราะห์
        </span>
        <button
          onClick={handleShare}
          className="p-2.5 hover:bg-[#edf4ff] rounded-xl text-[#006685] transition-colors cursor-pointer"
        >
          <Share2 className="w-5 h-5" />
        </button>
      </div>

      {/* Main Results Board Content */}
      <div className="flex-1 max-w-md mx-auto w-full p-5 flex flex-col gap-5">
        
        {/* Semi-circular risk meter gauge card */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-6 flex flex-col items-center text-center shadow-sm relative overflow-hidden">
          {/* Half arc meter SVG representation */}
          <div className="relative w-48 h-28 flex items-center justify-center">
            <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 50">
              {/* Back track arc */}
              <path
                d="M 10 50 A 40 40 0 0 1 90 50"
                fill="none"
                stroke="#f1f5f9"
                strokeWidth="8"
                strokeLinecap="round"
              />
              {/* Foreground risk arc */}
              <path
                d="M 10 50 A 40 40 0 0 1 90 50"
                fill="none"
                className={`${meterColor} transition-all duration-1000 ease-out`}
                strokeWidth="8"
                strokeLinecap="round"
                strokeDasharray="125.6"
                strokeDashoffset={125.6 * (1 - score / 100)}
              />
            </svg>

            {/* Score inside absolute text box */}
            <div className="absolute bottom-0 text-center flex flex-col items-center justify-end h-full">
              <span className="text-3xl font-black text-gray-900 tracking-tight leading-none">
                {score}
              </span>
              <span className="text-[10px] text-gray-400 font-bold mt-1 tracking-wider">
                คะแนนความเสี่ยง
              </span>
            </div>
          </div>

          {/* Risk Level badge */}
          <div
            className={`px-4 py-1.5 rounded-full text-xs font-black mt-4 border flex items-center gap-1.5 shadow-sm ${bgColor}`}
          >
            <span className="w-2 h-2 rounded-full bg-current animate-ping" />
            <span>
              {isDanger
                ? "ความเสี่ยงสูง (DANGER)"
                : isWarning
                ? "เฝ้าระวัง (WARNING)"
                : "ปลอดภัย (SAFE)"}
            </span>
          </div>
        </div>

        {/* Summary analysis card matching screen 7 */}
        <div className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-2.5">
          <h3 className="text-xs font-black text-gray-400 uppercase tracking-wider">
            สรุปผลการวิเคราะห์
          </h3>
          <p className="text-xs text-[#121c26] leading-relaxed font-sans font-bold">
            {summary}
          </p>
        </div>

        {/* Security highlights checklist */}
        <div className="grid grid-cols-2 gap-3">
          {/* Highlight Card 1: Contact check */}
          <div className="bg-white border border-[#cbd5e1] rounded-2xl p-3.5 flex flex-col gap-1.5 shadow-sm">
            <span className="text-[10px] text-gray-400 font-bold font-sans">
              ข้อมูลติดต่อ
            </span>
            <span
              className={`text-sm font-black ${
                scan.highlights.contact === "DANGER"
                  ? "text-red-600"
                  : scan.highlights.contact === "SUSPICIOUS"
                  ? "text-amber-500"
                  : "text-emerald-600"
              }`}
            >
              {scan.highlights.contact === "DANGER"
                ? "อันตรายสูงสุด"
                : scan.highlights.contact === "SUSPICIOUS"
                ? "น่าสงสัย"
                : "ปลอดภัย"}
            </span>
          </div>

          {/* Highlight Card 2: Transaction check */}
          <div className="bg-white border border-[#cbd5e1] rounded-2xl p-3.5 flex flex-col gap-1.5 shadow-sm">
            <span className="text-[10px] text-gray-400 font-bold font-sans">
              ข้อมูลธุรกรรม
            </span>
            <span
              className={`text-sm font-black ${
                scan.highlights.transaction === "DANGER"
                  ? "text-red-600"
                  : scan.highlights.transaction === "WARNING"
                  ? "text-amber-500"
                  : "text-emerald-600"
              }`}
            >
              {scan.highlights.transaction === "DANGER"
                ? "ความเสี่ยงสูง"
                : scan.highlights.transaction === "WARNING"
                ? "ควรตรวจสอบ"
                : "ปลอดภัย"}
            </span>
          </div>
        </div>

        {/* Visual Heatmap Teaser Card */}
        <div
          onClick={onViewHeatmap}
          className="bg-[#121c26] text-white rounded-3xl p-4 flex items-center justify-between border border-white/10 shadow-lg cursor-pointer hover:border-[#00a6d6] transition-all"
        >
          <div className="flex items-center gap-3">
            {/* Tiny image preview with red heat overlay */}
            <div className="w-12 h-12 rounded-xl overflow-hidden bg-white/5 border border-white/10 flex-shrink-0 relative">
              {scan.imageUrl ? (
                <img
                  referrerPolicy="no-referrer"
                  src={scan.imageUrl}
                  alt={scan.name}
                  className="w-full h-full object-cover opacity-70"
                />
              ) : (
                <div className="w-full h-full bg-[#1e2d3b]" />
              )}
              {/* Simulated red heat blot overlay inside teaser */}
              <div className="absolute inset-0 bg-red-500/30 mix-blend-multiply animate-pulse" />
            </div>
            <div>
              <h4 className="text-xs font-black text-white">
                Visual Heatmap
              </h4>
              <p className="text-[10px] text-gray-400 mt-1">
                ดูพื้นที่ที่ระบบ AI ตรวจพบความผิดปกติในเชิงลึก
              </p>
            </div>
          </div>
          <span className="text-[10px] font-bold text-[#00a6d6] px-2 py-1 bg-[#00a6d6]/10 rounded-full shrink-0 flex items-center gap-1">
            <span>พร้อมดู</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </span>
        </div>
      </div>

      {/* Primary Action Button Bar at bottom */}
      <div className="p-5 border-t border-[#cbd5e1] bg-white sticky bottom-0 z-10 shadow-inner">
        <div className="max-w-xs mx-auto flex flex-col gap-2.5">
          {/* Details toggle */}
          <button
            onClick={onViewDetails}
            className="w-full py-4 bg-[#006685] hover:bg-[#004d65] text-white font-extrabold rounded-2xl shadow-md flex items-center justify-center gap-2 cursor-pointer transition-colors text-sm"
          >
            <Eye className="w-5 h-5" />
            <span>ดูรายละเอียดการวิเคราะห์</span>
          </button>

          {/* Heatmap Toggle */}
          <button
            onClick={onViewHeatmap}
            className="w-full py-3.5 bg-white hover:bg-[#edf4ff] border border-[#cbd5e1] text-[#006685] font-extrabold rounded-2xl flex items-center justify-center gap-2 cursor-pointer transition-colors text-xs shadow-sm"
          >
            <Map className="w-4.5 h-4.5" />
            <span>เปิดดู Heatmap</span>
          </button>

          {/* Report Abuse Flag */}
          <button
            onClick={onReportScam}
            className="w-full py-3.5 bg-white hover:bg-red-50 border border-red-200 text-red-600 font-extrabold rounded-2xl flex items-center justify-center gap-2 cursor-pointer transition-colors text-xs"
          >
            <Flag className="w-4 h-4" />
            <span>รายงานภาพต้องสงสัยนี้</span>
          </button>
        </div>
      </div>
    </div>
  );
}
