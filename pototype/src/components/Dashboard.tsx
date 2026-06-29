import React, { useState, useRef } from "react";
import {
  Shield,
  Bell,
  Upload,
  AlertTriangle,
  CheckCircle,
  Clock,
  Search,
  SlidersHorizontal,
  FileText,
  User,
  ChevronRight,
  LogOut,
  Settings,
  Flag,
  Info,
  ExternalLink,
  Plus,
  Trash2,
  Globe,
  Languages,
  Palette,
  Eye,
  Trash,
  Check,
  Smartphone
} from "lucide-react";
import { ScanResult, TabType, NotificationItem } from "../types";
import { SAFETY_TIPS, INITIAL_HISTORY } from "../data";
import ProfileView from "./ProfileView";

interface DashboardProps {
  userName: string;
  userEmail: string;
  history: ScanResult[];
  notificationsCount: number;
  onSelectScan: (scan: ScanResult) => void;
  onUploadImage: (imageDataUrl: string, fileName: string) => void;
  onNavigateToTab: (tab: TabType) => void;
  onLogout: () => void;
  onViewNotifications: () => void;
  onViewPrivacySettings: () => void;
  onUpdateHistory: (updated: ScanResult[]) => void;
  onUpdateProfile: (name: string, email: string) => void;
}

