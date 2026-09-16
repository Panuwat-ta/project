import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import { Input, Select } from '../../components/ui/fields.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import Pagination from '../../components/ui/Pagination.jsx';
import ResponsiveCollection from '../../components/ui/ResponsiveCollection.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { ApiError, isAbortError } from '../../lib/api-client.js';
import { formatWaitingTime } from '../../lib/formatters.js';
import { REPORT_CATEGORIES, REPORT_STATUSES, categoryLabel } from '../../lib/media.js';
import { ROUTES } from '../../app/route-config.js';
import { useReports, useStartReview } from './report-queries.js';
import { RiskScore, StatusBadge } from './badges.jsx';

const PAGE_LIMIT = 20;

export default function ReportsPage() {
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();
  const toast = useToast();
  const startReview = useStartReview();

  const page = Math.max(1, Number(params.get('page')) || 1);
  const status = params.get('status') ?? '';
  const category = params.get('category') ?? '';
  const search = params.get('search') ?? '';
  const [draft, setDraft] = useState(search);

  useEffect(() => setDraft(search), [search]);

  // Debounced search synced to URL; stale requests abort via query signal.
  useEffect(() => {
    if (draft === search) return undefined;
    const timer = setTimeout(() => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        if (draft) next.set('search', draft);
        else next.delete('search');
        next.set('page', '1');
        return next;
      });
    }, 350);
    return () => clearTimeout(timer);
  }, [draft, search, setParams]);

  const update = (patch) => {
    setParams((prev) => {
      const next = new URLSearchParams(prev);
      for (const [key, value] of Object.entries(patch)) {
        if (value) next.set(key, value);
        else next.delete(key);
      }
      if (!('page' in patch)) next.set('page', '1');
      return next;
    });
  };

  const query = useReports({ page, limit: PAGE_LIMIT, status, category, search });
  const hasFilter = Boolean(status || category || search);

  const claimCase = async (report) => {
    try {
      await startReview.mutateAsync({ id: report.id, version: report.version });
      toast.success(`รับเคส #R-${report.id} แล้ว`);
    } catch (error) {
      if (isAbortError(error)) return;
      toast.error(error?.message ?? 'รับเคสไม่สำเร็จ');
    }
  };

  const openDetail = (report) => navigate(ROUTES.reportDetail(report.id));

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
          <span className="block">{categoryLabel(r.category)}</span>
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
          {(r.status === 'pending' || r.status === 'reviewing') && (
            <Button
              variant="primary"
              size="sm"
              loading={startReview.isPending && startReview.variables?.id === r.id}
              onClick={() => claimCase(r)}
            >
              รับเคส
            </Button>
          )}
        </span>
      ),
    },
  ];

  let body;
  if (query.isPending) {
    body = <StatePanel state="loading" title="กำลังโหลดรายงาน" />;
  } else if (query.isError) {
    const err = query.error;
    if (err instanceof ApiError && err.status === 404) {
      body = <StatePanel state="empty" title="ไม่พบรายงาน" />;
    } else {
      body = (
        <StatePanel
          state={err?.status === 0 ? 'offline' : 'error'}
          title="โหลดรายงานไม่สำเร็จ"
          hint={err?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => query.refetch()}
        />
      );
    }
  } else if (query.data.items.length === 0) {
    body = (
      <StatePanel
        state="empty"
        title={hasFilter ? 'ไม่พบผลจากตัวกรอง' : 'ยังไม่มีรายงาน'}
        hint={hasFilter ? 'ลองปรับคำค้นหาหรือตัวกรอง' : undefined}
      />
    );
  } else {
    body = (
      <>
        <ResponsiveCollection
          columns={columns}
          rows={query.data.items}
          rowKey={(r) => r.id}
          caption="รายการรายงาน"
          onRowClick={openDetail}
          renderCard={(r) => (
            <article aria-label={`รายงาน #R-${r.id}`} className="rounded-xl border border-line bg-surface p-3.5" role="listitem">
              <div className="flex items-center gap-2.5">
                <RiskScore score={r.scan?.total_risk_score} />
                <p className="text-sm font-bold">{categoryLabel(r.category)}</p>
                <span className="ml-auto"><StatusBadge status={r.status} /></span>
              </div>
              <p className="mt-1.5 line-clamp-2 text-[13px] text-ink-2">{r.description}</p>
              <p className="mt-1 font-mono text-xs text-ink-muted">#R-{r.id} · {r.user?.email ?? '—'}</p>
              <div className="mt-2.5 flex gap-2">
                <Button variant="secondary" size="sm" className="flex-1" onClick={() => openDetail(r)}>
                  เปิดรายละเอียด
                </Button>
                {(r.status === 'pending' || r.status === 'reviewing') && (
                  <Button variant="primary" size="sm" className="flex-[2]" loading={startReview.isPending && startReview.variables?.id === r.id} onClick={() => claimCase(r)}>
                    รับเคส
                  </Button>
                )}
              </div>
            </article>
          )}
        />
        <div className="mt-4 flex justify-center">
          <Pagination page={query.data.page} total={query.data.total} limit={query.data.limit} onChange={(p) => update({ page: String(p) })} />
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader eyebrow="ศูนย์ปฏิบัติการ" title="รายงานทั้งหมด" description="ค้นหา กรอง และรับเคสจากรายงานทั้งหมด" />
      <div className="mb-4 grid grid-cols-1 gap-3 rounded-xl border border-line bg-surface p-4 sm:grid-cols-[1fr_180px_200px]">
        <Input
          id="report-search"
          label="ค้นหา"
          placeholder="ค้นหาด้วยคำอธิบาย อีเมล…"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        />
        <Select id="report-status" label="สถานะ" value={status} onChange={(e) => update({ status: e.target.value })}>
          {REPORT_STATUSES.map((s) => (
            <option key={s.value} value={s.value}>{s.label}</option>
          ))}
        </Select>
        <Select id="report-category" label="หมวดหมู่" value={category} onChange={(e) => update({ category: e.target.value })}>
          {REPORT_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>{c.label}</option>
          ))}
        </Select>
      </div>
      {body}
      {query.isFetching && !query.isPending && (
        <p className="mt-2 text-xs text-ink-muted" role="status">กำลังอัปเดต…</p>
      )}
    </>
  );
}
