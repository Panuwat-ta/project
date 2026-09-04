import { useState, useEffect, useCallback } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  ArrowLeft,
  CheckCircle2,
  XCircle,
  Clock,
  FileText,
  AlertTriangle,
  Layers,
  KeyRound,
} from "lucide-react";
import { fetchReportDetail, updateReportStatus, startReviewReport } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { RiskBadge, StatusBadge, Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { HeatmapComparator } from "@/components/ui/HeatmapComparator";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate } from "@/lib/utils";

export function ReportDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();

  const [report, setReport] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  const [isStartingReview, setIsStartingReview] = useState(false);
  const [isSubmittingDecision, setIsSubmittingDecision] = useState(false);

  // Decision Modal State
  const [modalState, setModalState] = useState({
    isOpen: false,
    decision: null, // 'approved' | 'rejected'
  });
  const [adminNote, setAdminNote] = useState("");
  const [noteError, setNoteError] = useState("");

  const loadReport = useCallback(async () => {
    setIsLoading(true);
    setError("");
    try {
      const data = await fetchReportDetail(id);
      setReport(data);
      if (data.admin_note) {
        setAdminNote(data.admin_note);
      }
    } catch (err) {
      console.error("Load report detail failed:", err);
      setError(err.message || "ไม่สามารถโหลดข้อมูลรายงานได้");
      toast.error("เกิดข้อผิดพลาดในการโหลดรายงาน: " + err.message);
    } finally {
      setIsLoading(false);
    }
  }, [id, toast]);

  useEffect(() => {
    loadReport();
  }, [loadReport]);

  // Handle "Start Review" transition: pending -> reviewing
  const handleStartReview = async () => {
    if (!report) return;
    setIsStartingReview(true);
    try {
      const updated = await startReviewReport(report.id, report.version);
      setReport(updated);
      toast.success("เปลี่ยนสถานะเป็น 'กำลังตรวจสอบ (Reviewing)' เรียบร้อยแล้ว");
    } catch (err) {
      if (err.status === 409) {
        toast.error("ข้อมูลถูกแก้ไขโดยผู้ดูแลท่านอื่นแล้ว กรุณารีเฟรชหน้าจอ");
        loadReport();
      } else {
        toast.error("ไม่สามารถเริ่มการตรวจสอบได้: " + err.message);
      }
    } finally {
      setIsStartingReview(false);
    }
  };

  const openDecisionModal = (decision) => {
    setModalState({ isOpen: true, decision });
    setNoteError("");
  };

  const closeDecisionModal = () => {
    if (isSubmittingDecision) return;
    setModalState({ isOpen: false, decision: null });
    setNoteError("");
  };

  // Submit Final Decision: approved or rejected
  const handleSubmitDecision = async () => {
    const { decision } = modalState;
    if (decision === "rejected" && !adminNote.trim()) {
      setNoteError("กรุณาระบุเหตุผลหรือบันทึกของเจ้าหน้าที่ในการปฏิเสธรายงาน");
      return;
    }

    setIsSubmittingDecision(true);
    try {
      const updated = await updateReportStatus(
        report.id,
        report.version,
        decision,
        adminNote.trim()
      );
      setReport(updated);
      closeDecisionModal();
      toast.success(
        decision === "approved"
          ? "ยืนยันรายงานว่าเป็นภาพหลอกลวง (Approved) สำเร็จ"
          : "ปฏิเสธรายงาน (Rejected) สำเร็จ"
      );
    } catch (err) {
      if (err.status === 409) {
        toast.error("เกิดข้อขัดแย้ง: ข้อมูลถูกปรับปรุงโดยผู้อื่นแล้ว กรุณารีเฟรช");
        loadReport();
      } else {
        toast.error("ทำรายการไม่สำเร็จ: " + err.message);
      }
    } finally {
      setIsSubmittingDecision(false);
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-[500px] bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
          <div className="h-[500px] bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  if (error || !report) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4 text-center">
        <div className="size-12 rounded-full bg-rose-500/10 flex items-center justify-center text-rose-500">
          <AlertTriangle className="size-6" />
        </div>
        <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">
          ไม่สามารถเปิดรายงาน #{id} ได้
        </h3>
        <p className="text-xs text-slate-500 max-w-sm">{error || "ไม่พบข้อมูลในระบบ"}</p>
        <Button variant="primary" size="sm" onClick={() => navigate("/admin/reports")}>
          กลับไปคิวรายงาน
        </Button>
      </div>
    );
  }

  const multiLayer = report.multi_layer_analysis || {};
  const isPending = report.status === "pending";
  const isReviewing = report.status === "reviewing";

  return (
    <div className="space-y-6">
      {/* Back and Action Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link
            to="/admin/reports"
            className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-500 hover:text-slate-900 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            title="ย้อนกลับไปคิวรายงาน"
          >
            <ArrowLeft className="size-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-bold font-mono tracking-tight text-slate-900 dark:text-slate-100">
                รายงานตรวจสอบ #{report.id}
              </h2>
              <StatusBadge status={report.status} />
              <RiskBadge score={report.risk_score} />
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
              ส่งตรวจเมื่อ: {formatDate(report.created_at)}
            </p>
          </div>
        </div>

        {/* Workflow Actions */}
        <div className="flex items-center gap-2">
          {isPending && (
            <Button
              variant="primary"
              size="sm"
              icon={Clock}
              isLoading={isStartingReview}
              onClick={handleStartReview}
            >
              รับเรื่องตรวจ (Start Review)
            </Button>
          )}

          {(isReviewing || isPending) && (
            <>
              <Button
                variant="danger"
                size="sm"
                icon={XCircle}
                onClick={() => openDecisionModal("rejected")}
              >
                ปัดตกรายงาน (Reject)
              </Button>

              <Button
                variant="primary"
                size="sm"
                icon={CheckCircle2}
                onClick={() => openDecisionModal("approved")}
                className="bg-emerald-600 hover:bg-emerald-500 text-white"
              >
                ยืนยัน Scam (Approve)
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Main Forensic Workbench: Two Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left: Dual Layer Heatmap & Visual Anomaly Visualizer (7 cols) */}
        <div className="lg:col-span-7 space-y-6">
          <HeatmapComparator
            originalUrl={report.image_url}
            heatmapUrl={report.heatmap_url}
            title="การพิสูจน์ภาพตัดต่อ / AI Deepfake (SegFormer Anomaly)"
          />

          {/* Submitter Note & Reason */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="size-4 text-cyan-400" />
                <span>คำอธิบายจากผู้ส่งรายงาน (User Description)</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 text-sm text-slate-800 dark:text-slate-200 leading-relaxed">
                {report.description || "ไม่มีข้อความเพิ่มเติมจากผู้ส่ง"}
              </div>

              {report.admin_note && (
                <div className="space-y-1">
                  <div className="text-xs font-semibold text-slate-400">บันทึกของเจ้าหน้าที่ (Admin Note):</div>
                  <div className="p-3 rounded-lg bg-cyan-500/5 border border-cyan-500/20 text-xs text-cyan-300 font-mono">
                    {report.admin_note}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right: Multi-Layer XAI & Metadata Breakdown (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          {/* Multi-Layer Intelligence Analysis */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Layers className="size-4 text-cyan-400" />
                <span>การวิเคราะห์หลายชั้น (Multi-layer Analysis)</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Layer 1: Visual Anomaly (SegFormer) */}
              <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                    1. Visual Anomaly (SegFormer AI)
                  </span>
                  <Badge variant={multiLayer.visual_anomaly?.score >= 70 ? "danger" : "primary"} size="sm">
                    {multiLayer.visual_anomaly?.score ?? report.risk_score}%
                  </Badge>
                </div>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {multiLayer.visual_anomaly?.summary || "ตรวจพบจุดรบกวนของพิกเซลและร่องรอยการตัดต่อด้วยโมเดล Semantic Segmentation"}
                </p>
              </div>

              {/* Layer 2: Textual OCR (Surya OCR) */}
              <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                    2. Textual / OCR Analysis (Surya)
                  </span>
                  <Badge variant={multiLayer.textual_analysis?.score >= 70 ? "danger" : "default"} size="sm">
                    {multiLayer.textual_analysis?.score ?? 0}%
                  </Badge>
                </div>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {multiLayer.textual_analysis?.summary || "สกัดข้อความในภาพเพื่อตรวจสอบคำต้องสงสัยและรูปแบบข้อความหลอกลวง"}
                </p>
                {multiLayer.textual_analysis?.extracted_text && (
                  <div className="p-2 rounded bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-[11px] font-mono text-slate-400 max-h-24 overflow-y-auto">
                    {multiLayer.textual_analysis.extracted_text}
                  </div>
                )}
              </div>

              {/* Layer 3: Source Verification (Reverse Search) */}
              <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                    3. Source Verification (Vision)
                  </span>
                  <Badge variant="default" size="sm">
                    {multiLayer.source_verification?.matches_count ?? 0} matches
                  </Badge>
                </div>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {multiLayer.source_verification?.summary || "ค้นหาแหล่งที่มาของภาพผ่านฐานข้อมูลภาพสาธารณะ"}
                </p>
              </div>
            </CardContent>
          </Card>

          {/* Forensic Image & EXIF Metadata */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <KeyRound className="size-4 text-cyan-400" />
                <span>ข้อมูลทางเทคนิค (Forensic Metadata)</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 font-mono text-xs">
              <div className="flex items-center justify-between py-1.5 border-b border-slate-100 dark:border-slate-800/80">
                <span className="text-slate-500">Image Hash (SHA-256):</span>
                <span className="text-slate-300 truncate max-w-[180px]" title={report.image_hash}>
                  {report.image_hash || "-"}
                </span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-slate-100 dark:border-slate-800/80">
                <span className="text-slate-500">ขนาดความละเอียด:</span>
                <span className="text-slate-300">{report.metadata?.dimensions || "1080 x 1920"}</span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-slate-100 dark:border-slate-800/80">
                <span className="text-slate-500">อุปกรณ์ที่ถ่าย (Camera):</span>
                <span className="text-slate-300">{report.metadata?.device || "ไม่ระบุ"}</span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-slate-100 dark:border-slate-800/80">
                <span className="text-slate-500">ยินยอมให้นำไปวิจัย (PDPA):</span>
                <span className={report.allow_research_use ? "text-emerald-400" : "text-slate-400"}>
                  {report.allow_research_use ? "ยินยอม (Consent)" : "ไม่ยินยอม"}
                </span>
              </div>

              <div className="flex items-center justify-between py-1.5">
                <span className="text-slate-500">ผู้ส่งรายงาน:</span>
                <span className="text-slate-300">{report.user_email || "ไม่ระบุ"}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Decision Confirmation Modal */}
      <Modal
        isOpen={modalState.isOpen}
        onClose={closeDecisionModal}
        title={
          modalState.decision === "approved"
            ? "ยืนยันการอนุมัติรายงาน (Mark as Confirmed Scam)"
            : "ปฏิเสธรายงาน (Reject Report)"
        }
        description={
          modalState.decision === "approved"
            ? "การอนุมัติจะเปลี่ยนสถานะรายงานเป็น Approved และนำภาพเข้าสู่ระบบฝึกโมเดลหากได้รับความยินยอม"
            : "การปฏิเสธจะทำเครื่องหมายรายงานเป็น Rejected จำเป็นต้องระบุเหตุผลในการตัดสินใจ"
        }
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={closeDecisionModal} disabled={isSubmittingDecision}>
              ยกเลิก
            </Button>
            <Button
              variant={modalState.decision === "approved" ? "primary" : "danger"}
              size="sm"
              isLoading={isSubmittingDecision}
              onClick={handleSubmitDecision}
            >
              {modalState.decision === "approved" ? "ยืนยันผลการตัดสิน" : "ปฏิเสธรายงาน"}
            </Button>
          </>
        }
      >
        <div className="space-y-4 pt-2">
          <Textarea
            label="บันทึกเหตุผลของเจ้าหน้าที่ (Admin Reason / Note)"
            required={modalState.decision === "rejected"}
            value={adminNote}
            onChange={(e) => {
              setAdminNote(e.target.value);
              setNoteError("");
            }}
            placeholder={
              modalState.decision === "approved"
                ? "ระบุรายละเอียดเพิ่มเติม (ถ้ามี)..."
                : "ระบุสาเหตุที่ปฏิเสธรายงาน เช่น ภาพไม่ปรากฏจุดตัดต่อที่ผิดสังเกต..."
            }
            error={noteError}
            rows={4}
          />
        </div>
      </Modal>
    </div>
  );
}