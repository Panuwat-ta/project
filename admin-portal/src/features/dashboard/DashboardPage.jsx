import { useNavigate } from 'react-router-dom';
import { Activity, ArrowUpRight, Clock3, Inbox, RefreshCw, TriangleAlert } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import MetricCard from '../../components/ui/MetricCard.jsx';
import Button from '../../components/ui/Button.jsx';
import IconButton from '../../components/ui/IconButton.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import Badge from '../../components/ui/Badge.jsx';
import ResponsiveCollection from '../../components/ui/ResponsiveCollection.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { ApiError, isAbortError } from '../../lib/api-client.js';
import { formatDateTime, formatMetric, formatNumber, formatWaitingTime, normalizeRiskDistribution } from '../../lib/formatters.js';
import { ROUTES } from '../../app/route-config.js';
import { useStartReview } from '../reports/report-queries.js';
import { RiskScore, StatusBadge } from '../reports/badges.jsx';
import { sortQueue, useDashboardHealth, useDashboardSummary, usePendingQueue } from './dashboard-queries.js';
import ActivityMatrix from './ActivityMatrix.jsx';

function KpiStrip({ summary }) {
  if (!summary) return null;
  const dist = normalizeRiskDistribution(summary.risk_distribution);
  return (
    <div className="mb-6 grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
      <MetricCard label="รอตรวจสอบ" value={summary.reports.pending} tone="warning"
        icon={<Inbox size={18} aria-hidden="true" />} supportingText="เคสในคิวด้านล่าง" />
      <MetricCard label="กำลังตรวจสอบ" value={summary.reports.reviewing} tone="info"
        icon={<Clock3 size={18} aria-hidden="true" />} supportingText="อยู่ระหว่างดำเนินการ" />
      <MetricCard label="สแกนวันนี้" value={summary.overview.scans_today} tone="neutral"
        icon={<Activity size={18} aria-hidden="true" />} supportingText={`สัปดาห์นี้ ${formatNumber(summary.overview.scans_this_week)} ครั้ง`} />
      <MetricCard label="ความเสี่ยงสูง" value={dist.high} tone="danger"
        icon={<TriangleAlert size={18} aria-hidden="true" />} supportingText="จาก risk distribution" />
    </div>
  );
}

