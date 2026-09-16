import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { CheckCircle2, ExternalLink, Hand, TriangleAlert } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import ConfirmDialog from '../../components/ui/ConfirmDialog.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { ApiError, isAbortError } from '../../lib/api-client.js';
import { formatDateTime, formatMetric, formatNumber } from '../../lib/formatters.js';
import { categoryLabel, resolveMediaUrl } from '../../lib/media.js';
import { useDecideReport, useReport, useStartReview } from './report-queries.js';
import { RiskBadge, StatusBadge } from './badges.jsx';
import HeatmapComparator from './HeatmapComparator.jsx';

function isSafeExternal(url) {
  return typeof url === 'string' && /^(https?:)\/\//i.test(url.trim());
}

function Definition({ label, children }) {
  return (
    <div className="flex gap-2 py-1 text-sm">
      <dt className="w-32 shrink-0 text-ink-2">{label}</dt>
      <dd className="min-w-0 flex-1 break-words">{children}</dd>
    </div>
  );
}

function SafeJson({ data }) {
  if (data === null || data === undefined) return <span className="text-ink-muted">—</span>;
  const text = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
  return (
    <pre className="max-h-48 overflow-auto whitespace-pre-wrap break-all rounded-lg border border-line bg-elevated p-2.5 font-mono text-xs">
      {text}
    </pre>
  );
}

function ScanMetadata({ scan }) {
  if (!scan) {
    return <p className="text-sm text-ink-muted">รายงานนี้ไม่มีข้อมูลสแกนแนบมา</p>;
  }
  const scores = [
    ['คะแนนรวม', scan.total_risk_score],
    ['ข้อความ', scan.text_score],
    ['ภาพ', scan.visual_score],
    ['แหล่งที่มา', scan.source_score],
  ];
  return (
    <dl>
      <div className="mb-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
        {scores.map(([label, value]) => (
          <div key={label} className="rounded-lg border border-line/60 bg-elevated px-2.5 py-2">
            <dt className="text-[11px] text-ink-muted">{label}</dt>
            <dd className="tnum text-[15px] font-bold">{value ?? '—'}</dd>
          </div>
        ))}
      </div>
      <Definition label="ระดับความเสี่ยง">
        <RiskBadge score={scan.total_risk_score} grade={scan.risk_grade} />
      </Definition>
      <Definition label="Image hash">
        <span className="font-mono text-xs">{scan.image_hash ?? '—'}</span>
      </Definition>
      {scan.ai_gen_probability !== null && scan.ai_gen_probability !== undefined && (
        <Definition label="AI-generated">
          <span className="tnum">{formatMetric(scan.ai_gen_probability, 3)}</span>
        </Definition>
      )}
      {Array.isArray(scan.scam_keywords_found) && scan.scam_keywords_found.length > 0 && (
        <Definition label="คำต้องสงสัย">
          <span className="flex flex-wrap gap-1.5">
            {scan.scam_keywords_found.map((kw) => (
              <Badge key={String(kw)} tone="warning">{String(kw)}</Badge>
            ))}
          </span>
        </Definition>
      )}
      {scan.ocr_text && (
        <div className="mt-2">
          <dt className="pb-1 text-sm text-ink-2">ข้อความจาก OCR</dt>
          <dd className="max-h-32 overflow-auto whitespace-pre-wrap break-words rounded-lg border border-line bg-elevated p-2.5 text-[13px]">
            {scan.ocr_text}
          </dd>
        </div>
      )}
      {scan.exif_data !== null && scan.exif_data !== undefined && (
        <div className="mt-2">
          <dt className="pb-1 text-sm text-ink-2">EXIF</dt>
          <dd><SafeJson data={scan.exif_data} /></dd>
        </div>
      )}
    </dl>
  );
}

