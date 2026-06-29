import React, { useState } from "react";
import { Shield, ArrowLeft, User, Mail, Lock, Eye, EyeOff, RotateCw, CheckCircle } from "lucide-react";

interface RegisterProps {
  onBack: () => void;
  onLogin: () => void;
  onRegisterSuccess: (name: string, email: string) => void;
}

export default function Register({ onBack, onLogin, onRegisterSuccess }: RegisterProps) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [agree, setAgree] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (!name.trim()) {
      setError("กรุณากรอกชื่อ-นามสกุล");
      return;
    }
    if (!email.trim() || !email.includes("@")) {
      setError("กรุณากรอกอีเมลให้ถูกต้อง");
      return;
    }
    if (password.length < 8) {
      setError("รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร");
      return;
    }
    if (password !== confirmPassword) {
      setError("รหัสผ่านไม่ตรงกัน");
      return;
    }
    if (!agree) {
      setError("กรุณากดยอมรับเงื่อนไขการใช้งาน");
      return;
    }

    onRegisterSuccess(name, email);
  };

  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Top Header */}
      <div className="flex items-center justify-between p-4 bg-white border-b border-[#cbd5e1] sticky top-0 z-10 shadow-sm">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div className="flex items-center gap-1.5">
          <Shield className="w-5 h-5 text-[#006685]" />
          <span className="text-lg font-bold text-[#006685]">ScamGuard</span>
        </div>
        <div className="w-10" /> {/* Balance space */}
      </div>

      {/* Main Content Form */}
      <div className="flex-1 flex flex-col items-center justify-center p-5 max-w-sm mx-auto w-full">
        <div className="w-full bg-white rounded-3xl p-6 border border-[#d8e0ea] shadow-xl">
          <div className="text-center mb-6">
            <h1 className="text-2xl font-black text-[#121c26]">สมัครสมาชิกใหม่</h1>
            <p className="text-xs text-[#5e6b78] mt-1.5">
              เข้าร่วมระบบรักษาความปลอดภัยอัจฉริยะ
            </p>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-50 text-red-600 rounded-xl text-xs font-semibold border border-red-100">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            {/* Name input */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-[#121c26]">ชื่อ-นามสกุล</label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
                  <User className="w-5 h-5" />
                </span>
                <input
                  type="text"
                  placeholder="กรอกชื่อและนามสกุลของคุณ"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full pl-11 pr-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-sm text-[#121c26] placeholder-gray-400 focus:outline-none focus:border-[#00a6d6] focus:ring-1 focus:ring-[#00a6d6]"
                />
              </div>
            </div>

            {/* Email input */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-[#121c26]">อีเมล</label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
                  <Mail className="w-5 h-5" />
                </span>
                <input
                  type="email"
                  placeholder="example@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-11 pr-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-sm text-[#121c26] placeholder-gray-400 focus:outline-none focus:border-[#00a6d6] focus:ring-1 focus:ring-[#00a6d6]"
                />
              </div>
            </div>

            {/* Password input */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-[#121c26]">รหัสผ่าน</label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
                  <Lock className="w-5 h-5" />
                </span>
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="อย่างน้อย 8 ตัวอักษร"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-11 pr-11 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-sm text-[#121c26] placeholder-gray-400 focus:outline-none focus:border-[#00a6d6] focus:ring-1 focus:ring-[#00a6d6]"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-gray-400 hover:text-gray-600 cursor-pointer"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {/* Confirm Password input */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-[#121c26]">ยืนยันรหัสผ่านอีกครั้ง</label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-gray-400">
                  <RotateCw className="w-5 h-5" />
                </span>
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="กรอกรหัสผ่านเดิมอีกครั้ง"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full pl-11 pr-4 py-3 bg-white border border-[#cbd5e1] rounded-2xl text-sm text-[#121c26] placeholder-gray-400 focus:outline-none focus:border-[#00a6d6] focus:ring-1 focus:ring-[#00a6d6]"
                />
              </div>
            </div>

            {/* Consent Terms Box */}
            <label className="flex items-start gap-2.5 mt-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={agree}
                onChange={() => setAgree(!agree)}
                className="w-4 h-4 mt-0.5 accent-[#006685] border-gray-300 rounded cursor-pointer"
              />
              <span className="text-[11px] text-[#5e6b78] leading-relaxed">
                ฉันยอมรับ{" "}
                <span className="text-[#006685] font-bold hover:underline">เงื่อนไขการใช้งาน</span>{" "}
                และ{" "}
                <span className="text-[#006685] font-bold hover:underline">นโยบายความเป็นส่วนตัว</span>{" "}
                ของระบบ ScamGuard
              </span>
            </label>

            {/* Register button */}
            <button
              type="submit"
              className="w-full py-3.5 bg-[#006685] text-white hover:bg-[#004d65] font-bold rounded-2xl shadow-md flex items-center justify-center gap-2 mt-2 cursor-pointer transition-colors text-sm"
            >
              <span>สมัครสมาชิก</span>
              <User className="w-4.5 h-4.5" />
            </button>
          </form>

          {/* Already have an account */}
          <div className="text-center mt-6 pt-5 border-t border-[#edf4ff]">
            <span className="text-xs text-[#5e6b78]">มีบัญชีอยู่แล้ว? </span>
            <button
              onClick={onLogin}
              className="text-xs text-[#006685] font-extrabold hover:underline cursor-pointer"
            >
              เข้าสู่ระบบ
            </button>
          </div>
        </div>
      </div>

      {/* Bottom encryption banner */}
      <div className="p-4 flex justify-center mb-2">
        <div className="px-4 py-1.5 bg-[#edf4ff] text-[#006685] rounded-full text-[10px] font-bold tracking-wider flex items-center gap-2 border border-[#bfe9ff] shadow-sm">
          <CheckCircle className="w-4.5 h-4.5 text-[#006685]" />
          <span>END-TO-END ENCRYPTED DATA PROTECTION</span>
        </div>
      </div>
    </div>
  );
}