function RiskDistribution({ distribution }) {
  const dist = normalizeRiskDistribution(distribution);
  const total = Math.max(1, dist.high + dist.medium + dist.low + dist.unknown);
  const rows = [
    { label: 'สูง', count: dist.high, bar: 'bg-bad' },
    { label: 'กลาง', count: dist.medium, bar: 'bg-warn' },
    { label: 'ต่ำ', count: dist.low, bar: 'bg-ok' },
  ];
  return (
    <section aria-label="การกระจายความเสี่ยง" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="text-base font-bold">การกระจายความเสี่ยง</h2>
      <div className="mt-3 flex flex-col gap-2.5">
        {rows.map((row) => (
          <div key={row.label} className="flex items-center gap-2.5 text-[13px]">
            <span className="w-8 shrink-0 text-ink-2">{row.label}</span>
            <span className="h-2 flex-1 overflow-hidden rounded-full bg-surface-2" role="img" aria-label={`${row.label} ${row.count} เคส`}>
              <span className={`block h-full rounded-full ${row.bar}`} style={{ width: `${Math.round((row.count / total) * 100)}%` }} />
            </span>
            <span className="tnum w-8 shrink-0 text-right font-bold">{formatNumber(row.count)}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function HealthCard({ query }) {
  if (query.isPending) return <StatePanel state="loading" title="กำลังโหลดสุขภาพระบบ" />;
  if (query.isError) {
    return (
      <section aria-label="สุขภาพระบบ" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
        <h2 className="text-base font-bold">สุขภาพระบบ</h2>
        <StatePanel state="error" title="โหลดสุขภาพระบบไม่สำเร็จ" actionLabel="ลองอีกครั้ง" onAction={() => query.refetch()} className="mt-3 border-0 p-4" />
      </section>
    );
  }
  const health = query.data;
  const rows = [
    ['ฐานข้อมูล', health.database],
    ['พื้นที่จัดเก็บ', health.storage],
    ['โมเดล', health.models],
    ['คิวงาน', health.queue],
  ];
  return (
    <section aria-label="สุขภาพระบบ" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="text-base font-bold">สุขภาพระบบ</h2>
      <ul className="mt-2">
        {rows.map(([label, value]) => (
          <li key={label} className="flex items-center gap-2 py-1.5 text-[13px]">
            <span className="text-ink-2">{label}</span>
            <span className="ml-auto">
              <Badge tone={String(value).toLowerCase() === 'ok' || value === 'ปกติ' ? 'success' : 'warning'}>
                {value}
              </Badge>
            </span>
          </li>
        ))}
      </ul>
      <p className="mt-2 text-xs text-ink-muted">ตรวจล่าสุด {formatDateTime(health.last_check)}</p>
    </section>
  );
}

function ModelCard({ model }) {
  if (!model) return null;
  const metrics = [
    ['mIoU', formatMetric(model.m_iou)],
    ['aAcc', formatMetric(model.a_acc)],
    ['mAcc', formatMetric(model.m_acc)],
    ['mDice', formatMetric(model.m_dice)],
  ];
  return (
    <section aria-label="โมเดลที่ใช้งาน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="text-base font-bold">โมเดลที่ใช้งาน</h2>
      <p className="mt-2 font-mono text-xl font-bold">{model.active_version ?? '—'}</p>
      <p className="text-xs text-ink-muted">
        {model.deployed_at ? `deploy เมื่อ ${formatDateTime(model.deployed_at)}` : 'ยังไม่มีข้อมูลการ deploy'}
      </p>
      <div className="mt-3 grid grid-cols-2 gap-2">
        {metrics.map(([key, value]) => (
          <div key={key} className="rounded-lg border border-line/60 bg-elevated px-2.5 py-2">
            <p className="text-[11px] text-ink-muted">{key}</p>
            {value === null ? (
              <p className="text-[15px] font-bold" aria-label={`${key} ไม่มีข้อมูล`}>—</p>
            ) : (
              <p className="tnum text-[15px] font-bold">{value}</p>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}

function QueueCard({ queueQuery }) {
  const navigate = useNavigate();
  const toast = useToast();
  const startReview = useStartReview();

  const claimCase = async (report) => {
    try {
      await startReview.mutateAsync({ id: report.id, version: report.version });
      toast.success(`รับเคส #R-${report.id} แล้ว`);
    } catch (error) {
      if (isAbortError(error)) return;
      if (error instanceof ApiError && error.status === 409) {
        toast.error('เคสนี้ถูกดำเนินการโดยผู้ดูแลคนอื่นแล้ว กำลังโหลดข้อมูลใหม่');
        queueQuery.refetch();
        return;
      }
      toast.error(error?.message ?? 'รับเคสไม่สำเร็จ');
    }
  };

  const openDetail = (report) => navigate(ROUTES.reportDetail(report.id));

  let body;
  if (queueQuery.isPending) {
    body = <StatePanel state="loading" title="กำลังโหลดคิว" className="border-0" />;
  } else if (queueQuery.isError) {
    body = (
      <StatePanel
        state="error"
        title="โหลดคิวไม่สำเร็จ"
        hint={queueQuery.error?.message}
        actionLabel="ลองอีกครั้ง"
        onAction={() => queueQuery.refetch()}
        className="border-0"
      />
    );
  } else {
    const sorted = sortQueue(queueQuery.data.items).slice(0, 5);
    const columns = [
      {
        key: 'risk',
        header: 'ความเสี่ยง',
        render: (r) => <RiskScore score={r.scan?.total_risk_score} />,
      },
      {
        key: 'report',
        header: 'รายงาน / ผู้ส่ง',
        render: (r) => (
          <span>
            <span className="block font-mono text-xs">#R-{r.id}</span>
            <span className="block text-xs text-ink-muted">{r.user?.full_name ?? r.user?.email ?? '—'}</span>
          </span>
        ),
      },
      {
        key: 'category',
        header: 'หมวดหมู่ / แพลตฟอร์ม',
        render: (r) => (
          <span>
            <span className="block">{r.category}</span>
            <span className="block text-xs text-ink-muted">{r.platform ?? '—'}</span>
          </span>
        ),
      },
      {
        key: 'waiting',
        header: 'เวลาที่รอ',
        render: (r) => <span className="whitespace-nowrap">{formatWaitingTime(r.created_at)}</span>,
      },
      { key: 'status', header: 'สถานะ', render: (r) => <StatusBadge status={r.status} /> },
      {
        key: 'actions',
        header: 'ดำเนินการ',
        render: (r) => (
          <span className="flex gap-2" onClick={(e) => e.stopPropagation()}>
            <Button variant="secondary" size="sm" onClick={() => openDetail(r)}>
              เปิดรายละเอียด
            </Button>
            <Button
              variant="primary"
              size="sm"
              loading={startReview.isPending && startReview.variables?.id === r.id}
              onClick={() => claimCase(r)}
            >
              รับเคส
            </Button>
          </span>
        ),
      },
    ];
    body = (
      <ResponsiveCollection
        columns={columns}
        rows={sorted}
        rowKey={(r) => r.id}
        caption="คิวรายงานรอตรวจสอบ 5 เคสแรก"
        onRowClick={openDetail}
        empty={<StatePanel state="empty" title="ยังไม่มีรายงานรอตรวจ" className="border-0" />}
        renderCard={(r) => (
          <article aria-label={`รายงาน #R-${r.id}`} className="rounded-xl border border-line bg-surface p-3.5" role="listitem">
            <div className="flex items-center gap-2.5">
              <RiskScore score={r.scan?.total_risk_score} />
              <p className="text-sm font-bold">{r.category}</p>
              <span className="ml-auto"><StatusBadge status={r.status} /></span>
            </div>
            <p className="mt-1.5 line-clamp-2 text-[13px] text-ink-2">{r.description}</p>
            <dl className="mt-2 flex flex-wrap gap-x-3 gap-y-0.5 text-xs text-ink-muted">
              <div className="flex gap-1"><dt>รอ</dt><dd>{formatWaitingTime(r.created_at)}</dd></div>
              <div className="flex gap-1"><dt className="sr-only">รายงาน</dt><dd className="font-mono">#R-{r.id} · {r.user?.full_name ?? r.user?.email ?? '—'}</dd></div>
            </dl>
            <div className="mt-2.5 flex gap-2">
              <Button variant="secondary" size="sm" className="flex-1" onClick={() => openDetail(r)}>
                เปิดรายละเอียด
              </Button>
              <Button variant="primary" size="sm" className="flex-[2]" loading={startReview.isPending && startReview.variables?.id === r.id} onClick={() => claimCase(r)}>
                รับเคส
              </Button>
            </div>
          </article>
        )}
      />
    );
  }

  return (
    <section aria-label="คิวรอดำเนินการ" className="min-w-0 rounded-xl border border-line bg-surface p-4 sm:p-5">
      <div className="mb-2 flex items-center gap-2.5">
        <h2 className="text-base font-bold">คิวรอดำเนินการ</h2>
        <button
          type="button"
          onClick={() => navigate(ROUTES.reports)}
          className="ml-auto inline-flex items-center gap-1 text-[13px] font-semibold text-action hover:underline"
        >
          ดูทั้งหมด
          <ArrowUpRight size={14} aria-hidden="true" />
        </button>
      </div>
      {body}
      {queueQuery.isFetching && !queueQuery.isPending && (
        <p className="mt-2 text-xs text-ink-muted" role="status">กำลังอัปเดต…</p>
      )}
    </section>
  );
}

export default function DashboardPage() {
  const navigate = useNavigate();
  const summaryQuery = useDashboardSummary();
  const healthQuery = useDashboardHealth();
  const queueQuery = usePendingQueue();

  const updatedAt = summaryQuery.dataUpdatedAt ? formatDateTime(new Date(summaryQuery.dataUpdatedAt).toISOString()) : null;

  const refreshing = summaryQuery.isFetching || queueQuery.isFetching;

  return (
    <>
      <PageHeader
        eyebrow="ศูนย์ปฏิบัติการ"
        title="คิวตรวจสอบความเสี่ยง"
        description="ดูสัญญาณภาพรวม แล้วลงมือกับเคสที่รอตรวจ"
        metadata={updatedAt ? [<span key="u">อัปเดตล่าสุด {updatedAt}</span>] : undefined}
        actions={
          <>
            <IconButton
              label="รีเฟรชข้อมูล"
              onClick={() => {
                summaryQuery.refetch();
                healthQuery.refetch();
                queueQuery.refetch();
              }}
            >
              <RefreshCw size={18} aria-hidden="true" className={refreshing ? 'animate-spin' : ''} />
            </IconButton>
            <Button variant="secondary" onClick={() => navigate(ROUTES.reports)}>
              ดูรายงานทั้งหมด
              <ArrowUpRight size={16} aria-hidden="true" />
            </Button>
          </>
        }
      />

      {summaryQuery.isPending ? (
        <StatePanel state="loading" title="กำลังโหลดภาพรวม" className="mb-6" />
      ) : summaryQuery.isError ? (
        <StatePanel
          state="error"
          title="โหลดภาพรวมไม่สำเร็จ"
          hint={summaryQuery.error?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => summaryQuery.refetch()}
          className="mb-6"
        />
      ) : (
        <>
          <KpiStrip summary={summaryQuery.data} />
          <div className="mb-6">
            <ActivityMatrix trend={summaryQuery.data.scan_trend} />
          </div>
        </>
      )}

      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 xl:col-span-8">
          <QueueCard queueQuery={queueQuery} />
        </div>
        <div className="col-span-12 flex flex-col gap-6 xl:col-span-4">
          {summaryQuery.data ? (
            <RiskDistribution distribution={summaryQuery.data.risk_distribution} />
          ) : (
            <StatePanel state={summaryQuery.isError ? 'error' : 'loading'} title="การกระจายความเสี่ยง" actionLabel={summaryQuery.isError ? 'ลองอีกครั้ง' : undefined} onAction={summaryQuery.isError ? () => summaryQuery.refetch() : undefined} />
          )}
          <HealthCard query={healthQuery} />
          {summaryQuery.data && <ModelCard model={summaryQuery.data.model} />}
        </div>
      </div>

      <div aria-live="polite" className="sr-only">
        {startReviewLiveText(summaryQuery, queueQuery)}
      </div>
    </>
  );
}

function startReviewLiveText(summaryQuery, queueQuery) {
  if (summaryQuery.isError) return 'โหลดภาพรวมไม่สำเร็จ';
  if (queueQuery.isError) return 'โหลดคิวไม่สำเร็จ';
  return '';
}
