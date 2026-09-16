import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Download, Plus, XCircle } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import { Input, Select } from '../../components/ui/fields.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import Pagination from '../../components/ui/Pagination.jsx';
import ConfirmDialog from '../../components/ui/ConfirmDialog.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { isAbortError } from '../../lib/api-client.js';
import { formatDateTime, formatFileSize, formatNumber } from '../../lib/formatters.js';
import { REPORT_CATEGORIES } from '../../lib/media.js';
import { exportCreateSchema } from '../../schemas/admin.js';
import {
  downloadExportJob,
  isJobActive,
  useCancelExportJob,
  useCreateExportJob,
  useExportJob,
  useExportJobs,
} from './export-queries.js';

const PAGE_LIMIT = 20;

const STATUS_TONE = {
  queued: 'info',
  running: 'info',
  pending: 'info',
  processing: 'info',
  succeeded: 'success',
  completed: 'success',
  failed: 'danger',
  canceled: 'neutral',
  cancelled: 'neutral',
};

function JobCard({ job }) {
  const toast = useToast();
  const cancel = useCancelExportJob();
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [downloading, setDownloading] = useState(false);
  // Active jobs poll their own detail; completed jobs render the list snapshot.
  const live = useExportJob(job.id, isJobActive(job.status));
  const current = live.data ?? job;
  const active = isJobActive(current.status);
  const progress = Math.round(Number(current.progress ?? 0) * (Number(current.progress ?? 0) <= 1 ? 100 : 1));

  const doCancel = async () => {
    setCancelling(true);
    try {
      await cancel.mutateAsync({ id: current.id });
      toast.success('ยกเลิก export แล้ว');
      setCancelOpen(false);
    } catch (error) {
      if (isAbortError(error)) {
        setCancelOpen(false);
        return;
      }
      throw error;
    } finally {
      setCancelling(false);
    }
  };

  const doDownload = async () => {
    setDownloading(true);
    try {
      const filename = await downloadExportJob(current.id);
      toast.success(`ดาวน์โหลด ${filename} แล้ว`);
    } catch (error) {
      if (!isAbortError(error)) toast.error(error?.message ?? 'ดาวน์โหลดไม่สำเร็จ');
    } finally {
      setDownloading(false);
    }
  };

  return (
    <article aria-label={`Export ${current.id}`} className="rounded-xl border border-line bg-surface p-4">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono text-xs">{String(current.id).slice(0, 8)}…</span>
        <Badge tone={STATUS_TONE[String(current.status).toLowerCase()] ?? 'neutral'}>{current.status}</Badge>
        <span className="ml-auto text-xs text-ink-muted">สร้าง {formatDateTime(current.created_at)}</span>
      </div>
      {active ? (
        <div className="mt-3">
          <div className="flex items-center justify-between text-xs">
            <span>กำลังประมวลผล{current.total_rows ? ` · ${formatNumber(current.total_rows)} แถว` : ''}</span>
            <span className="tnum font-bold">{Number.isNaN(progress) ? '—' : `${progress}%`}</span>
          </div>
          <div className="mt-1 h-2 overflow-hidden rounded-full bg-surface-2" role="progressbar" aria-valuenow={Number.isNaN(progress) ? undefined : progress} aria-valuemin={0} aria-valuemax={100} aria-label="ความคืบหน้า export">
            <div className="h-full rounded-full bg-action" style={{ width: `${Number.isNaN(progress) ? 0 : progress}%` }} />
          </div>
          <div className="mt-2.5">
            <Button variant="secondary" size="sm" onClick={() => setCancelOpen(true)}>
              <XCircle size={14} aria-hidden="true" />
              ยกเลิก
            </Button>
          </div>
        </div>
      ) : (
        <dl className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-ink-muted">
          {current.total_rows !== null && current.total_rows !== undefined && (
            <div className="flex gap-1"><dt>แถว</dt><dd className="tnum">{formatNumber(current.total_rows)}</dd></div>
          )}
          {current.file_size_bytes !== null && current.file_size_bytes !== undefined && (
            <div className="flex gap-1"><dt>ขนาด</dt><dd>{formatFileSize(current.file_size_bytes)}</dd></div>
          )}
          {current.completed_at && (
            <div className="flex gap-1"><dt>เสร็จ</dt><dd>{formatDateTime(current.completed_at)}</dd></div>
          )}
          {current.expires_at && (
            <div className="flex gap-1"><dt>หมดอายุ</dt><dd>{formatDateTime(current.expires_at)}</dd></div>
          )}
        </dl>
      )}
      {['failed', 'error'].includes(String(current.status).toLowerCase()) && current.error_message && (
        <p role="alert" className="mt-2 rounded-lg border border-bad bg-surface px-2.5 py-2 text-[13px] text-bad">
          {current.error_message}
        </p>
      )}
      {!active && !['failed', 'error'].includes(String(current.status).toLowerCase()) && current.file_size_bytes && (
        <div className="mt-2.5">
          <Button variant="secondary" size="sm" loading={downloading} onClick={doDownload}>
            <Download size={14} aria-hidden="true" />
            ดาวน์โหลด
          </Button>
        </div>
      )}
      <ConfirmDialog
        open={cancelOpen}
        onClose={() => setCancelOpen(false)}
        onConfirm={doCancel}
        title="ยกเลิก export"
        description="ยืนยันยกเลิกงาน export นี้ งานที่ยกเลิกแล้วไม่สามารถทำต่อได้"
        confirmLabel="ยกเลิกงาน"
        danger
        confirming={cancelling}
      />
    </article>
  );
}

