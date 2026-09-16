import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Ban, CheckCircle2 } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import { Input, Select } from '../../components/ui/fields.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import Pagination from '../../components/ui/Pagination.jsx';
import ResponsiveCollection from '../../components/ui/ResponsiveCollection.jsx';
import { ApiError } from '../../lib/api-client.js';
import { formatDateTime, formatNumber } from '../../lib/formatters.js';
import { ROUTES } from '../../app/route-config.js';
import { useUsers } from './user-queries.js';

const PAGE_LIMIT = 20;

function ActiveBadge({ isActive }) {
  return isActive ? (
    <Badge tone="success" icon={<CheckCircle2 size={12} aria-hidden="true" />}>ใช้งาน</Badge>
  ) : (
    <Badge tone="danger" icon={<Ban size={12} aria-hidden="true" />}>ระงับ</Badge>
  );
}

export default function UsersPage() {
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();

  const page = Math.max(1, Number(params.get('page')) || 1);
  const search = params.get('search') ?? '';
  // Backend has no status filter param: this filters the loaded page client-side.
  const statusFilter = params.get('active') ?? '';
  const [draft, setDraft] = useState(search);

  useEffect(() => setDraft(search), [search]);

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

  const query = useUsers({ page, limit: PAGE_LIMIT, search });
  const items = query.data?.items ?? [];
  const visible = statusFilter === '' ? items : items.filter((u) => (statusFilter === 'active' ? u.is_active : !u.is_active));

  const openDetail = (user) => navigate(ROUTES.userDetail(user.id));

  let body;
  if (query.isPending) {
    body = <StatePanel state="loading" title="กำลังโหลดผู้ใช้" />;
  } else if (query.isError) {
    const err = query.error;
    body = (
      <StatePanel
        state={err?.status === 0 ? 'offline' : 'error'}
        title="โหลดผู้ใช้ไม่สำเร็จ"
        hint={err instanceof ApiError ? err.message : undefined}
        actionLabel="ลองอีกครั้ง"
        onAction={() => query.refetch()}
      />
    );
  } else if (items.length === 0) {
    body = <StatePanel state="empty" title={search ? 'ไม่พบผลจากตัวกรอง' : 'ยังไม่มีผู้ใช้'} />;
  } else {
    const columns = [
      {
        key: 'user',
        header: 'ผู้ใช้',
        render: (u) => (
          <span>
            <span className="block font-semibold">{u.full_name ?? '—'}</span>
            <span className="block text-xs text-ink-muted">{u.email}</span>
          </span>
        ),
      },
      { key: 'role', header: 'บทบาท', render: (u) => u.role },
      {
        key: 'stats',
        header: 'สแกน / รายงาน',
        render: (u) => <span className="tnum">{formatNumber(u.total_scans)} / {formatNumber(u.total_reports)}</span>,
      },
      { key: 'status', header: 'สถานะ', render: (u) => <ActiveBadge isActive={u.is_active} /> },
      { key: 'created', header: 'สมัครเมื่อ', render: (u) => <span className="whitespace-nowrap">{formatDateTime(u.created_at)}</span> },
      {
        key: 'actions',
        header: 'ดำเนินการ',
        render: (u) => (
          <Button variant="secondary" size="sm" onClick={() => openDetail(u)}>
            เปิดประวัติ
          </Button>
        ),
      },
    ];
    body = (
      <>
        <ResponsiveCollection
          columns={columns}
          rows={visible}
          rowKey={(u) => u.id}
          caption="รายการผู้ใช้"
          onRowClick={openDetail}
          empty={<StatePanel state="empty" title="ไม่พบผลจากตัวกรองสถานะในหน้านี้" />}
          renderCard={(u) => (
            <article aria-label={u.email} className="rounded-xl border border-line bg-surface p-3.5" role="listitem">
              <div className="flex items-center gap-2">
                <p className="min-w-0 flex-1 truncate text-sm font-bold">{u.full_name ?? u.email}</p>
                <ActiveBadge isActive={u.is_active} />
              </div>
              <p className="mt-0.5 truncate text-xs text-ink-muted">{u.email} · {u.role}</p>
              <p className="tnum mt-1 text-xs text-ink-muted">สแกน {formatNumber(u.total_scans)} · รายงาน {formatNumber(u.total_reports)}</p>
              <Button variant="secondary" size="sm" className="mt-2.5 w-full" onClick={() => openDetail(u)}>
                เปิดประวัติ
              </Button>
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
      <PageHeader eyebrow="ศูนย์ปฏิบัติการ" title="ผู้ใช้" description="ค้นหาประวัติและจัดการสถานะผู้ใช้" />
      <div className="mb-4 grid grid-cols-1 gap-3 rounded-xl border border-line bg-surface p-4 sm:grid-cols-[1fr_200px]">
        <Input
          id="user-search"
          label="ค้นหา"
          placeholder="ค้นหาด้วยชื่อหรืออีเมล…"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        />
        <Select
          id="user-status"
          label="สถานะ (กรองในหน้านี้)"
          value={statusFilter}
          onChange={(e) => update({ active: e.target.value })}
        >
          <option value="">ทั้งหมด</option>
          <option value="active">ใช้งาน</option>
          <option value="banned">ระงับ</option>
        </Select>
      </div>
      {body}
    </>
  );
}
