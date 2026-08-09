import { useState, useEffect } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  ArrowLeft, Check, X, ExternalLink, Loader2,
  Image as ImageIcon, Map as MapIcon, FileText, KeyRound, Camera, User, ShieldAlert,
} from "lucide-react";

import { fetchReportDetail, updateReportStatus } from "@/lib/api";

const statusStyles = {
  pending: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400",
  reviewing: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400",
  approved: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400",
  rejected: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400",
};

const riskColor = (score) => {
  if (score >= 70) return { color: "#ef4444", label: "HIGH" };
  if (score >= 40) return { color: "#eab308", label: "MEDIUM" };
  return { color: "#22c55e", label: "LOW" };
};

const riskBarColor = [
  { key: "text", label: "Text", color: "#818CF8" },
  { key: "visual", label: "Visual", color: "#F472B6" },
  { key: "source", label: "Source", color: "#38BDF8" },
];

function ScoreRing({ value }) {
  const { color, label } = riskColor(value);
  const radius = 34;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (value / 100) * circumference;

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative size-20">
        <svg viewBox="0 0 80 80" className="size-20 -rotate-90">
          <circle cx="40" cy="40" r={radius} fill="none" stroke="currentColor" strokeWidth="8" className="text-slate-200 dark:text-slate-800" />
          <circle
            cx="40" cy="40" r={radius} fill="none" stroke={color} strokeWidth="8"
            strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={offset}
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-xl font-bold text-slate-900 dark:text-slate-100">{value}</span>
          <span className="text-[9px] font-bold tracking-wider text-slate-500 dark:text-slate-400">{label}</span>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <p className="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</p>
      <div className="mt-1 text-sm text-slate-900 dark:text-slate-100">{children}</div>
    </div>
  );
}