function ExportForm() {
  const toast = useToast();
  const create = useCreateExportJob();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset,
  } = useForm({
    resolver: zodResolver(exportCreateSchema),
    defaultValues: { include_metadata: true, format: 'zip' },
  });

  const submit = handleSubmit(async (values) => {
    const payload = {
      include_metadata: values.include_metadata,
      format: values.format || 'zip',
    };
    if (values.categories?.length > 0) payload.categories = values.categories;
    if (values.from_date) payload.from_date = values.from_date;
    if (values.to_date) payload.to_date = values.to_date;
    try {
      await create.mutateAsync(payload);
      toast.success('สร้างงาน export แล้ว');
      reset();
    } catch (error) {
      if (!isAbortError(error)) toast.error(error?.message ?? 'สร้างงาน export ไม่สำเร็จ');
    }
  });

  return (
    <section aria-label="สร้าง export" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="mb-3 text-base font-bold">สร้าง export ใหม่</h2>
      <form onSubmit={submit} className="flex flex-col gap-3">
        <fieldset>
          <legend className="mb-1.5 text-sm font-semibold">หมวดหมู่ (ไม่เลือก = ทั้งหมด)</legend>
          <div className="flex flex-wrap gap-2">
            {REPORT_CATEGORIES.filter((c) => c.value).map((c) => (
              <label key={c.value} className="inline-flex h-10 cursor-pointer items-center gap-2 rounded-lg border border-line-strong px-3 text-sm">
                <input type="checkbox" value={c.value} {...register('categories')} className="h-4 w-4 accent-[#0E7490]" />
                {c.label}
              </label>
            ))}
          </div>
        </fieldset>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Input id="export-from" label="จากวันที่" type="date" error={errors.from_date?.message} {...register('from_date')} />
          <Input id="export-to" label="ถึงวันที่" type="date" error={errors.to_date?.message} {...register('to_date')} />
        </div>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Select id="export-format" label="รูปแบบไฟล์" {...register('format')}>
            <option value="zip">ZIP</option>
            <option value="csv">CSV</option>
          </Select>
          <label htmlFor="export-meta" className="inline-flex h-10 cursor-pointer items-center gap-2 self-end rounded-lg border border-line-strong px-3 text-sm">
            <input id="export-meta" type="checkbox" {...register('include_metadata')} className="h-4 w-4 accent-[#0E7490]" />
            รวม metadata
          </label>
        </div>
        <div>
          <Button type="submit" loading={isSubmitting || create.isPending}>
            <Plus size={16} aria-hidden="true" />
            สร้างงาน export
          </Button>
        </div>
      </form>
    </section>
  );
}

export default function DatasetPage() {
  const [page, setPage] = useState(1);
  const query = useExportJobs({ page, limit: PAGE_LIMIT });

  let list;
  if (query.isPending) {
    list = <StatePanel state="loading" title="กำลังโหลดงาน export" />;
  } else if (query.isError) {
    list = (
      <StatePanel
        state={query.error?.status === 0 ? 'offline' : 'error'}
        title="โหลดงาน export ไม่สำเร็จ"
        hint={query.error?.message}
        actionLabel="ลองอีกครั้ง"
        onAction={() => query.refetch()}
      />
    );
  } else if (query.data.items.length === 0) {
    list = <StatePanel state="empty" title="ยังไม่มีงาน export" hint="สร้างงานแรกจากแบบฟอร์มด้านบน" />;
  } else {
    const sorted = [...query.data.items].sort((a, b) => Number(isJobActive(b.status)) - Number(isJobActive(a.status)));
    list = (
      <>
        <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
          {sorted.map((job) => (
            <JobCard key={job.id} job={job} />
          ))}
        </div>
        <div className="mt-4 flex justify-center">
          <Pagination page={query.data.page} total={query.data.total} limit={query.data.limit} onChange={setPage} />
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader eyebrow="การดำเนินงาน" title="ชุดข้อมูล" description="สร้างและดาวน์โหลด dataset export" />
      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 xl:col-span-5"><ExportForm /></div>
        <div className="col-span-12 flex flex-col gap-3 xl:col-span-7">{list}</div>
      </div>
    </>
  );
}
