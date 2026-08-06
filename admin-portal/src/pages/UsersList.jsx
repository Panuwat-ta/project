import { useState, useEffect } from "react";

import { Users as UsersIcon, ShieldAlert, ShieldCheck } from "lucide-react";

export function UsersList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState({ isOpen: false, user: null, action: null });

  const loadUsers = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch("/api/v1/admin/users", {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setUsers(data.items || []);
      }
    } catch (error) {
      console.error("Failed to fetch users", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const toggleUserStatus = async (userId, currentStatus) => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch(`/api/v1/admin/users/${userId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify({ is_active: !currentStatus })
      });
      if (res.ok) {
        loadUsers();
        closeModal();
      }
    } catch (error) {
      console.error("Failed to update user", error);
    }
  };

  const openModal = (user, action) => {
    setModalState({ isOpen: true, user, action });
  };

  const closeModal = () => {
    setModalState({ isOpen: false, user: null, action: null });
  };

  return (
    <div className="flex flex-col gap-6 font-sans relative">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Manage Users</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          จัดการบัญชีผู้ใช้งานระบบ ScamGuard, ตั้งค่าสิทธิ์ และจัดการการแบนบัญชี
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2 mb-1">
            <UsersIcon className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ผู้ใช้งานทั้งหมด</h3>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">แสดงรายชื่อผู้ใช้งานทั้งหมดในระบบ เรียงตามวันที่สมัคร</p>
        </div>
        
        <div className="flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">ID</th>
                <th className="px-4 py-3 font-medium">Email / ชื่อ</th>
                <th className="px-4 py-3 font-medium">สิทธิ์ (Role)</th>
                <th className="px-4 py-3 font-medium">สถานะ</th>
                <th className="px-4 py-3 font-medium text-right">จัดการ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <td colSpan="6" className="px-4 py-3">
                      <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบข้อมูลผู้ใช้งาน
                  </td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-xs">#{user.id}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col">
                        <span className="font-medium text-slate-900 dark:text-slate-100">{user.email}</span>
                        {user.full_name && (
                          <span className="text-xs text-slate-500 dark:text-slate-400">{user.full_name}</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium border ${
                        user.role === 'admin' 
                          ? "bg-slate-900 dark:bg-slate-100 text-slate-50 dark:text-slate-900 border-slate-900 dark:border-slate-100" 
                          : "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700"
                      }`}>
                        {user.role}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {user.is_active ? (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/50">
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border border-red-200 dark:border-red-800/50">
                          Banned
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {user.is_active ? (
                        <button 
                          onClick={() => openModal(user, 'ban')}
                          disabled={user.role === 'admin'}
                          className={`inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md transition-colors outline-none focus:ring-2 focus:ring-red-500 ${
                            user.role === 'admin' 
                              ? "bg-slate-100 dark:bg-slate-800 text-slate-400 dark:text-slate-500 cursor-not-allowed" 
                              : "bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/40"
                          }`}
                        >
                          <ShieldAlert className="size-4" />
                          แบนผู้ใช้
                        </button>
                      ) : (
                        <button 
                          onClick={() => openModal(user, 'unban')}
                          className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 rounded-md hover:bg-emerald-100 dark:hover:bg-emerald-900/40 transition-colors outline-none focus:ring-2 focus:ring-emerald-500"
                        >
                          <ShieldCheck className="size-4" />
                          ปลดแบน
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Custom Modal */}
      {modalState.isOpen && modalState.user && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-xl max-w-md w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-slate-200 dark:border-slate-800">
            <div className="p-6">
              <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-2">
                {modalState.action === 'ban' ? 'ยืนยันการแบนบัญชี' : 'ยืนยันการปลดแบนบัญชี'}
              </h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                {modalState.action === 'ban' 
                  ? 'คุณแน่ใจหรือไม่ที่จะแบนผู้ใช้นี้? บัญชีนี้จะไม่สามารถเข้าสู่ระบบและใช้งานฟีเจอร์ต่างๆ ได้อีกจนกว่าจะได้รับการปลดแบน' 
                  : 'คุณกำลังจะคืนสิทธิ์การใช้งานให้กับบัญชีนี้ คุณแน่ใจหรือไม่?'}
              </p>
            </div>
            <div className="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3">
              <button 
                onClick={closeModal}
                className="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors outline-none focus:ring-2 focus:ring-slate-500"
              >
                ยกเลิก
              </button>
              <button 
                onClick={() => toggleUserStatus(modalState.user.id, modalState.user.is_active)}
                className={`px-4 py-2 text-sm font-medium text-white rounded-md transition-colors outline-none ${
                  modalState.action === 'ban' 
                    ? "bg-red-600 hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900" 
                    : "bg-emerald-600 hover:bg-emerald-700 focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
                }`}
              >
                {modalState.action === 'ban' ? 'แบนผู้ใช้' : 'ปลดแบน'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