export default function Dashboard({
  userName,
  userEmail,
  history,
  notificationsCount,
  onSelectScan,
  onUploadImage,
  onNavigateToTab,
  onLogout,
  onViewNotifications,
  onViewPrivacySettings,
  onUpdateHistory,
  onUpdateProfile
}: DashboardProps) {
  const [activeTab, setActiveTab] = useState<TabType>("home");
  const [settingsSubView, setSettingsSubView] = useState<"menu" | "profile">("menu");
  const [dragActive, setDragActive] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFilter, setSelectedFilter] = useState<"ALL" | "SAFE" | "WARNING" | "DANGER">("ALL");
  const fileInputRef = useRef<HTMLInputElement>(null);

  // For Reporting Scam Tab
  const [reportType, setReportType] = useState("");
  const [reportPlatform, setReportPlatform] = useState("");
  const [reportDetails, setReportDetails] = useState("");
  const [reportConsent, setReportConsent] = useState(false);
  const [reportSuccess, setReportSuccess] = useState(false);
  const [uploadedReportImage, setUploadedReportImage] = useState<string | null>(null);

  // Settings mock cache state
  const [cacheSize, setCacheSize] = useState("12.4 MB");

  // Handle Drag Events
  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      handleFile(e.target.files[0]);
    }
  };

  const handleFile = (file: File) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      if (typeof reader.result === "string") {
        onUploadImage(reader.result, file.name);
      }
    };
    reader.readAsDataURL(file);
  };

  const triggerFileSelect = () => {
    fileInputRef.current?.click();
  };

  // Filter history based on search & filter tabs
  const filteredHistory = history.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.summary.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.ocrText.toLowerCase().includes(searchQuery.toLowerCase());

    if (selectedFilter === "ALL") return matchesSearch;
    return matchesSearch && item.riskLevel === selectedFilter;
  });

  // Handle Report Form submit
  const handleReportSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reportType || !reportPlatform) {
      alert("กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน");
      return;
    }
    setReportSuccess(true);
    setTimeout(() => {
      setReportSuccess(false);
      setReportType("");
      setReportPlatform("");
      setReportDetails("");
      setUploadedReportImage(null);
      setReportConsent(false);
    }, 4000);
  };

  const handleReportFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (typeof reader.result === "string") {
          setUploadedReportImage(reader.result);
        }
      };
      reader.readAsDataURL(e.target.files[0]);
    }
  };

  if (activeTab === "settings" && settingsSubView === "profile") {
    return (
      <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans pb-20">
        <ProfileView
          userName={userName}
          userEmail={userEmail}
          onBack={() => setSettingsSubView("menu")}
          onUpdateProfile={onUpdateProfile}
          onDeleteAccount={onLogout}
        />

        {/* Bottom Sticky Tab Navigation Menu */}
        <div className="fixed bottom-0 inset-x-0 z-30 bg-white border-t border-[#cbd5e1] py-2 px-4 shadow-xl flex items-center justify-around">
          {/* Tab button 1: HOME */}
          <button
            onClick={() => {
              setActiveTab("home");
              setSettingsSubView("menu");
            }}
            className="flex flex-col items-center gap-1 cursor-pointer select-none transition-colors text-gray-400 hover:text-gray-600"
          >
            <Smartphone className="w-6 h-6" strokeWidth={2} />
            <span className="text-[10px] font-bold">หน้าหลัก</span>
          </button>

          {/* Tab button 2: HISTORY */}
          <button
            onClick={() => {
              setActiveTab("history");
              setSettingsSubView("menu");
            }}
            className="flex flex-col items-center gap-1 cursor-pointer select-none transition-colors text-gray-400 hover:text-gray-600"
          >
            <Clock className="w-6 h-6" strokeWidth={2} />
            <span className="text-[10px] font-bold">ประวัติ</span>
          </button>

          {/* Tab button 3: REPORT */}
          <button
            onClick={() => {
              setActiveTab("report");
              setSettingsSubView("menu");
            }}
            className="flex flex-col items-center gap-1 cursor-pointer select-none transition-colors text-gray-400 hover:text-gray-600"
          >
            <Flag className="w-6 h-6" strokeWidth={2} />
            <span className="text-[10px] font-bold">แจ้งรายงาน</span>
          </button>

          {/* Tab button 4: SETTINGS */}
          <button
            onClick={() => {
              setActiveTab("settings");
            }}
            className="flex flex-col items-center gap-1 cursor-pointer select-none transition-colors text-[#006685]"
          >
            <Settings className="w-6 h-6" strokeWidth={2.5} />
            <span className="text-[10px] font-bold">ตั้งค่า</span>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans pb-20">
      {/* Top Navigation Bar Header */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <div className="flex items-center gap-2">
          <Shield className="w-6 h-6 text-[#006685]" strokeWidth={2.5} />
          <span className="text-xl font-black text-[#006685] tracking-tight">
            ScamGuard
          </span>
        </div>

        <button
          onClick={onViewNotifications}
          className="relative p-2.5 hover:bg-[#edf4ff] rounded-xl text-[#121c26] transition-colors"
        >
          <Bell className="w-5.5 h-5.5 text-[#006685]" />
          {notificationsCount > 0 && (
            <span className="absolute top-1.5 right-1.5 w-5 h-5 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center border-2 border-white shadow-sm animate-bounce">
              {notificationsCount}
            </span>
          )}
        </button>
      </div>

      {/* Main Tab Rendering */}
      <div className="flex-1 max-w-lg mx-auto w-full p-4">
        {/* TAB 1: HOME */}
        {activeTab === "home" && (
          <div className="flex flex-col gap-6">
            {/* User Greeting block */}
            <div>
              <h2 className="text-2xl font-black text-[#121c26] font-sans">
                สวัสดี, {userName || "ผู้ใช้งาน"}
              </h2>
              <p className="text-xs text-[#5e6b78] mt-1 font-semibold">
                ยินดีต้อนรับกลับสู่ระบบรักษาความปลอดภัยของคุณ
              </p>
            </div>

            {/* Central Upload Dashboard Area */}
            <div
              onDragEnter={handleDrag}
              onDragOver={handleDrag}
              onDragLeave={handleDrag}
              onDrop={handleDrop}
              className={`w-full bg-white border-2 border-dashed rounded-3xl p-6 flex flex-col items-center text-center justify-center transition-all ${
                dragActive
                  ? "border-[#00a6d6] bg-[#edf4ff]/50 scale-[1.01]"
                  : "border-[#cbd5e1] hover:border-[#006685] hover:bg-gray-50/50"
              }`}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileChange}
                className="hidden"
              />

              <div className="p-4 bg-[#edf4ff] text-[#006685] rounded-full mb-4 shadow-sm">
                <Upload className="w-8 h-8" />
              </div>

              <h3 className="text-lg font-extrabold text-[#121c26]">
                ตรวจสอบรูปภาพต้องสงสัย
              </h3>
              <p className="text-xs text-[#5e6b78] mt-2 mb-5 leading-relaxed max-w-[260px] mx-auto">
                เลือกรูปภาพจากอุปกรณ์เพื่อตรวจสอบความเสี่ยง เช่น สลิปโอนเงิน, ข้อความ SMS, QR Code (jpg, jpeg, png, webp)
              </p>

              <button
                onClick={triggerFileSelect}
                className="px-6 py-3 bg-[#006685] hover:bg-[#004d65] text-white font-bold rounded-2xl shadow-md flex items-center gap-2 cursor-pointer transition-colors text-xs"
              >
                <Plus className="w-4 h-4" />
                <span>อัปโหลดรูปภาพ</span>
              </button>
            </div>

            {/* Security Tips horizontal/grid bento section */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-sm font-black text-[#121c26] tracking-tight">
                  💡 เคล็ดลับความปลอดภัย
                </span>
              </div>
              <div className="grid grid-cols-1 gap-3">
                {SAFETY_TIPS.map((tip) => (
                  <div
                    key={tip.id}
                    className="flex items-center gap-3 p-3.5 bg-white border border-[#d8e0ea] rounded-2xl shadow-sm hover:shadow transition-shadow"
                  >
                    <div className="p-2 bg-[#edf4ff] text-[#006685] rounded-xl">
                      {tip.id === "tip1" ? (
                        <CheckCircle className="w-5 h-5" />
                      ) : tip.id === "tip2" ? (
                        <FileText className="w-5 h-5" />
                      ) : (
                        <AlertTriangle className="w-5 h-5 text-amber-500 animate-pulse" />
                      )}
                    </div>
                    <span className="text-xs font-bold text-[#121c26] leading-snug">
                      {tip.title}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Recent Scans preview logs */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-sm font-black text-[#121c26]">
                  ประวัติการสแกนล่าสุด
                </span>
                <button
                  onClick={() => setActiveTab("history")}
                  className="text-xs font-extrabold text-[#006685] hover:underline cursor-pointer"
                >
                  ดูทั้งหมด
                </button>
              </div>

              {history.length === 0 ? (
                <div className="bg-white rounded-2xl p-6 text-center text-xs text-gray-400 border border-gray-100">
                  ไม่มีประวัติการสแกน
                </div>
              ) : (
                <div className="flex flex-col gap-3">
                  {history.slice(0, 3).map((scan) => (
                    <div
                      key={scan.id}
                      onClick={() => onSelectScan(scan)}
                      className="flex items-center justify-between p-3.5 bg-white border border-[#d8e0ea] rounded-2xl cursor-pointer hover:border-[#006685] hover:shadow-sm transition-all shadow-sm"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 border border-gray-100 flex-shrink-0 relative">
                          {scan.imageUrl ? (
                            <img
                              referrerPolicy="no-referrer"
                              src={scan.imageUrl}
                              alt={scan.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center bg-[#edf4ff] text-[#006685]">
                              <FileText className="w-5 h-5" />
                            </div>
                          )}
                        </div>
                        <div>
                          <h4 className="text-xs font-black text-[#121c26] line-clamp-1 max-w-[160px]">
                            {scan.name}
                          </h4>
                          <span className="text-[10px] text-gray-400 mt-1 block">
                            {scan.date}
                          </span>
                        </div>
                      </div>

                      {/* Score or Status badge */}
                      <span
                        className={`text-[10px] font-extrabold px-3 py-1.5 rounded-full select-none ${
                          scan.riskLevel === "DANGER"
                            ? "bg-red-50 text-red-600 border border-red-100"
                            : scan.riskLevel === "WARNING"
                            ? "bg-amber-50 text-amber-600 border border-amber-100"
                            : "bg-emerald-50 text-emerald-600 border border-emerald-100"
                        }`}
                      >
                        {scan.riskLevel === "DANGER"
                          ? "เสี่ยงสูง"
                          : scan.riskLevel === "WARNING"
                          ? "เฝ้าระวัง"
                          : "ปลอดภัย"}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 2: HISTORY */}
        {activeTab === "history" && (
          <div className="flex flex-col gap-4">
            <div>
              <h2 className="text-2xl font-black text-[#121c26]">
                ประวัติการตรวจสอบ
              </h2>
              <div className="flex items-center gap-2 mt-1">
                <span className="text-xs bg-[#bfe9ff] text-[#006685] font-bold px-2.5 py-1 rounded-full">
                  {history.length} รายการ
                </span>
              </div>
            </div>

            {/* Search and Filters */}
            <div className="flex gap-2">
              <div className="relative flex-1">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">
                  <Search className="w-4 h-4" />
                </span>
                <input
                  type="text"
                  placeholder="ค้นหาประวัติ..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2.5 bg-white border border-[#cbd5e1] rounded-2xl text-xs placeholder-gray-400 focus:outline-none focus:border-[#00a6d6]"
                />
              </div>
              <button className="p-2.5 bg-white border border-[#cbd5e1] rounded-2xl text-gray-500 hover:text-gray-700">
                <SlidersHorizontal className="w-5 h-5" />
              </button>
            </div>

            {/* Quick Filter chips */}
            <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-none">
              {(["ALL", "SAFE", "WARNING", "DANGER"] as const).map((filter) => (
                <button
                  key={filter}
                  onClick={() => setSelectedFilter(filter)}
                  className={`px-3.5 py-1.5 rounded-full text-[10px] font-black tracking-wide border transition-all cursor-pointer ${
                    selectedFilter === filter
                      ? "bg-[#006685] border-[#006685] text-white"
                      : "bg-white border-[#cbd5e1] text-[#5e6b78] hover:bg-gray-50"
                  }`}
                >
                  {filter === "ALL"
                    ? "ทั้งหมด"
                    : filter === "SAFE"
                    ? "ปลอดภัย"
                    : filter === "WARNING"
                    ? "เฝ้าระวัง"
                    : "เสี่ยงสูง"}
                </button>
              ))}
            </div>

            {/* History List items */}
            {filteredHistory.length === 0 ? (
              <div className="bg-white rounded-3xl p-10 text-center text-xs text-gray-400 border border-[#cbd5e1] shadow-sm">
                ไม่พบประวัติที่คุณกำลังค้นหา
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {filteredHistory.map((scan) => (
                  <div
                    key={scan.id}
                    onClick={() => onSelectScan(scan)}
                    className="p-4 bg-white border border-[#cbd5e1] rounded-3xl shadow-sm hover:border-[#006685] transition-all cursor-pointer flex gap-4"
                  >
                    {/* Thumbnail preview */}
                    <div className="w-16 h-16 rounded-2xl bg-[#f0f4f8] border border-gray-100 flex-shrink-0 overflow-hidden flex items-center justify-center relative shadow-sm">
                      {scan.imageUrl ? (
                        <img
                          referrerPolicy="no-referrer"
                          src={scan.imageUrl}
                          alt={scan.name}
                          className="w-full h-full object-cover animate-fade-in"
                        />
                      ) : (
                        <FileText className="w-6 h-6 text-[#006685]" />
                      )}
                    </div>

                    {/* Meta info */}
                    <div className="flex-1 flex flex-col justify-between py-0.5">
                      <div>
                        <div className="flex justify-between items-start gap-1">
                          <h3 className="text-xs font-black text-[#121c26] line-clamp-1">
                            {scan.name}
                          </h3>
                          <span
                            className={`text-[9px] font-extrabold px-2 py-0.5 rounded-full select-none shrink-0 ${
                              scan.riskLevel === "DANGER"
                                ? "bg-red-50 text-red-600"
                                : scan.riskLevel === "WARNING"
                                ? "bg-amber-50 text-amber-600"
                                : "bg-emerald-50 text-emerald-600"
                            }`}
                          >
                            {scan.riskLevel === "DANGER"
                              ? "เสี่ยงสูง"
                              : scan.riskLevel === "WARNING"
                              ? "ปานกลาง"
                              : "ปลอดภัย"}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5 text-[10px] text-gray-400 mt-1 font-sans">
                          <Clock className="w-3 h-3" />
                          <span>{scan.date}</span>
                        </div>
                      </div>

                      {/* Match percentage gauge bar */}
                      <div className="mt-2.5">
                        <div className="flex justify-between text-[10px] font-bold text-gray-400 mb-1">
                          <span>ระดับความเสี่ยง</span>
                          <span
                            className={
                              scan.riskLevel === "DANGER"
                                ? "text-red-500"
                                : scan.riskLevel === "WARNING"
                                ? "text-amber-500"
                                : "text-emerald-500"
                            }
                          >
                            {scan.score}%
                          </span>
                        </div>
                        <div className="w-full bg-[#f0f4f8] h-1.5 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all duration-500 ${
                              scan.riskLevel === "DANGER"
                                ? "bg-red-500"
                                : scan.riskLevel === "WARNING"
                                ? "bg-amber-500"
                                : "bg-emerald-500"
                            }`}
                            style={{ width: `${scan.score}%` }}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* TAB 3: REPORT FORM */}
        {activeTab === "report" && (
          <div className="flex flex-col gap-4">
            <div>
              <h2 className="text-2xl font-black text-[#121c26]">
                แจ้งรายงานการหลอกลวง
              </h2>
              <p className="text-xs text-[#5e6b78] mt-1 font-semibold leading-relaxed">
                ช่วยเราสร้างสังคมดิจิทัลที่ปลอดภัยยิ่งขึ้นโดยการแจ้งเบาะแส
              </p>
            </div>

            {reportSuccess ? (
              <div className="bg-emerald-50 border border-emerald-100 rounded-3xl p-6 text-center shadow-md animate-scale-in">
                <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4 shadow-inner">
                  <CheckCircle className="w-10 h-10" />
                </div>
                <h3 className="text-lg font-black text-emerald-800">
                  ส่งรายงานสำเร็จ!
                </h3>
                <p className="text-xs text-emerald-600 mt-2 max-w-[280px] mx-auto leading-relaxed">
                  ขอขอบคุณสำหรับการแจ้งข้อมูล ทีมงานจะดำเนินการสืบสวนและตรวจสอบแบล็คลิสต์เพื่อป้องกันการหลอกลวงทันที
                </p>
              </div>
            ) : (
              <form onSubmit={handleReportSubmit} className="flex flex-col gap-4">
                {/* Image upload preview widget */}
                <div className="bg-white border border-[#cbd5e1] rounded-3xl p-4 shadow-sm flex flex-col gap-3">
                  <span className="text-xs font-bold text-[#121c26]">
                    รูปภาพที่ตรวจสอบ
                  </span>
                  
                  {uploadedReportImage ? (
                    <div className="relative aspect-video w-full rounded-2xl overflow-hidden bg-gray-50 border border-gray-100 flex items-center justify-center">
                      <img
                        referrerPolicy="no-referrer"
                        src={uploadedReportImage}
                        alt="Scam upload report preview"
                        className="w-full h-full object-cover"
                      />
                      <button
                        type="button"
                        onClick={() => setUploadedReportImage(null)}
                        className="absolute top-2 right-2 p-2 bg-black/60 text-white rounded-full hover:bg-black/80 cursor-pointer"
                      >
                        <Trash2 className="w-4.5 h-4.5" />
                      </button>
                    </div>
                  ) : (
                    <div className="w-full h-24 bg-[#f0f4f8] rounded-2xl border border-dashed border-gray-300 flex flex-col items-center justify-center gap-2">
                      <Upload className="w-6 h-6 text-[#006685]" />
                      <label className="text-xs font-bold text-[#006685] hover:underline cursor-pointer">
                        แนบภาพหลักฐาน
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleReportFileChange}
                          className="hidden"
                        />
                      </label>
                    </div>
                  )}
                </div>

                {/* Dropdown Select Report Type */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#121c26]">
                    ประเภทเหตุการณ์ <span className="text-red-500">*</span>
                  </label>
                  <select
                    required
                    value={reportType}
                    onChange={(e) => setReportType(e.target.value)}
                    className="w-full px-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6]"
                  >
                    <option value="">เลือกประเภทการหลอกลวง</option>
                    <option value="PHISHING">ข้อความ SMS / ลิงก์ฟิชชิ่งปลอม</option>
                    <option value="SLIP">สลิปโอนเงินปลอมแปลงแก้ไข</option>
                    <option value="ACCOUNT">บัญชีม้า / บัญชีรับโอนเงินผิดกฎหมาย</option>
                    <option value="IMPERSONATION">แอบอ้างบุคคล / โปรไฟล์หน่วยงานรัฐปลอม</option>
                  </select>
                </div>

                {/* platform input text */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#121c26]">
                    แพลตฟอร์มที่พบ <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
                      <Globe className="w-4.5 h-4.5" />
                    </span>
                    <input
                      required
                      type="text"
                      placeholder="เช่น Facebook, Line, TikTok"
                      value={reportPlatform}
                      onChange={(e) => setReportPlatform(e.target.value)}
                      className="w-full pl-10 pr-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6]"
                    />
                  </div>
                </div>

                {/* Details text area */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#121c26]">
                    รายละเอียดเพิ่มเติม
                  </label>
                  <textarea
                    rows={4}
                    placeholder="ระบุลำดับเหตุการณ์ หรือข้อมูลที่น่าสงสัย..."
                    value={reportDetails}
                    onChange={(e) => setReportDetails(e.target.value)}
                    className="w-full px-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6] resize-none"
                  />
                </div>

                {/* Consent development checkbox */}
                <label className="flex items-start gap-2.5 mt-1 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={reportConsent}
                    onChange={() => setReportConsent(!reportConsent)}
                    className="w-4.5 h-4.5 mt-0.5 accent-[#006685] border-gray-300 rounded cursor-pointer animate-pulse"
                  />
                  <span className="text-[11px] text-[#5e6b78] leading-relaxed">
                    ยินยอมให้ใช้ข้อมูลเพื่อพัฒนาโมเดล AI ในการตรวจสอบและป้องกันภัยไซเบอร์
                  </span>
                </label>

                {/* Submit button */}
                <button
                  type="submit"
                  className="w-full py-3.5 bg-[#006685] text-white hover:bg-[#004d65] font-bold rounded-2xl shadow-md flex items-center justify-center gap-2 mt-2 transition-colors cursor-pointer text-sm"
                >
                  <Flag className="w-4.5 h-4.5" />
                  <span>ส่งรายงาน</span>
                </button>

                <p className="text-[10px] text-gray-400 text-center mt-2 leading-relaxed">
                  ข้อมูลของคุณจะถูกเก็บเป็นความลับและใช้เพื่อความปลอดภัยส่วนรวมเท่านั้น
                </p>
              </form>
            )}
          </div>
        )}

        {/* TAB 4: SETTINGS */}
        {activeTab === "settings" && (
          <div className="flex flex-col gap-5">
            {/* User card profile details matching screen 13 */}
            <div
              onClick={() => setSettingsSubView("profile")}
              className="bg-white border border-[#cbd5e1] rounded-3xl p-4 flex items-center justify-between shadow-sm cursor-pointer hover:bg-gray-50/50 transition-colors animate-fade-in"
            >
              <div className="flex items-center gap-3">
                <div className="w-14 h-14 bg-[#bfe9ff] text-[#006685] rounded-full flex items-center justify-center border-2 border-[#00a6d6] shadow-sm font-bold text-xl relative">
                  {userName.charAt(0) || "U"}
                  <div className="absolute -bottom-1 -right-1 p-1 bg-[#16a34a] text-white rounded-full shadow border-2 border-white flex items-center justify-center">
                    <Check className="w-3.5 h-3.5" strokeWidth={3} />
                  </div>
                </div>
                <div>
                  <h3 className="text-sm font-extrabold text-[#121c26] tracking-tight">
                    {userName || "สมชาย รักความปลอดภัย"}
                  </h3>
                  <span className="text-[10px] text-gray-500 mt-0.5 block font-medium">
                    การป้องกันระดับพื้นฐาน • v1.0.0
                  </span>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 animate-pulse" />
            </div>

            {/* List menu options */}
            <div className="bg-white border border-[#cbd5e1] rounded-3xl overflow-hidden shadow-sm">
              {/* Option 1: Account */}
              <button
                onClick={() => setSettingsSubView("profile")}
                className="w-full px-5 py-4 flex items-center justify-between border-b border-[#cbd5e1] hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <User className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">บัญชี</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>

              {/* Option 2: Notifications settings */}
              <button
                onClick={onViewNotifications}
                className="w-full px-5 py-4 flex items-center justify-between border-b border-[#cbd5e1] hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <Bell className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">การแจ้งเตือน</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>

              {/* Option 3: Language */}
              <button className="w-full px-5 py-4 flex items-center justify-between border-b border-[#cbd5e1] hover:bg-gray-50/50 text-left cursor-pointer transition-all">
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <Languages className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">ภาษา</span>
                </div>
                <div className="flex items-center gap-1">
                  <span className="text-xs text-gray-400 font-semibold">ไทย</span>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              </button>

              {/* Option 4: Theme switcher option */}
              <button className="w-full px-5 py-4 flex items-center justify-between border-b border-[#cbd5e1] hover:bg-gray-50/50 text-left cursor-pointer transition-all">
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <Palette className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">ธีม</span>
                </div>
                <div className="flex items-center gap-1">
                  <span className="text-xs text-gray-400 font-semibold font-sans">สว่าง</span>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              </button>

              {/* Option 5: Privacy consent manager */}
              <button
                onClick={onViewPrivacySettings}
                className="w-full px-5 py-4 flex items-center justify-between border-b border-[#cbd5e1] hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <Shield className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">ความเป็นส่วนตัว</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>

              {/* Option 6: Clear Cache */}
              <button
                onClick={() => {
                  setCacheSize("0.0 MB");
                  alert("ล้างไฟล์ขยะและแคชสำเร็จแล้ว");
                }}
                className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div className="flex items-center gap-3.5 text-[#121c26]">
                  <div className="p-2 bg-[#edf4ff] rounded-xl text-[#006685]">
                    <Trash className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold">ล้างแคช</span>
                </div>
                <div className="flex items-center gap-1">
                  <span className="text-xs text-gray-400 font-mono font-semibold">
                    {cacheSize}
                  </span>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              </button>
            </div>

            {/* Logout button */}
            <button
              onClick={onLogout}
              className="w-full py-3.5 bg-white hover:bg-red-50 text-red-600 border border-red-200 font-extrabold rounded-2xl flex items-center justify-center gap-2 mt-4 cursor-pointer transition-colors text-sm shadow-sm"
            >
              <LogOut className="w-4.5 h-4.5" />
              <span>ออกจากระบบ</span>
            </button>
          </div>
        )}
      </div>

      {/* Bottom Sticky Tab Navigation Menu */}
      <div className="fixed bottom-0 inset-x-0 z-30 bg-white border-t border-[#cbd5e1] py-2 px-4 shadow-xl flex items-center justify-around">
        {/* Tab button 1: HOME */}
        <button
          onClick={() => {
            setActiveTab("home");
            setSettingsSubView("menu");
          }}
          className={`flex flex-col items-center gap-1 cursor-pointer select-none transition-colors ${
            activeTab === "home" ? "text-[#006685]" : "text-gray-400 hover:text-gray-600"
          }`}
        >
          <Smartphone className="w-6 h-6" strokeWidth={activeTab === "home" ? 2.5 : 2} />
          <span className="text-[10px] font-bold">หน้าหลัก</span>
        </button>

        {/* Tab button 2: HISTORY */}
        <button
          onClick={() => {
            setActiveTab("history");
            setSettingsSubView("menu");
          }}
          className={`flex flex-col items-center gap-1 cursor-pointer select-none transition-colors ${
            activeTab === "history" ? "text-[#006685]" : "text-gray-400 hover:text-gray-600"
          }`}
        >
          <Clock className="w-6 h-6" strokeWidth={activeTab === "history" ? 2.5 : 2} />
          <span className="text-[10px] font-bold">ประวัติ</span>
        </button>

        {/* Tab button 3: REPORT */}
        <button
          onClick={() => {
            setActiveTab("report");
            setSettingsSubView("menu");
          }}
          className={`flex flex-col items-center gap-1 cursor-pointer select-none transition-colors ${
            activeTab === "report" ? "text-[#006685]" : "text-gray-400 hover:text-gray-600"
          }`}
        >
          <Flag className="w-6 h-6" strokeWidth={activeTab === "report" ? 2.5 : 2} />
          <span className="text-[10px] font-bold">แจ้งรายงาน</span>
        </button>

        {/* Tab button 4: SETTINGS */}
        <button
          onClick={() => setActiveTab("settings")}
          className={`flex flex-col items-center gap-1 cursor-pointer select-none transition-colors ${
            activeTab === "settings" ? "text-[#006685]" : "text-gray-400 hover:text-gray-600"
          }`}
        >
          <Settings className="w-6 h-6" strokeWidth={activeTab === "settings" ? 2.5 : 2} />
          <span className="text-[10px] font-bold">ตั้งค่า</span>
        </button>
      </div>
    </div>
  );
}