export function ReportDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [report, setReport] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [showOriginal, setShowOriginal] = useState(true);
  const [adminNote, setAdminNote] = useState("");
  const [noteError, setNoteError] = useState("");
  const [modalState, setModalState] = useState({ isOpen: false, action: null });
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState("");

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      setLoadError("");
      try {
        const data = await fetchReportDetail(id);
        setReport(data);
        setAdminNote(data.admin_note || "");
      } catch (err) {
        setLoadError(err.message);
      } finally {
        setIsLoading(false);
      }
    }
    load();
  }, [id]);

  const openModal = (action) => {
    setActionError("");
    if (action === "rejected" && !adminNote.trim()) {
      setNoteError("กรุณากรอกบันทึกหรือเหตุผล ก่อนปัดตก");
      return;
    }
    setModalState({ isOpen: true, action });
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    setActionError("");
    try {
      await updateReportStatus(report.id, { status: modalState.action, admin_note: adminNote.trim() || null });
      setModalState({ isOpen: false, action: null });
      navigate("/admin/reports", { replace: true });
    } catch (err) {
      setActionError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex flex-col gap-6 font-sans">
        <div className="h-7 bg-slate-200 dark:bg-slate-800 rounded-md w-40 animate-pulse" />
        <div className="grid gap-4 lg:grid-cols-5">
          <div className="lg:col-span-3 h-72 bg-slate-100 dark:bg-slate-800/50 rounded-xl animate-pulse" />
          <div className="lg:col-span-2 h-72 bg-slate-100 dark:bg-slate-800/50 rounded-xl animate-pulse" />
        </div>
        <div className="h-48 bg-slate-100 dark:bg-slate-800/50 rounded-xl animate-pulse" />
      </div>
    );
  }

  if (loadError || !report) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-20 font-sans">
        <ShieldAlert className="size-12 text-slate-400" />
        <p className="text-slate-500 dark:text-slate-400">{loadError || "ไม่พบรายงาน"}</p>
        <Link to="/admin/reports" className="px-4 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 border border-slate-200 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
          กลับไปยังรายการ
        </Link>
      </div>
    );
  }

  const scan = report.scan;
  const imageUrl = showOriginal ? scan?.thumbnail_url : scan?.heatmap_image_url;

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div>
        <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 mb-1">
          <Link to="/admin/reports" className="hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors">Reports</Link>
          <span>/</span>
          <span className="text-slate-700 dark:text-slate-300">Report #{report.id}</span>
        </div>
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate("/admin/reports")}
              className="p-2 text-slate-500 dark:text-slate-400 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-md hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors outline-none"
              aria-label="Back"
            >
              <ArrowLeft className="size-4" />
            </button>
            <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Report #{report.id}</h2>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${statusStyles[report.status] || statusStyles.pending}`}>
              {report.status}
            </span>
          </div>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-5">
        {/* Left column - report & reporter info */}
        <div className="lg:col-span-3 flex flex-col gap-4">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ข้อมูลรายงาน</h3>
            </div>
            <div className="p-6 grid gap-4 sm:grid-cols-2">
              <Field label="หมวดหมู่">
                <span className="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
                  {report.category}
                </span>
              </Field>
              <Field label="แพลตฟอร์ม">{report.platform || "-"}</Field>
              <Field label="ยินยอมให้ใช้วิจัย">
                <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                  report.allow_research_use ? "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400" : "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
                }`}>
                  {report.allow_research_use ? "ใช่" : "ไม่"}
                </span>
              </Field>
              <Field label="วันที่รายงาน">
                {report.created_at ? new Date(report.created_at).toLocaleString("th-TH") : "-"}
              </Field>
              <div className="sm:col-span-2">
                <Field label="รายละเอียด">
                  <p className="text-sm leading-relaxed text-slate-700 dark:text-slate-300">{report.description || "-"}</p>
                </Field>
              </div>
              {report.reference_url && (
                <div className="sm:col-span-2">
                  <Field label="ลิงก์อ้างอิง">
                    <a href={report.reference_url} target="_blank" rel="noreferrer"
                       className="inline-flex items-center gap-1 text-indigo-600 dark:text-indigo-400 hover:underline">
                      {report.reference_url}
                      <ExternalLink className="size-3" />
                    </a>
                  </Field>
                </div>
              )}
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center gap-2">
              <User className="size-4 text-indigo-600 dark:text-indigo-400" />
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ข้อมูลผู้รายงาน</h3>
            </div>
            <div className="p-6 grid gap-4 sm:grid-cols-3">
              <Field label="ชื่อ">{report.user?.full_name || "Unknown"}</Field>
              <Field label="Email">{report.user?.email || "No Email"}</Field>
              <Field label="รายงานที่เคยส่ง">{report.user?.total_reports_submitted ?? "-"}</Field>
            </div>
          </div>

          {/* Decision section */}
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">การตัดสินใจ</h3>
            </div>
            <div className="p-6">
              {report.status === "approved" || report.status === "rejected" ? (
                <div className={`p-4 rounded-lg border text-sm ${
                  report.status === "approved"
                    ? "bg-emerald-50 dark:bg-emerald-900/10 border-emerald-200 dark:border-emerald-800/50 text-emerald-700 dark:text-emerald-400"
                    : "bg-red-50 dark:bg-red-900/10 border-red-200 dark:border-red-800/50 text-red-700 dark:text-red-400"
                }`}>
                  <p className="font-medium">{report.status === "approved" ? "รายงานนี้ได้รับการอนุมัติแล้ว" : "รายงานนี้ถูกปัดตกแล้ว"}</p>
                  {report.admin_note && <p className="mt-1 text-xs opacity-80">หมายเหตุ: {report.admin_note}</p>}
                </div>
              ) : (
                <>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">Admin Note</label>
                  <textarea
                    value={adminNote}
                    onChange={(e) => { setAdminNote(e.target.value); setNoteError(""); }}
                    rows={4}
                    placeholder="กรอกบันทึกหรือเหตุผลประกอบการตัดสินใจ..."
                    className="mt-2 w-full px-3 py-2 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all resize-y"
                  />
                  {noteError && <p className="mt-1 text-xs text-red-600 dark:text-red-400">{noteError}</p>}
                  {actionError && <p className="mt-2 text-xs text-red-600 dark:text-red-400">{actionError}</p>}
                  <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <button
                      onClick={() => openModal("approved")}
                      className="inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
                    >
                      <Check className="size-4" />
                      อนุมัติ
                    </button>
                    <button
                      onClick={() => openModal("rejected")}
                      className="inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
                    >
                      <X className="size-4" />
                      ปัดตก
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Right column - image & analysis */}
        <div className="lg:col-span-2 flex flex-col gap-4">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
            <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ภาพที่รายงาน</h3>
              {scan?.heatmap_image_url && (
                <div className="flex p-0.5 bg-slate-100 dark:bg-slate-800 rounded-md">
                  <button
                    onClick={() => setShowOriginal(true)}
                    className={`px-2.5 py-1 text-xs font-medium rounded flex items-center gap-1 transition-colors ${
                      showOriginal ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm" : "text-slate-500 dark:text-slate-400"
                    }`}
                  >
                    <ImageIcon className="size-3" /> Original
                  </button>
                  <button
                    onClick={() => setShowOriginal(false)}
                    className={`px-2.5 py-1 text-xs font-medium rounded flex items-center gap-1 transition-colors ${
                      !showOriginal ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm" : "text-slate-500 dark:text-slate-400"
                    }`}
                  >
                    <MapIcon className="size-3" /> Heatmap
                  </button>
                </div>
              )}
            </div>
            <div className="p-6">
              {imageUrl ? (
                <img
                  src={imageUrl}
                  alt="Reported scam"
                  className="w-full aspect-square object-cover rounded-lg border border-slate-200 dark:border-slate-800 bg-slate-100 dark:bg-slate-800"
                  onError={(e) => { e.currentTarget.style.display = "none"; }}
                />
              ) : (
                <div className="w-full aspect-square flex items-center justify-center bg-slate-100 dark:bg-slate-800 rounded-lg text-slate-400">
                  ไม่มีรูปภาพ
                </div>
              )}
            </div>
          </div>

          {scan && (
            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800">
                <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">คะแนนเสี่ยง</h3>
              </div>
              <div className="p-6 flex flex-col items-center gap-5">
                <ScoreRing value={scan.total_risk_score || 0} />
                <div className="w-full flex flex-col gap-3">
                  {riskBarColor.map(({ key, label, color }) => (
                    <div key={key} className="w-full">
                      <div className="flex justify-between text-xs mb-1.5">
                        <span className="text-slate-600 dark:text-slate-400">{label}</span>
                        <span className="font-bold text-slate-900 dark:text-slate-100">{scan[`${key}_score`] || 0}</span>
                      </div>
                      <div className="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                        <div className="h-full rounded-full" style={{ width: `${scan[`${key}_score`] || 0}%`, backgroundColor: color }} />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Analysis */}
          {scan && (
            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800">
                <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">ผลวิเคราะห์</h3>
              </div>
              <div className="p-6 flex flex-col gap-5">
                <div>
                  <p className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400 mb-2">
                    <FileText className="size-3.5" /> OCR Text
                  </p>
                  <pre className="whitespace-pre-wrap text-xs font-mono text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-3 border border-slate-100 dark:border-slate-800">
                    {scan.ocr_text || "No text detected."}
                  </pre>
                </div>
                <div>
                  <p className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400 mb-2">
                    <KeyRound className="size-3.5" /> Scam Keywords
                  </p>
                  <div className="flex flex-wrap gap-1.5">
                    {(scan.scam_keywords_found || []).length > 0 ? scan.scam_keywords_found.map((kw) => (
                      <span key={kw} className="px-2 py-0.5 rounded-full text-xs font-medium bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border border-red-100 dark:border-red-800/50">
                        {kw}
                      </span>
                    )) : <span className="text-xs text-slate-500 dark:text-slate-400">ไม่พบคำสำคัญ</span>}
                  </div>
                </div>
                {scan.exif_data && Object.keys(scan.exif_data).length > 0 && (
                  <div>
                    <p className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400 mb-2">
                      <Camera className="size-3.5" /> EXIF Data
                    </p>
                    <div className="rounded-lg border border-slate-100 dark:border-slate-800 overflow-hidden text-xs">
                      {Object.entries(scan.exif_data).slice(0, 12).map(([key, value]) => (
                        <div key={key} className="flex justify-between gap-4 px-3 py-1.5 border-b border-slate-100 dark:border-slate-800 last:border-b-0">
                          <span className="text-slate-500 dark:text-slate-400">{key}</span>
                          <span className="text-slate-900 dark:text-slate-100 text-right truncate">{String(value)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                <div>
                  <p className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400 mb-2">
                    AI-Generated Probability
                  </p>
                  <div className="flex items-center gap-3">
                    <div className="flex-1 h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                      <div className="h-full rounded-full bg-indigo-500 transition-all"
                           style={{ width: `${Math.min(100, (scan.ai_gen_probability || 0) * 100)}%` }} />
                    </div>
                    <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                      {Math.round((scan.ai_gen_probability || 0) * 100)}%
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Confirmation Modal */}
      {modalState.isOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-xl max-w-md w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-slate-200 dark:border-slate-800">
            <div className="p-6">
              <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-2">
                ยืนยันการ{modalState.action === "approved" ? "อนุมัติ" : "ปัดตก"}รายงาน #{report.id}
              </h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                {modalState.action === "approved"
                  ? "รายงานนี้จะถูกยืนยันว่าเป็นภาพหลอกลวง และนำไปรวมในชุดข้อมูล (Dataset) ได้"
                  : "รายงานนี้จะถูกปัดตก และจะไม่ถูกนำไปใช้ใน Dataset"}
              </p>
            </div>
            <div className="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3">
              <button
                onClick={() => setModalState({ isOpen: false, action: null })}
                className="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
              >
                ยกเลิก
              </button>
              <button
                onClick={handleSubmit}
                disabled={submitting}
                className={`inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white rounded-md transition-colors disabled:opacity-70 disabled:cursor-not-allowed ${
                  modalState.action === "approved"
                    ? "bg-emerald-600 hover:bg-emerald-700"
                    : "bg-red-600 hover:bg-red-700"
                }`}
              >
                {submitting && <Loader2 className="size-4 animate-spin" />}
                ยืนยัน{modalState.action === "approved" ? "อนุมัติ" : "ปัดตก"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}