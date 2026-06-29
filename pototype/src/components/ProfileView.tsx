import React, { useState, useRef } from "react";
import { ArrowLeft, Camera, ChevronRight, Lock, Trash2, ShieldCheck, Check, User, Mail, ShieldAlert } from "lucide-react";

interface ProfileViewProps {
  userName: string;
  userEmail: string;
  onBack: () => void;
  onUpdateProfile: (name: string, email: string) => void;
  onDeleteAccount: () => void;
}

export default function ProfileView({
  userName,
  userEmail,
  onBack,
  onUpdateProfile,
  onDeleteAccount
}: ProfileViewProps) {
  // Local edit states
  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState(userName);
  const [editEmail, setEditEmail] = useState(userEmail);
  const [englishName, setEnglishName] = useState("Somchai Rak-Plodpai");

  // Password change states
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordSuccess, setPasswordSuccess] = useState(false);
  const [passwordError, setPasswordError] = useState("");

  // Account delete modal state
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  // Avatar file upload reference
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (typeof reader.result === "string") {
          setAvatarUrl(reader.result);
        }
      };
      reader.readAsDataURL(e.target.files[0]);
    }
  };

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editName.trim() || !editEmail.trim()) {
      alert("กรุณากรอกชื่อและอีเมลให้ถูกต้อง");
      return;
    }
    onUpdateProfile(editName, editEmail);
    setIsEditing(false);
  };

  const handlePasswordSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!oldPassword || !newPassword || !confirmPassword) {
      setPasswordError("กรุณากรอกข้อมูลให้ครบทุกช่อง");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError("รหัสผ่านใหม่ไม่ตรงกัน");
      return;
    }
    if (newPassword.length < 6) {
      setPasswordError("รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร");
      return;
    }

    setPasswordSuccess(true);
    setPasswordError("");
    setTimeout(() => {
      setShowPasswordModal(false);
      setPasswordSuccess(false);
      setOldPassword("");
      setNewPassword("");
      setConfirmPassword("");
    }, 2000);
  };

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans pb-24">
      {/* Header Bar */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#006685] transition-colors cursor-pointer"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <span className="text-base font-extrabold text-[#006685] font-sans">
          โปรไฟล์
        </span>
        <div className="w-10" />
      </div>

      <div className="flex-1 max-w-md mx-auto w-full p-5 flex flex-col gap-6">
        {/* Avatar Section */}
        <div className="flex flex-col items-center text-center">
          <div className="relative mb-4">
            {/* Circular Avatar Container */}
            <div className="w-28 h-28 bg-[#d1d5db] border-4 border-[#00a6d6]/30 rounded-full flex items-center justify-center overflow-hidden shadow-md">
              {avatarUrl ? (
                <img
                  referrerPolicy="no-referrer"
                  src={avatarUrl}
                  alt="Profile Avatar"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="flex flex-col items-center justify-center text-gray-700">
                  <span className="text-sm font-black tracking-widest font-mono">img</span>
                </div>
              )}
            </div>

            {/* Pencil edit button */}
            <button
              onClick={() => fileInputRef.current?.click()}
              className="absolute bottom-1 right-1 p-2 bg-[#006685] hover:bg-[#004d65] text-white rounded-full shadow-lg border-2 border-white transition-all cursor-pointer"
            >
              <Camera className="w-4.5 h-4.5" />
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleAvatarChange}
              className="hidden"
            />
          </div>

          <h2 className="text-lg font-black text-[#121c26] tracking-tight">
            {userName}
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            {userEmail}
          </p>

          <button
            onClick={() => setIsEditing(!isEditing)}
            className="mt-4 px-6 py-2.5 bg-[#006685] hover:bg-[#004d65] text-white font-extrabold rounded-2xl shadow-md transition-colors cursor-pointer text-xs"
          >
            แก้ไขโปรไฟล์
          </button>
        </div>

        {/* Profile Details Cards */}
        {isEditing ? (
          <form onSubmit={handleSaveProfile} className="bg-white border border-[#cbd5e1] rounded-3xl p-5 shadow-sm flex flex-col gap-4">
            <h3 className="text-xs font-black text-[#006685] uppercase tracking-wider mb-2">
              แก้ไขข้อมูลส่วนตัว
            </h3>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-black text-[#5e6b78] uppercase">ชื่อ-นามสกุล (ไทย)</label>
              <input
                type="text"
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6] font-bold"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-black text-[#5e6b78] uppercase">ชื่อ-นามสกุล (English)</label>
              <input
                type="text"
                value={englishName}
                onChange={(e) => setEnglishName(e.target.value)}
                className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6] font-bold"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-black text-[#5e6b78] uppercase">อีเมล</label>
              <input
                type="email"
                value={editEmail}
                onChange={(e) => setEditEmail(e.target.value)}
                className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6] font-semibold"
              />
            </div>

            <div className="flex gap-2 mt-2">
              <button
                type="button"
                onClick={() => setIsEditing(false)}
                className="flex-1 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-2xl text-xs transition-colors cursor-pointer"
              >
                ยกเลิก
              </button>
              <button
                type="submit"
                className="flex-1 py-3 bg-[#006685] hover:bg-[#004d65] text-white font-bold rounded-2xl text-xs transition-colors cursor-pointer"
              >
                บันทึก
              </button>
            </div>
          </form>
        ) : (
          <div className="flex flex-col gap-4">
            {/* Primary Details Card */}
            <div className="bg-white border border-[#cbd5e1] rounded-3xl overflow-hidden shadow-sm">
              {/* Row 1: ชื่อ-นามสกุล */}
              <button
                onClick={() => setIsEditing(true)}
                className="w-full px-5 py-4 flex items-center justify-between border-b border-gray-100 hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div>
                  <span className="text-[10px] text-gray-400 font-bold block">ชื่อ-นามสกุล</span>
                  <span className="text-xs font-bold text-[#121c26] mt-1 block">
                    {englishName}
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>

              {/* Row 2: อีเมล */}
              <button
                onClick={() => setIsEditing(true)}
                className="w-full px-5 py-4 flex items-center justify-between border-b border-gray-100 hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div>
                  <span className="text-[10px] text-gray-400 font-bold block">อีเมล</span>
                  <span className="text-xs font-bold text-[#121c26] mt-1 block">
                    {userEmail}
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>

              {/* Row 3: เปลี่ยนรหัสผ่าน */}
              <button
                onClick={() => setShowPasswordModal(true)}
                className="w-full px-5 py-4.5 flex items-center justify-between hover:bg-gray-50/50 text-left cursor-pointer transition-all"
              >
                <div className="flex items-center gap-3">
                  <Lock className="w-4 h-4 text-[#006685]" />
                  <span className="text-xs font-bold text-[#121c26]">
                    เปลี่ยนรหัสผ่าน
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            {/* Standalone Delete Account Container */}
            <button
              onClick={() => setShowDeleteModal(true)}
              className="w-full px-5 py-4 bg-white hover:bg-red-50/50 border border-[#cbd5e1] hover:border-red-200 rounded-3xl flex items-center gap-3 text-red-600 font-extrabold cursor-pointer transition-all text-xs text-left shadow-sm"
            >
              <Trash2 className="w-4.5 h-4.5" />
              <span>ลบบัญชีผู้ใช้งาน</span>
            </button>
          </div>
        )}

        {/* Security watermark footer */}
        <div className="mt-6 flex flex-col items-center gap-2 text-center text-gray-400">
          <div className="p-2.5 bg-[#edf4ff] text-[#006685]/60 rounded-full border border-[#cbd5e1]">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <span className="text-[10px] font-bold uppercase tracking-wider">
            ScamGuard v2.4.0
          </span>
          <span className="text-[9px] text-gray-400/80">
            ระบบความปลอดภัยสากล ได้รับการรับรองสิทธิ์ของท่าน
          </span>
        </div>
      </div>

      {/* MODAL 1: CHANGE PASSWORD */}
      {showPasswordModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs font-sans">
          <div className="bg-white rounded-3xl p-6 w-full max-w-sm border border-[#cbd5e1] shadow-2xl animate-scale-in">
            {passwordSuccess ? (
              <div className="text-center py-6">
                <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Check className="w-6 h-6" strokeWidth={3} />
                </div>
                <h3 className="text-sm font-black text-emerald-800">เปลี่ยนรหัสผ่านสำเร็จ</h3>
                <p className="text-[11px] text-emerald-600 mt-2">รหัสผ่านใหม่ของคุณพร้อมใช้งานแล้ว</p>
              </div>
            ) : (
              <form onSubmit={handlePasswordSubmit} className="flex flex-col gap-4">
                <h3 className="text-sm font-black text-[#121c26]">เปลี่ยนรหัสผ่านใหม่</h3>
                
                {passwordError && (
                  <div className="p-3 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-[10px] font-bold flex gap-2 items-center">
                    <ShieldAlert className="w-4 h-4 shrink-0" />
                    <span>{passwordError}</span>
                  </div>
                )}

                <div className="flex flex-col gap-1.5">
                  <label className="text-[10px] font-bold text-[#5e6b78]">รหัสผ่านเดิม</label>
                  <input
                    required
                    type="password"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6]"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-[10px] font-bold text-[#5e6b78]">รหัสผ่านใหม่</label>
                  <input
                    required
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6]"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-[10px] font-bold text-[#5e6b78]">ยืนยันรหัสผ่านใหม่</label>
                  <input
                    required
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full px-4 py-3 bg-[#f8fafc] border border-[#cbd5e1] rounded-2xl text-xs focus:outline-none focus:border-[#00a6d6]"
                  />
                </div>

                <div className="flex gap-2 mt-2">
                  <button
                    type="button"
                    onClick={() => setShowPasswordModal(false)}
                    className="flex-1 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-2xl text-xs cursor-pointer"
                  >
                    ยกเลิก
                  </button>
                  <button
                    type="submit"
                    className="flex-1 py-3 bg-[#006685] hover:bg-[#004d65] text-white font-bold rounded-2xl text-xs cursor-pointer"
                  >
                    ยืนยัน
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* MODAL 2: DELETE ACCOUNT CONFIRMATION */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs font-sans">
          <div className="bg-white rounded-3xl p-6 w-full max-w-sm border border-[#cbd5e1] shadow-2xl animate-scale-in text-center">
            <div className="w-14 h-14 bg-red-50 text-red-600 rounded-full flex items-center justify-center mx-auto mb-4 shadow-inner">
              <ShieldAlert className="w-8 h-8" />
            </div>
            <h3 className="text-sm font-black text-[#121c26]">ต้องการลบบัญชีใช่หรือไม่?</h3>
            <p className="text-[11px] text-[#5e6b78] mt-2 leading-relaxed">
              การกระทำนี้จะไม่สามารถย้อนกลับได้ ข้อมูลส่วนตัวและประวัติการสแกนทั้งหมดของท่านจะถูกทำลายและลบออกจากระบบอย่างถาวรทันทีตามนโยบาย PDPA
            </p>

            <div className="flex gap-2.5 mt-6">
              <button
                onClick={() => setShowDeleteModal(false)}
                className="flex-1 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-2xl text-xs cursor-pointer"
              >
                ยกเลิก
              </button>
              <button
                onClick={() => {
                  setShowDeleteModal(false);
                  onDeleteAccount();
                }}
                className="flex-1 py-3 bg-red-600 hover:bg-red-700 text-white font-bold rounded-2xl text-xs cursor-pointer"
              >
                ลบข้อมูลถาวร
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
