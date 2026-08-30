import { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { getUser, updateUserStatus } from "@/lib/api";
import { 
  ArrowLeft, 
  ShieldAlert, 
  CheckCircle2, 
  Ban, 
  Activity,
  FileText,
  AlertCircle
} from "lucide-react";

export function UserDetail() {
  const { id } = useParams();
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [showBanModal, setShowBanModal] = useState(false);
  const [banReason, setBanReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchUser = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getUser(id);
      setUser(data);
    } catch (err) {
      setError(err.message || "Failed to load user details");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUser();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleToggleStatus = async (e) => {
    e.preventDefault();
    if (!banReason.trim()) {
      alert("กรุณาระบุเหตุผล");
      return;
    }

    try {
      setIsSubmitting(true);
      await updateUserStatus(user.id, !user.is_active, banReason);
      setShowBanModal(false);
      setBanReason("");
      await fetchUser();
    } catch (err) {
      alert(err.message || "Failed to update user status");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <AlertCircle className="mx-auto h-12 w-12 text-red-500 mb-4" />
        <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100">{error}</h3>
        <Link to="/admin/users" className="mt-4 text-indigo-600 hover:text-indigo-500 inline-block">
          กลับไปหน้ารายชื่อผู้ใช้
        </Link>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link 
            to="/admin/users"
            className="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <ArrowLeft className="h-5 w-5 text-gray-500 dark:text-gray-400" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
              {user.full_name || "ไม่มีชื่อ"}
              {!user.is_active && (
                <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">
                  ถูกระงับ
                </span>
              )}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">{user.email}</p>
          </div>
        </div>
        <div>
          <button
            onClick={() => setShowBanModal(true)}
            className={`px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors ${
              user.is_active 
                ? "bg-red-50 text-red-600 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40" 
                : "bg-green-50 text-green-600 hover:bg-green-100 dark:bg-green-900/20 dark:hover:bg-green-900/40"
            }`}
          >
            {user.is_active ? (
              <>
                <Ban className="h-4 w-4" />
                ระงับบัญชี
              </>
            ) : (
              <>
                <CheckCircle2 className="h-4 w-4" />
                ปลดระงับบัญชี
              </>
            )}
          </button>
        </div>
      </div>

      {/* Ban Reason Alert */}
      {!user.is_active && user.ban_reason && (
        <div className="bg-red-50 dark:bg-red-900/20 p-4 rounded-xl border border-red-100 dark:border-red-900/50 flex gap-3">
          <ShieldAlert className="h-5 w-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
          <div>
            <h3 className="text-sm font-medium text-red-800 dark:text-red-300">เหตุผลที่ถูกระงับบัญชี</h3>
            <p className="mt-1 text-sm text-red-700 dark:text-red-400">{user.ban_reason}</p>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 p-5">
          <dt className="truncate text-sm font-medium text-gray-500 dark:text-gray-400 flex items-center gap-2">
            <Activity className="h-4 w-4" /> การสแกนทั้งหมด
          </dt>
          <dd className="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">{user.stats?.total_scans || 0}</dd>
          <dd className="mt-1 text-sm text-gray-500 dark:text-gray-400">ในเดือนนี้: {user.stats?.scans_this_month || 0}</dd>
        </div>
        
        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 p-5">
          <dt className="truncate text-sm font-medium text-gray-500 dark:text-gray-400 flex items-center gap-2">
            <FileText className="h-4 w-4" /> ส่งรายงานทั้งหมด
          </dt>
          <dd className="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">{user.stats?.total_reports_submitted || 0}</dd>
        </div>

        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 p-5">
          <dt className="truncate text-sm font-medium text-gray-500 dark:text-gray-400 flex items-center gap-2">
            <CheckCircle2 className="h-4 w-4 text-green-500" /> รายงานที่อนุมัติ
          </dt>
          <dd className="mt-2 text-3xl font-semibold text-green-600 dark:text-green-400">{user.stats?.reports_approved || 0}</dd>
        </div>

        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 p-5">
          <dt className="truncate text-sm font-medium text-gray-500 dark:text-gray-400 flex items-center gap-2">
            <Ban className="h-4 w-4 text-red-500" /> รายงานที่ถูกปัดตก
          </dt>
          <dd className="mt-2 text-3xl font-semibold text-red-600 dark:text-red-400">{user.stats?.reports_rejected || 0}</dd>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Scans */}
        <div className="bg-white dark:bg-gray-800 shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 dark:border-gray-700">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">การสแกนล่าสุด (10 รายการ)</h3>
          </div>
          <ul className="divide-y divide-gray-100 dark:divide-gray-700">
            {user.recent_scans?.length > 0 ? (
              user.recent_scans.map((scan) => (
                <li key={scan.id} className="px-6 py-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-900 dark:text-white flex items-center gap-2">
                        ความเสี่ยง: {scan.total_risk_score}%
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          scan.total_risk_score >= 70 ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' :
                          scan.total_risk_score >= 40 ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-500' :
                          'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                        }`}>
                          {scan.total_risk_score >= 70 ? 'High' : scan.total_risk_score >= 40 ? 'Medium' : 'Low'}
                        </span>
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        โอกาสสร้างจาก AI: {(scan.ai_gen_probability * 100).toFixed(1)}%
                      </p>
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {new Date(scan.created_at).toLocaleString("th-TH")}
                    </div>
                  </div>
                </li>
              ))
            ) : (
              <li className="px-6 py-8 text-center text-gray-500 dark:text-gray-400 text-sm">
                ไม่มีประวัติการสแกน
              </li>
            )}
          </ul>
        </div>

        {/* Recent Reports */}
        <div className="bg-white dark:bg-gray-800 shadow-sm rounded-xl border border-gray-100 dark:border-gray-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 dark:border-gray-700">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">รายงานล่าสุด (10 รายการ)</h3>
          </div>
          <ul className="divide-y divide-gray-100 dark:divide-gray-700">
            {user.recent_reports?.length > 0 ? (
              user.recent_reports.map((report) => (
                <li key={report.id} className="px-6 py-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <Link to={`/admin/reports/${report.id}`} className="text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:underline">
                        Report #{report.id}
                      </Link>
                      <div className="flex items-center gap-2 mt-1">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          report.status === 'approved' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                          report.status === 'rejected' ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' :
                          report.status === 'reviewing' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400' :
                          'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-500'
                        }`}>
                          {report.status}
                        </span>
                        <span className="text-xs text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded-full">
                          {report.category}
                        </span>
                      </div>
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {new Date(report.created_at).toLocaleString("th-TH")}
                    </div>
                  </div>
                </li>
              ))
            ) : (
              <li className="px-6 py-8 text-center text-gray-500 dark:text-gray-400 text-sm">
                ไม่มีประวัติการส่งรายงาน
              </li>
            )}
          </ul>
        </div>
      </div>

      {/* Ban Modal */}
      {showBanModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-screen items-center justify-center p-4 text-center sm:p-0">
            <div className="fixed inset-0 bg-gray-500/75 dark:bg-gray-900/80 transition-opacity" onClick={() => !isSubmitting && setShowBanModal(false)} />
            
            <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-gray-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
              <form onSubmit={handleToggleStatus}>
                <div className="bg-white dark:bg-gray-800 px-4 pb-4 pt-5 sm:p-6 sm:pb-4">
                  <div className="sm:flex sm:items-start">
                    <div className={`mx-auto flex h-12 w-12 shrink-0 items-center justify-center rounded-full sm:mx-0 sm:h-10 sm:w-10 ${
                      user.is_active ? "bg-red-100 dark:bg-red-900/30" : "bg-green-100 dark:bg-green-900/30"
                    }`}>
                      {user.is_active ? (
                        <Ban className="h-6 w-6 text-red-600 dark:text-red-400" />
                      ) : (
                        <CheckCircle2 className="h-6 w-6 text-green-600 dark:text-green-400" />
                      )}
                    </div>
                    <div className="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                      <h3 className="text-base font-semibold leading-6 text-gray-900 dark:text-white">
                        {user.is_active ? "ระงับบัญชีผู้ใช้" : "ปลดระงับบัญชีผู้ใช้"}
                      </h3>
                      <div className="mt-2">
                        <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
                          คุณกำลังจะ {user.is_active ? "ระงับ" : "ปลดระงับ"} บัญชี <strong>{user.email}</strong>
                          กรุณาระบุเหตุผลเพื่อเก็บบันทึกใน Audit Log
                        </p>
                        <textarea
                          rows={3}
                          className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-900 dark:border-gray-700 dark:text-white sm:text-sm p-3"
                          placeholder="เหตุผลประกอบการตัดสินใจ..."
                          value={banReason}
                          onChange={(e) => setBanReason(e.target.value)}
                          disabled={isSubmitting}
                          required
                        />
                      </div>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-800/50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6">
                  <button
                    type="submit"
                    disabled={isSubmitting || !banReason.trim()}
                    className={`inline-flex w-full justify-center rounded-lg px-3 py-2 text-sm font-semibold text-white shadow-sm sm:ml-3 sm:w-auto ${
                      user.is_active 
                        ? "bg-red-600 hover:bg-red-500 focus-visible:outline-red-600" 
                        : "bg-green-600 hover:bg-green-500 focus-visible:outline-green-600"
                    } disabled:opacity-50`}
                  >
                    {isSubmitting ? "กำลังดำเนินการ..." : "ยืนยัน"}
                  </button>
                  <button
                    type="button"
                    disabled={isSubmitting}
                    className="mt-3 inline-flex w-full justify-center rounded-lg bg-white dark:bg-gray-700 px-3 py-2 text-sm font-semibold text-gray-900 dark:text-gray-200 shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-gray-600 hover:bg-gray-50 dark:hover:bg-gray-600 sm:mt-0 sm:w-auto"
                    onClick={() => setShowBanModal(false)}
                  >
                    ยกเลิก
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
