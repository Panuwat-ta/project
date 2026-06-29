import React from "react";
import { ArrowLeft, Bell, Check, Trash2, ShieldAlert } from "lucide-react";
import { NotificationItem } from "../types";

interface NotificationsViewProps {
  notifications: NotificationItem[];
  onBack: () => void;
  onClear: () => void;
  onRemoveItem: (id: string) => void;
}

export default function NotificationsView({
  notifications,
  onBack,
  onClear,
  onRemoveItem
}: NotificationsViewProps) {
  return (
    <div className="min-h-screen bg-[#f7f9ff] text-[#121c26] flex flex-col justify-between font-sans">
      {/* Header bar */}
      <div className="sticky top-0 z-20 bg-white border-b border-[#cbd5e1] px-5 py-4 flex items-center justify-between shadow-sm">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 hover:bg-gray-100 rounded-full text-[#121c26] transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <span className="text-base font-extrabold text-[#121c26]">
            กล่องแจ้งเตือน
          </span>
        </div>

        {notifications.length > 0 && (
          <button
            onClick={onClear}
            className="p-2.5 text-red-600 hover:bg-red-50 rounded-xl transition-colors cursor-pointer"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Notifications list feed */}
      <div className="flex-1 max-w-md mx-auto w-full p-5 flex flex-col gap-4">
        {notifications.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-8 gap-4 mt-16">
            <div className="p-4 bg-gray-100 text-gray-400 rounded-full shadow-inner">
              <Bell className="w-10 h-10" />
            </div>
            <div>
              <h3 className="text-sm font-black text-gray-800">ไม่มีการแจ้งเตือน</h3>
              <p className="text-[11px] text-gray-400 mt-1 max-w-[200px] mx-auto">
                เมื่อระบบตรวจพบภัยความเสี่ยงใหม่หรือมีอัปเดต จะแสดงข้อมูลตรงนี้ทันที
              </p>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {notifications.map((item) => (
              <div
                key={item.id}
                className="bg-white border border-[#cbd5e1] rounded-3xl p-4 shadow-sm flex items-start gap-3 relative overflow-hidden"
              >
                {/* Visual indicator badge */}
                <div
                  className={`p-2 rounded-xl shrink-0 ${
                    item.type === "success"
                      ? "bg-emerald-50 text-emerald-600"
                      : item.type === "warning"
                      ? "bg-amber-50 text-amber-600"
                      : "bg-red-50 text-red-600"
                  }`}
                >
                  {item.type === "success" ? (
                    <Check className="w-4.5 h-4.5" strokeWidth={3} />
                  ) : (
                    <ShieldAlert className="w-4.5 h-4.5" />
                  )}
                </div>

                {/* Info Text */}
                <div className="flex-1 pr-6">
                  <h4 className="text-xs font-black text-[#121c26]">{item.title}</h4>
                  <p className="text-[11px] text-[#5e6b78] mt-1 leading-normal">
                    {item.message}
                  </p>
                  <span className="text-[9px] text-gray-400 mt-2 block font-medium">
                    {item.time}
                  </span>
                </div>

                {/* Close/Remove action */}
                <button
                  onClick={() => onRemoveItem(item.id)}
                  className="absolute top-3 right-3 p-1 hover:bg-gray-100 rounded-full text-gray-400 hover:text-gray-600 cursor-pointer"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Return button */}
      <div className="p-5 border-t border-[#cbd5e1] bg-white sticky bottom-0 z-10 shadow-inner">
        <button
          onClick={onBack}
          className="w-full max-w-xs mx-auto py-3.5 bg-[#006685] text-white hover:bg-[#004d65] font-extrabold rounded-2xl shadow-md flex items-center justify-center cursor-pointer transition-colors text-xs"
        >
          <span>ย้อนกลับ</span>
        </button>
      </div>
    </div>
  );
}
