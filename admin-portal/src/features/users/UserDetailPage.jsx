import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { Ban, CheckCircle2 } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import ConfirmDialog from '../../components/ui/ConfirmDialog.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { ApiError, isAbortError } from '../../lib/api-client.js';
import { formatDateTime, formatNumber } from '../../lib/formatters.js';
import { categoryLabel } from '../../lib/media.js';
import { useUpdateUser, useUser } from './user-queries.js';

function Definition({ label, children }) {
  return (
    <div className="flex gap-2 py-1 text-sm">
      <dt className="w-36 shrink-0 text-ink-2">{label}</dt>
      <dd className="min-w-0 flex-1 break-words">{children}</dd>
    </div>
  );
}

function dictText(row) {
  if (!row || typeof row !== 'object') return '—';
  const id = row.id ?? row.scan_id ?? row.report_id ?? '';
  const score = row.total_risk_score ?? row.score;
  const when = row.created_at ? formatDateTime(row.created_at) : '';
  return [id && `#${id}`, score !== undefined && score !== null ? `เสี่ยง ${score}` : '', when].filter(Boolean).join(' · ') || '—';
}

export default function UserDetailPage() {
  const { id } = useParams();
  const toast = useToast();
  const query = useUser(id);
  const updateUser = useUpdateUser();
  const [confirming, setConfirming] = useState(false);
  const [banDialog, setBanDialog] = useState(null); // 'ban' | 'unban' | null

  const submitBan = async (reason) => {
    if (!query.data) return;
    setConfirming(true);
    try {
      await updateUser.mutateAsync({
        id: query.data.id,
        is_active: banDialog === 'unban',
        reason,
      });
      toast.success(banDialog === 'ban' ? 'ระงับผู้ใช้แล้ว' : 'ยกเลิกระงับผู้ใช้แล้ว');
      setBanDialog(null);
    } catch (error) {
      if (isAbortError(error)) {
        setBanDialog(null);
        return;
      }
      throw error;
    } finally {
      setConfirming(false);
    }
  };

  if (query.isPending) return <StatePanel state="loading" title="กำลังโหลดข้อมูลผู้ใช้" />;
  if (query.isError) {
    const err = query.error;
    if (err instanceof ApiError && err.status === 404) {
      return (
        <>
          <PageHeader eyebrow="ผู้ใช้" title={`#${id}`} />
          <StatePanel state="empty" title="ไม่พบผู้ใช้" />
        </>
      );
    }
    return (
      <>
        <PageHeader eyebrow="ผู้ใช้" title={`#${id}`} />
        <StatePanel
          state={err?.status === 0 ? 'offline' : 'error'}
          title="โหลดข้อมูลไม่สำเร็จ"
          hint={err?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => query.refetch()}
        />
      </>
    );
  }

  const user = query.data;
  const stats = [
    ['สแกนทั้งหมด', user.stats.total_scans],
    ['สแกนเดือนนี้', user.stats.scans_this_month],
    ['รายงานที่ส่ง', user.stats.total_reports_submitted],
    ['อนุมัติ', user.stats.reports_approved],
    ['ปฏิเสธ', user.stats.reports_rejected],
    ['รอตรวจ', user.stats.reports_pending],
  ];

  return (
    <>
      <PageHeader
        eyebrow="ผู้ใช้"
        title={user.full_name ?? user.email}
        description={user.email}
        metadata={[<span key="r">บทบาท {user.role}</span>, <span key="c">สมัครเมื่อ {formatDateTime(user.created_at)}</span>]}
        actions={
          user.is_active ? (
            <Button variant="danger" onClick={() => setBanDialog('ban')}>
              <Ban size={16} aria-hidden="true" />
              ระงับผู้ใช้
            </Button>
          ) : (
            <Button variant="secondary" onClick={() => setBanDialog('unban')}>
              <CheckCircle2 size={16} aria-hidden="true" />
              ยกเลิกระงับ
            </Button>
          )
        }
      />

      <div className="mb-4 flex items-center gap-2.5">
        {user.is_active ? (
          <Badge tone="success" icon={<CheckCircle2 size={12} aria-hidden="true" />}>ใช้งาน</Badge>
        ) : (
          <Badge tone="danger" icon={<Ban size={12} aria-hidden="true" />}>ระงับ</Badge>
        )}
        {user.ban_reason && <span className="text-[13px] text-ink-2">เหตุผล: {user.ban_reason}</span>}
      </div>

      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 flex min-w-0 flex-col gap-6 xl:col-span-8">
          <section aria-label="สถิติ" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-3 text-base font-bold">สถิติ</h2>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {stats.map(([label, value]) => (
                <div key={label} className="rounded-lg border border-line/60 bg-elevated px-3 py-2.5">
                  <p className="text-xs text-ink-muted">{label}</p>
                  <p className="tnum text-lg font-bold">{formatNumber(value)}</p>
                </div>
              ))}
            </div>
          </section>

          <section aria-label="สแกนล่าสุด" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-2 text-base font-bold">สแกนล่าสุด</h2>
            {user.recent_scans.length === 0 ? (
              <p className="text-sm text-ink-muted">ไม่มีประวัติสแกน</p>
            ) : (
              <ul className="flex flex-col gap-1.5">
                {user.recent_scans.map((row, i) => (
                  <li key={`${dictText(row)}-${i}`} className="rounded-lg border border-line/60 bg-elevated px-3 py-2 font-mono text-xs">
                    {dictText(row)}
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section aria-label="รายงานล่าสุด" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
            <h2 className="mb-2 text-base font-bold">รายงานล่าสุด</h2>
            {user.recent_reports.length === 0 ? (
              <p className="text-sm text-ink-muted">ไม่มีประวัติรายงาน</p>
            ) : (
              <ul className="flex flex-col gap-1.5">
                {user.recent_reports.map((row, i) => (
                  <li key={`${dictText(row)}-${i}`} className="rounded-lg border border-line/60 bg-elevated px-3 py-2 text-[13px]">
                    {row.category ? `${categoryLabel(row.category)} · ` : ''}{dictText(row)}
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="col-span-12 xl:col-span-4">
          <section aria-label="สถานะการกลั่นกรอง" className="rounded-xl border border-line bg-surface p-4 sm:p-5 xl:sticky xl:top-6">
            <h2 className="mb-2 text-base font-bold">สถานะการกลั่นกรอง</h2>
            <dl>
              <Definition label="สถานะ">{user.is_active ? 'ใช้งาน' : 'ระงับ'}</Definition>
              <Definition label="เหตุผลล่าสุด">{user.ban_reason ?? '—'}</Definition>
              <Definition label="อัปเดตล่าสุด">{formatDateTime(user.updated_at)}</Definition>
            </dl>
          </section>
        </div>
      </div>

      <ConfirmDialog
        open={banDialog === 'ban'}
        onClose={() => setBanDialog(null)}
        onConfirm={submitBan}
        title="ระงับผู้ใช้"
        description={`ยืนยันระงับ ${user.email} — ต้องระบุเหตุผล`}
        confirmLabel="ระงับผู้ใช้"
        danger
        reasonRequired
        reasonLabel="เหตุผลการระงับ (บังคับ)"
        confirming={confirming}
      />
      <ConfirmDialog
        open={banDialog === 'unban'}
        onClose={() => setBanDialog(null)}
        onConfirm={submitBan}
        title="ยกเลิกระงับผู้ใช้"
        description={`ยืนยันยกเลิกระงับ ${user.email} — ต้องระบุเหตุผล`}
        confirmLabel="ยกเลิกระงับ"
        reasonRequired
        reasonLabel="เหตุผล (บังคับ)"
        confirming={confirming}
      />
    </>
  );
}
