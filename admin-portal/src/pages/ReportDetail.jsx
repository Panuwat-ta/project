import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  ArrowLeft,
  CheckCircle2,
  XCircle,
  Clock,
  FileText,
  AlertCircle,
  Layers,
  KeyRound,
} from "lucide-react";
import { fetchReportDetail, updateReportStatus, startReviewReport } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { RiskBadge, StatusBadge, Badge, EvidenceState } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { HeatmapComparator } from "@/components/ui/HeatmapComparator";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate } from "@/lib/utils";
import { formatOptionalMetric } from "@/lib/display-state";
import { useAdminQuery } from "@/lib/use-admin-query";

export function ReportDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();

  const [isStartingReview, setIsStartingReview] = useState(false);
  const [isSubmittingDecision, setIsSubmittingDecision] = useState(false);

  // Decision Modal State
  const [modalState, setModalState] = useState({
    isOpen: false,
    decision: null, // 'approved' | 'rejected'
  });
  const [adminNote, setAdminNote] = useState("");
  const [noteError, setNoteError] = useState("");

  const {
    data: report,
    isLoading,
    error,
    reload: loadReport,
  } = useAdminQuery(() => fetchReportDetail(id), {
    deps: [id],
    errorMessage: "ไม่สามารถโหลดข้อมูลรายงานได้",
    logPrefix: "Load report detail failed:",
  });

  // Sync the decision note once per report identity. Quiet refreshes must never
  // clobber text the admin is currently editing.
  const noteSynced = useRef(false);

  useEffect(() => {
    noteSynced.current = false;
    setAdminNote("");
    setNoteError("");
  }, [id]);

  useEffect(() => {
    if (!noteSynced.current && report?.id) {
      setAdminNote(report.admin_note || "");
      noteSynced.current = true;
    }
  }, [report?.id, report?.admin_note]);

  const syncNote = (data) => {
    setAdminNote(data?.admin_note || "");
    noteSynced.current = true;
  };

  // Handle "Start Review" transition: pending -> reviewing
  const handleStartReview = async () => {
    if (!report) return;
    setIsStartingReview(true);
    try {
      await startReviewReport(report.id, report.version);
      const updatedReport = await loadReport();
      if (updatedReport) syncNote(updatedReport);
      toast.success("เริ่มตรวจสอบรายงานแล้ว");
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

  const resetDecisionModal = () => {
    setModalState({ isOpen: false, decision: null });
    setNoteError("");
  };

  const closeDecisionModal = () => {
    if (isSubmittingDecision) return;
    resetDecisionModal();
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
      await updateReportStatus(
        report.id,
        report.version,
        decision,
        adminNote.trim()
      );
      const updatedReport = await loadReport();
      if (updatedReport) syncNote(updatedReport);
      resetDecisionModal();
      toast.success(
        decision === "approved"
          ? "ยืนยันรายงานว่าเป็นการหลอกลวงแล้ว"
          : "ปฏิเสธรายงานแล้ว"
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

  if (error && !report) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <div className="size-14 rounded-full bg-danger-subtle border border-danger-border flex items-center justify-center text-danger">
          <AlertCircle className="size-7" />
        </div>
        <div className="text-center space-y-1">
          <h3 className="text-base font-semibold text-foreground">
            ไม่สามารถโหลดรายละเอียดรายงานได้
          </h3>
          <p className="text-xs text-muted-foreground max-w-sm">{error || "ไม่พบข้อมูลในระบบ"}</p>
        </div>
        <Button
          variant="outline"
          size="sm"
          icon={ArrowLeft}
          onClick={() => navigate("/admin/reports")}
        >
          กลับไปหน้ารายการ
        </Button>
      </div>
    );
  }

  if (isLoading || !report) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-muted rounded animate-pulse w-48" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-[500px] bg-muted rounded-xl animate-pulse" />
          <div className="h-[500px] bg-muted rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  const scan = report.scan || {};
  const sourceStatus = scan.source_status || "unavailable";
  const sourceStatusCopy = {
    unavailable: "Source Verification ยังไม่พร้อมใช้งาน จึงยังสรุปไม่ได้ว่าพบหรือไม่พบภาพที่ตรงกัน",
    not_checked: "ยังไม่ได้ตรวจสอบแหล่งที่มาของภาพนี้",
    checked_no_match: "ระบบตรวจสอบแหล่งที่มาแล้วและไม่พบภาพที่ตรงกัน",
    matches_found: "ระบบตรวจสอบแหล่งที่มาแล้วและพบภาพหรือแหล่งที่มาที่เกี่ยวข้อง",
    error: "การตรวจสอบแหล่งที่มาไม่สำเร็จ จึงยังสรุปผลไม่ได้",
  };
  const isPending = report.status === "pending";
  const isReviewing = report.status === "reviewing";

  return (
    <div className="space-y-6 pb-12">
      {/* Top Bar Navigation and Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate("/admin/reports")}
            className="p-1.5 rounded-lg border border-border text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
            title="กลับไปหน้ารายการ"
            aria-label="กลับไปหน้ารายการรายงาน"
          >
            <ArrowLeft className="size-4" />
          </button>
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-xl font-bold tracking-tight text-foreground">
                รายงาน <span className="font-mono">#{report.id}</span>
              </h2>
              <StatusBadge status={report.status} />
              <RiskBadge score={report.scan?.total_risk_score} />
            </div>
            <p className="text-[13px] text-muted-foreground mt-0.5">
              ส่งตรวจเมื่อ <span className="font-mono">{formatDate(report.created_at)}</span>
            </p>
          </div>
        </div>

        {/* Workflow Actions */}
        <div className="flex flex-wrap items-center gap-2">
          {isPending && (
            <Button
              variant="primary"
              size="sm"
              icon={Clock}
              isLoading={isStartingReview}
              onClick={handleStartReview}
            >
              เริ่มตรวจสอบ
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
                ปฏิเสธ
              </Button>

              <Button
                variant="primary"
                size="sm"
                icon={CheckCircle2}
                onClick={() => openDecisionModal("approved")}
              >
                ยืนยันว่าเป็นการหลอกลวง
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
            originalUrl={report.scan?.raw_image_url}
            heatmapUrl={report.scan?.heatmap_image_url}
            title="จุดผิดปกติที่โมเดลตรวจพบ"
          />

          {/* Submitter Note & Reason */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="size-4 text-primary" />
                <span>รายละเอียดจากผู้รายงาน</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="p-3.5 rounded-lg bg-muted/40 border border-border text-sm text-foreground leading-relaxed">
                {report.description || "ไม่มีข้อความเพิ่มเติมจากผู้ส่ง"}
              </div>

              {report.admin_note && (
                <div className="space-y-1">
                  <div className="text-[13px] font-semibold text-foreground">บันทึกของผู้ตรวจ</div>
                  <div className="p-3 rounded-lg bg-primary-subtle border border-primary-border text-sm text-foreground">
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
                <Layers className="size-4 text-primary" />
                <span>ผลการวิเคราะห์</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0 divide-y divide-border-subtle">
              {/* Layer 1: Visual anomaly evidence from the report API only. */}
              <div className="px-5 py-4 space-y-2">
                <div className="flex items-center justify-between gap-3">
                  <span className="text-[13px] font-semibold text-foreground">
                    ความผิดปกติของภาพ
                  </span>
                  <Badge variant={scan.visual_score == null ? "default" : "primary"} size="sm">
                    {formatOptionalMetric(scan.visual_score, { suffix: "%" })}
                  </Badge>
                </div>
                <p className="text-xs text-muted-foreground">
                  {scan.xai_explanation || "ไม่มีคำอธิบายจากระบบ"}
                </p>
              </div>

              {/* Layer 2: Text analysis. Missing score is unavailable, never zero. */}
              <div className="px-5 py-4 space-y-2">
                <div className="flex items-center justify-between gap-3">
                  <span className="text-[13px] font-semibold text-foreground">
                    ข้อความในภาพ (OCR)
                  </span>
                  <Badge variant={scan.text_score == null ? "default" : "primary"} size="sm">
                    {formatOptionalMetric(scan.text_score, { suffix: "%" })}
                  </Badge>
                </div>
                <p className="text-xs text-muted-foreground">
                  {scan.text_summary || "ไม่มีคำอธิบายจากระบบ"}
                </p>
                {scan.ocr_text && (
                  <div className="p-2 rounded bg-muted border border-border text-xs font-mono text-foreground max-h-24 overflow-y-auto">
                    {scan.ocr_text}
                  </div>
                )}
              </div>

              {/* Source verification state comes from the backend contract; never infer from score alone. */}
              <div className="px-5 py-4 space-y-2">
                <div className="flex items-center justify-between gap-3">
                  <span className="text-[13px] font-semibold text-foreground">
                    การตรวจสอบแหล่งที่มา
                  </span>
                  <EvidenceState status={sourceStatus} className="text-xs" />
                </div>
                <p className="text-xs text-muted-foreground">
                  {sourceStatusCopy[sourceStatus] || "ไม่ทราบสถานะการตรวจสอบแหล่งที่มา"}
                </p>
              </div>
            </CardContent>
          </Card>

          {/* Forensic Image & EXIF Metadata */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <KeyRound className="size-4 text-primary" />
                <span>ข้อมูลไฟล์</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-[13px]">
              <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">Hash (SHA-256):</span>
                <span className="text-foreground font-mono font-semibold truncate max-w-[180px]" title={report.scan?.image_hash}>
                  {report.scan?.image_hash || "-"}
                </span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">ขนาดความละเอียด:</span>
                <span className="text-foreground font-mono font-semibold">{report.scan?.exif_data?.dimensions || report.metadata?.dimensions || "ไม่ระบุ"}</span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">อุปกรณ์ที่ถ่าย:</span>
                <span className="text-foreground font-semibold">{report.metadata?.device || "ไม่ระบุ"}</span>
              </div>

              <div className="flex items-center justify-between py-1.5 border-b border-border-subtle">
                <span className="text-muted-foreground font-medium">อนุญาตให้นำข้อมูลไปใช้วิจัย:</span>
                <span className={report.allow_research_use ? "text-success font-semibold" : "text-muted-foreground font-semibold"}>
                  {report.allow_research_use ? "อนุญาต" : "ไม่อนุญาต"}
                </span>
              </div>

              <div className="flex items-center justify-between py-1.5">
                <span className="text-muted-foreground font-medium">ผู้ส่งรายงาน:</span>
                <span className="text-foreground font-mono font-semibold">{report.user?.email || "ไม่ระบุ"}</span>
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
            ? "ยืนยันรายงานว่าเป็นการหลอกลวง"
            : "ปฏิเสธรายงาน"
        }
        description={
          modalState.decision === "approved"
            ? "รายงานจะถูกยืนยัน และนำภาพไปใช้กับชุดข้อมูลวิจัยเมื่อผู้ใช้อนุญาต"
            : "กรุณาระบุเหตุผลก่อนปฏิเสธรายงาน"
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
            label="บันทึกของผู้ตรวจ"
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