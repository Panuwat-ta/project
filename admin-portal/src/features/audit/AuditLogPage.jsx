import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Copy } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import { Input } from '../../components/ui/fields.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import Pagination from '../../components/ui/Pagination.jsx';
import Drawer from '../../components/ui/Drawer.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { ApiError } from '../../lib/api-client.js';
import { formatDateTime } from '../../lib/formatters.js';
import { useAuditLogs } from './audit-queries.js';

const PAGE_LIMIT = 50;

function CopyButton({ value, label }) {
  const toast = useToast();
  if (!value) return <span className="text-ink-muted">—</span>;
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(String(value));
      toast.success('คัดลอกแล้ว');
    } catch {
      toast.error('คัดลอกไม่สำเร็จ');
    }
  };
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="font-mono text-xs">{value}</span>
      <button
        type="button"
        onClick={copy}
        aria-label={`${label} คัดลอก`}
        title={`${label} คัดลอก`}
        className="inline-flex h-7 w-7 items-center justify-center rounded-md text-ink-muted hover:bg-surface-2 hover:text-ink"
      >
        <Copy size={13} aria-hidden="true" />
      </button>
    </span>
  );
}

function StateJson({ title, data }) {
  if (data === null || data === undefined) return null;
  return (
    <div className="mt-2">
      <p className="pb-1 text-sm font-semibold">{title}</p>
      <pre className="max-h-64 overflow-auto whitespace-pre-wrap break-all rounded-lg border border-line bg-elevated p-2.5 font-mono text-xs">
        {JSON.stringify(data, null, 2)}
      </pre>
    </div>
  );
}

export default function AuditLogPage() {
  const [params, setParams] = useSearchParams();
  const [selected, setSelected] = useState(null);

  const page = Math.max(1, Number(params.get('page')) || 1);
  const search = params.get('search') ?? '';
  const action = params.get('action') ?? '';
  const entityType = params.get('entity_type') ?? '';
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

  const query = useAuditLogs({ page, limit: PAGE_LIMIT, search, action, entity_type: entityType });

  let body;
  if (query.isPending) {
    body = <StatePanel state="loading" title="กำลังโหลดบันทึกตรวจสอบ" />;
  } else if (query.isError) {
    const err = query.error;
    body = (
      <StatePanel
        state={err?.status === 0 ? 'offline' : 'error'}
        title="โหลดบันทึกไม่สำเร็จ"
        hint={err instanceof ApiError ? err.message : undefined}
        actionLabel="ลองอีกครั้ง"
        onAction={() => query.refetch()}
      />
    );
  } else if (query.data.items.length === 0) {
    body = <StatePanel state="empty" title={search || action || entityType ? 'ไม่พบผลจากตัวกรอง' : 'ยังไม่มีบันทึก'} />;
  } else {
    body = (
      <>
        <div className="overflow-x-auto rounded-xl border border-line bg-surface">
          <table className="w-full min-w-[720px] border-collapse text-[13px]">
            <caption className="sr-only">บันทึกตรวจสอบ</caption>
            <thead>
              <tr>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">เวลา</th>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">ผู้ทำ</th>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">Action</th>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">Entity</th>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">เหตุผล</th>
                <th scope="col" className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted">Request ID</th>
              </tr>
            </thead>
            <tbody>
              {query.data.items.map((log) => (
                <tr key={log.id} className="hover:bg-surface-2">
                  <td className="whitespace-nowrap border-b border-line/60 px-3 py-2.5">{formatDateTime(log.created_at)}</td>
                  <td className="border-b border-line/60 px-3 py-2.5 font-mono text-xs">{log.admin_id ?? '—'}</td>
                  <td className="border-b border-line/60 px-3 py-2.5">
                    <button type="button" onClick={() => setSelected(log)} className="font-semibold text-action hover:underline">
                      {log.action}
                    </button>
                  </td>
                  <td className="border-b border-line/60 px-3 py-2.5">
                    {[log.entity_type, log.entity_id].filter(Boolean).join(' #') || '—'}
                  </td>
                  <td className="max-w-48 truncate border-b border-line/60 px-3 py-2.5">{log.reason ?? '—'}</td>
                  <td className="border-b border-line/60 px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                    <CopyButton value={log.request_id} label="Request ID" />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="mt-4 flex justify-center">
          <Pagination page={query.data.page} total={query.data.total} limit={query.data.limit} onChange={(p) => update({ page: String(p) })} />
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader eyebrow="กำกับดูแล" title="บันทึกตรวจสอบ" description="Audit log แบบอ่านอย่างเดียว" />
      <div className="mb-4 grid grid-cols-1 gap-3 rounded-xl border border-line bg-surface p-4 sm:grid-cols-[1fr_200px_200px]">
        <Input
          id="audit-search"
          label="ค้นหา"
          placeholder="ค้นหา action, entity, เหตุผล…"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        />
        <Input
          id="audit-action"
          label="Action"
          placeholder="เช่น approve_report"
          value={action}
          onChange={(e) => update({ action: e.target.value })}
        />
        <Input
          id="audit-entity"
          label="ประเภท entity"
          placeholder="เช่น report"
          value={entityType}
          onChange={(e) => update({ entity_type: e.target.value })}
        />
      </div>
      {body}
      <Drawer open={selected !== null} onClose={() => setSelected(null)} title={selected ? `รายละเอียด #${selected.id}` : 'รายละเอียด'}>
        {selected && (
          <dl className="flex flex-col gap-1 text-sm">
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">เวลา</dt><dd>{formatDateTime(selected.created_at)}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">ผู้ทำ</dt><dd className="font-mono text-xs">{selected.admin_id ?? '—'}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">Action</dt><dd className="font-semibold">{selected.action}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">Entity</dt><dd>{[selected.entity_type, selected.entity_id].filter(Boolean).join(' #') || '—'}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">เหตุผล</dt><dd className="break-words">{selected.reason ?? '—'}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">IP</dt><dd className="font-mono text-xs">{selected.ip_address ?? '—'}</dd></div>
            <div className="flex gap-2 py-1"><dt className="w-28 shrink-0 text-ink-2">Request ID</dt><dd><CopyButton value={selected.request_id} label="Request ID" /></dd></div>
            {selected.details && (
              <div className="py-1"><dt className="pb-1 text-ink-2">รายละเอียด</dt><dd className="whitespace-pre-wrap break-words rounded-lg border border-line bg-elevated p-2.5 text-[13px]">{selected.details}</dd></div>
            )}
            <dd><StateJson title="Before" data={selected.before_state} /></dd>
            <dd><StateJson title="After" data={selected.after_state} /></dd>
            <div className="pt-2">
              <Button variant="secondary" size="sm" onClick={() => setSelected(null)}>
                ปิด
              </Button>
            </div>
          </dl>
        )}
      </Drawer>
    </>
  );
}
