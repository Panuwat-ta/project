import { useState, useEffect } from "react";

import { Link } from "react-router-dom";
import { Users as UsersIcon, ShieldAlert, ShieldCheck, Search, ChevronLeft, ChevronRight } from "lucide-react";

import { fetchUsers, updateUserStatus } from "@/lib/api";

export function UsersList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState({ isOpen: false, user: null, action: null });
  const [reason, setReason] = useState("");
  const [reasonError, setReasonError] = useState("");

  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");

  const loadUsers = async () => {
    setLoading(true);
    try {
      const data = await fetchUsers(page, 15, search);
      setUsers(data.items || []);
      setTotalPages(data.total_pages || 1);
    } catch (error) {
      console.error("Failed to fetch users", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    setPage(1);
    setSearch(searchInput);
  };

  const toggleUserStatus = async (userId, currentStatus) => {
    if (!reason.trim()) {
      setReasonError("กรุณากรอกเหตุผล");
      return;
    }
    try {
      await updateUserStatus(userId, !currentStatus, reason.trim());
      loadUsers();
      closeModal();
    } catch (error) {
      setReasonError(error.message || "Failed to update user");
      console.error("Failed to update user", error);
    }
  };

  const openModal = (user, action) => {
    setModalState({ isOpen: true, user, action });
    setReason("");
    setReasonError("");
  };

  const closeModal = () => {
    setModalState({ isOpen: false, user: null, action: null });
  };

  const renderStatusBadge = (user) => (
    user.is_active ? (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/50">
        Active
      </span>
    ) : (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border border-red-200 dark:border-red-800/50">
        Banned
      </span>
    )
  );

  const renderRoleBadge = (user) => (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium border ${
      user.role === 'admin' 
        ? "bg-slate-900 dark:bg-slate-100 text-slate-50 dark:text-slate-900 border-slate-900 dark:border-slate-100" 
        : "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700"
    }`}>
      {user.role}
    </span>
  );

  const renderActionButton = (user) => (
    user.is_active ? (
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
    )
  );

  return (
    <div className="flex flex-col gap-6 font-sans relative">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Manage Users</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          จัดการบัญชีผู้ใช้งานระบบ ScamGuard, ตั้งค่าสิทธิ์ และจัดการการแบนบัญชี
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <UsersIcon className="size-5 text-indigo-600 dark:text-indigo-400" />
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ผู้ใช้งานทั้งหมด</h3>
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400">แสดงรายชื่อผู้ใช้งานทั้งหมดในระบบ เรียงตามวันที่สมัคร</p>
          </div>
          
          <form onSubmit={handleSearchSubmit} className="relative w-full md:max-w-xs">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-slate-400" />
            <input
              type="text"
              placeholder="ค้นหาชื่อหรืออีเมล..."
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
            />
          </form>
        </div>

        {/* Desktop table */}
        <div className="hidden md:block flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">ID</th>
                <th className="px-4 py-3 font-medium">Email / ชื่อ</th>
                <th className="px-4 py-3 font-medium">สิทธิ์ (Role)</th>
                <th className="px-4 py-3 font-medium text-center">สแกน (ครั้ง)</th>
                <th className="px-4 py-3 font-medium text-center">ส่งรายงาน</th>
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
                  <td colSpan="7" className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบข้อมูลผู้ใช้งาน
                  </td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-mono text-slate-500 dark:text-slate-400 text-xs">#{user.id}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col">
                        <Link to={`/admin/users/${user.id}`} className="font-medium text-indigo-600 dark:text-indigo-400 hover:underline">
                          {user.email}
                        </Link>
                        {user.full_name && (
                          <span className="text-xs text-slate-500 dark:text-slate-400">{user.full_name}</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">{renderRoleBadge(user)}</td>
                    <td className="px-4 py-3 text-center text-slate-900 dark:text-slate-100 font-medium">{user.total_scans}</td>
                    <td className="px-4 py-3 text-center text-slate-900 dark:text-slate-100 font-medium">{user.total_reports}</td>
                    <td className="px-4 py-3">{renderStatusBadge(user)}</td>
                    <td className="px-4 py-3 text-right">{renderActionButton(user)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Mobile card layout */}
        <div className="md:hidden flex flex-col divide-y divide-slate-200 dark:divide-slate-800">
          {loading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div key={`skeleton-m-${i}`} className="p-4">
                <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
              </div>
            ))
          ) : users.length === 0 ? (
            <div className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">ไม่พบข้อมูลผู้ใช้งาน</div>
          ) : (
            users.map((user) => (
              <div key={user.id} className="p-4 flex flex-col gap-3">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex flex-col min-w-0">
                    <Link to={`/admin/users/${user.id}`} className="font-medium text-indigo-600 dark:text-indigo-400 hover:underline truncate">
                      {user.email}
                    </Link>
                    {user.full_name && (
                      <span className="text-xs text-slate-500 dark:text-slate-400 truncate">{user.full_name}</span>
                    )}
                  </div>
                  <span className="font-mono text-slate-500 dark:text-slate-400 text-xs shrink-0">#{user.id}</span>
                </div>
                <div className="flex justify-between text-sm mt-1 border-t border-slate-100 dark:border-slate-800/50 pt-2">
                  <div className="flex gap-4">
                    <span><span className="text-slate-500">Scans:</span> {user.total_scans}</span>
                    <span><span className="text-slate-500">Reports:</span> {user.total_reports}</span>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {renderRoleBadge(user)}
                  {renderStatusBadge(user)}
                </div>
                <div className="flex justify-end">{renderActionButton(user)}</div>
              </div>
            ))
          )}
        </div>
        
        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-5 py-3 flex items-center justify-between border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">
            <span className="text-sm text-slate-500 dark:text-slate-400">
              หน้า {page} จาก {totalPages}
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1 rounded-md text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
              >
                <ChevronLeft className="size-5" />
              </button>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1 rounded-md text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
              >
                <ChevronRight className="size-5" />
              </button>
            </div>
          </div>
        )}
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
              
              <div className="mt-4">
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">เหตุผลที่ต้องระบุ</label>
                <textarea
                  value={reason}
                  onChange={(e) => { setReason(e.target.value); setReasonError(""); }}
                  placeholder="กรุณาระบุเหตุผลการดำเนินการ..."
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all resize-none"
                  rows="3"
                ></textarea>
                {reasonError && <p className="mt-1 text-xs text-red-600 dark:text-red-400">{reasonError}</p>}
              </div>
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