export default function ReportDetailPage() {
  const { id } = useParams();
  const toast = useToast();
  const query = useReport(id);
  const startReview = useStartReview();
  const decide = useDecideReport();
  const [confirmAction, setConfirmAction] = useState(null); // 'approve' | 'reject' | null
  const [confirming, setConfirming] = useState(false);
  const [conflict, setConflict] = useState(false);

  const handleConflict = () => {
    setConflict(true);
    query.refetch();
  };

  const claimCase = async () => {
    if (!query.data) return;
    try {
      await startReview.mutateAsync({ id: query.data.id, version: query.data.version });
      toast.success(`รับเคส #R-${query.data.id} แล้ว`);
    } catch (error) {
      if (isAbortError(error)) return;
      if (error instanceof ApiError && error.status === 409) {
        handleConflict();
        return;
      }
      toast.error(error?.message ?? 'รับเคสไม่สำเร็จ');
    }
  };

  const confirmDecision = async (note) => {
    if (!query.data || !confirmAction) return;
    setConfirming(true);
    try {
      const status = confirmAction === 'approve' ? 'approved' : 'rejected';
      await decide.mutateAsync({
        id: query.data.id,
        status,
        version: query.data.version,
        admin_note: note,
      });
      toast.success(status === 'approved' ? `อนุมัติรายงาน #R-${query.data.id} แล้ว` : `ปฏิเสธรายงาน #R-${query.data.id} แล้ว`);
      setConfirmAction(null);
      setConflict(false);
    } catch (error) {
      if (error instanceof ApiError && error.status === 409) {
        setConfirmAction(null);
        handleConflict();
        return;
      }
      throw error;
    } finally {
      setConfirming(false);
    }
  };

  if (query.isPending) return <StatePanel state="loading" title="กำลังโหลดรายละเอียดรายงาน" />;
  if (query.isError) {
    const err = query.error;
    if (err instanceof ApiError && err.status === 404) {
      return (
        <>
          <PageHeader eyebrow="รายงาน" title={`#R-${id}`} />
          <StatePanel state="empty" title="ไม่พบรายงาน" hint="รายงานนี้อาจถูกลบหรือ URL ไม่ถูกต้อง" />
        </>
      );
    }
    return (
      <>
        <PageHeader eyebrow="รายงาน" title={`#R-${id}`} />
        <StatePanel
          state={err?.status === 0 ? 'offline' : 'error'}
          title="โหลดรายละเอียดไม่สำเร็จ"
          hint={err?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => query.refetch()}
        />
      </>
    );
  }

  const report = query.data;
  const scan = report.scan && typeof report.scan === 'object' ? report.scan : null;
  const originalUrl = resolveMediaUrl(scan?.raw_image_url ?? scan?.thumbnail_url);
  const heatmapUrl = resolveMediaUrl(scan?.heatmap_image_url);
  const decidable = report.status === 'pending' || report.status === 'reviewing';

  return (
    <>
      <PageHeader
        eyebrow="รายงาน"
        title={`#R-${report.id} ${categoryLabel(report.category)}`}
        description={report.description}
        metadata={[
          <span key="s">ส่งเมื่อ {formatDateTime(report.created_at)}</span>,
          <span key="v">version {formatNumber(report.version)}</span>,
        ]}
      />

      {conflict && (
        <div role="alert" className="mb-4 flex items-start gap-2.5 rounded-xl border border-warn bg-surface px-4 py-3 text-sm">
          <TriangleAlert size={18} aria-hidden="true" className="mt-0.5 shrink-0 text-warn" />
          <p>
            <strong>ข้อมูลถูกแก้ไขโดยผู้ดูแลคนอื่น</strong> — โหลดข้อมูลล่าสุดแล้ว
            กรุณาตรวจสอบรายละเอียดใหม่ก่อนดำเนินการต่อ
          </p>
        </div>
      )}

      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 flex min-w-0 flex-col gap-6 xl:col-span-8">
          <section aria-label="หลักฐาน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-3 text-base font-bold">หลักฐาน</h2>
            <HeatmapComparator originalUrl={originalUrl} heatmapUrl={heatmapUrl} reportId={report.id} />
          </section>

          <section aria-label="ข้อมูลรายงาน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-2 text-base font-bold">ข้อมูลรายงาน</h2>
            <dl>
              <Definition label="หมวดหมู่">{categoryLabel(report.category)}</Definition>
              <Definition label="แพลตฟอร์ม">{report.platform ?? '—'}</Definition>
              <Definition label="URL อ้างอิง">
                {report.reference_url ? (
                  isSafeExternal(report.reference_url) ? (
                    <a href={report.reference_url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 break-all text-action hover:underline">
                      {report.reference_url}
                      <ExternalLink size={13} aria-hidden="true" className="shrink-0" />
                    </a>
                  ) : (
                    <span className="break-all">{report.reference_url}</span>
                  )
                ) : (
                  '—'
                )}
              </Definition>
              <Definition label="ยินยอมใช้วิจัย">
                {report.allow_research_use ? 'ยินยอม' : 'ไม่ยินยอม'}
              </Definition>
            </dl>
          </section>

          <section aria-label="ผู้รายงาน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-2 text-base font-bold">ผู้รายงาน</h2>
            <dl>
              <Definition label="ชื่อ">{report.user?.full_name ?? '—'}</Definition>
              <Definition label="อีเมล">{report.user?.email ?? '—'}</Definition>
              {report.user?.total_reports_submitted !== null && report.user?.total_reports_submitted !== undefined && (
                <Definition label="รายงานทั้งหมด">
                  {formatNumber(report.user.total_reports_submitted)} ครั้ง
                </Definition>
              )}
            </dl>
          </section>

          <section aria-label="ข้อมูลสแกน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-2 text-base font-bold">ข้อมูลสแกน</h2>
            <ScanMetadata scan={scan} />
          </section>
        </div>

        <div className="col-span-12 xl:col-span-4">
          <div className="flex flex-col gap-6 xl:sticky xl:top-6">
            <section aria-label="สถานะการตรวจสอบ" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
              <h2 className="mb-2 text-base font-bold">สถานะการตรวจสอบ</h2>
              <dl>
                <Definition label="สถานะ"><StatusBadge status={report.status} /></Definition>
                <Definition label="Version">{formatNumber(report.version)}</Definition>
                <Definition label="ผู้ตรวจ">
                  {report.moderated_by !== null && report.moderated_by !== undefined ? `#${report.moderated_by}` : '—'}
                </Definition>
                <Definition label="ตรวจเมื่อ">{report.moderated_at ? formatDateTime(report.moderated_at) : '—'}</Definition>
              </dl>
              {report.admin_note && (
                <div className="mt-2 rounded-lg border border-line/60 bg-elevated p-2.5 text-[13px]">
                  <p className="text-xs text-ink-muted">บันทึกก่อนหน้า</p>
                  <p className="mt-0.5 whitespace-pre-wrap break-words">{report.admin_note}</p>
                </div>
              )}
            </section>

            {decidable && (
              <section aria-label="การตัดสิน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
                <h2 className="mb-3 text-base font-bold">การตัดสิน</h2>
                <div className="flex flex-col gap-2.5">
                  {report.status === 'pending' && (
                    <Button
                      variant="secondary"
                      loading={startReview.isPending}
                      onClick={claimCase}
                    >
                      <Hand size={16} aria-hidden="true" />
                      รับเคสเข้าตรวจ
                    </Button>
                  )}
                  <Button variant="primary" onClick={() => setConfirmAction('approve')}>
                    <CheckCircle2 size={16} aria-hidden="true" />
                    อนุมัติรายงาน
                  </Button>
                  <Button variant="danger" onClick={() => setConfirmAction('reject')}>
                    ปฏิเสธรายงาน
                  </Button>
                </div>
                <p className="mt-2.5 text-xs text-ink-muted">
                  การอนุมัติและปฏิเสธต้องยืนยันพร้อมบันทึกเหตุผลทุกครั้ง
                </p>
              </section>
            )}
          </div>
        </div>
      </div>

      <ConfirmDialog
        open={confirmAction === 'approve'}
        onClose={() => setConfirmAction(null)}
        onConfirm={confirmDecision}
        title="อนุมัติรายงาน"
        description={`ยืนยันอนุมัติรายงาน #R-${report.id} — ต้องบันทึก audit note ประกอบการตัดสิน`}
        confirmLabel="อนุมัติ"
        reasonRequired
        reasonLabel="Audit note (บังคับ)"
        confirming={confirming}
      />
      <ConfirmDialog
        open={confirmAction === 'reject'}
        onClose={() => setConfirmAction(null)}
        onConfirm={confirmDecision}
        title="ปฏิเสธรายงาน"
        description={`ยืนยันปฏิเสธรายงาน #R-${report.id} — ต้องระบุเหตุผล`}
        confirmLabel="ปฏิเสธ"
        danger
        reasonRequired
        reasonLabel="เหตุผลการปฏิเสธ (บังคับ)"
        confirming={confirming}
      />
    </>
  );
}
