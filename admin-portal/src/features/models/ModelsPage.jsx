import { useState } from 'react';
import { CheckCircle2, FlaskConical, Rocket, TriangleAlert } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import ConfirmDialog from '../../components/ui/ConfirmDialog.jsx';
import ResponsiveCollection from '../../components/ui/ResponsiveCollection.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { isAbortError } from '../../lib/api-client.js';
import { formatDateTime, formatMetric } from '../../lib/formatters.js';
import { useDeployModel, useDryRunModel, useModels } from './model-queries.js';

function MetricValue({ label, value }) {
  if (value === null || value === undefined) {
    return (
      <span aria-label={`${label} ไม่มีข้อมูล`} className="tnum text-sm font-bold">
        —
      </span>
    );
  }
  return <span className="tnum text-sm font-bold">{formatMetric(value)}</span>;
}

function DryRunResult({ result }) {
  if (!result) return null;
  return (
    <div role="status" className="mt-2 rounded-lg border border-line bg-elevated p-2.5 text-[13px]">
      <p className="flex items-center gap-1.5 font-semibold">
        {result.success ? (
          <CheckCircle2 size={15} aria-hidden="true" className="text-ok" />
        ) : (
          <TriangleAlert size={15} aria-hidden="true" className="text-bad" />
        )}
        {result.success ? 'Dry-run สำเร็จ' : 'Dry-run ไม่สำเร็จ'}: {result.message}
      </p>
      {result.details && (
        <pre className="mt-1.5 max-h-40 overflow-auto whitespace-pre-wrap break-all font-mono text-xs">
          {JSON.stringify(result.details, null, 2)}
        </pre>
      )}
    </div>
  );
}

function ModelActions({ model }) {
  const toast = useToast();
  const deploy = useDeployModel();
  const dryRun = useDryRunModel();
  const [deployOpen, setDeployOpen] = useState(false);
  const [deploying, setDeploying] = useState(false);

  const runDryRun = async () => {
    try {
      await dryRun.mutateAsync({ id: model.id });
    } catch (error) {
      if (isAbortError(error)) return;
      toast.error(error?.message ?? 'Dry-run ไม่สำเร็จ');
    }
  };

  const confirmDeploy = async (reason) => {
    setDeploying(true);
    try {
      await deploy.mutateAsync({ id: model.id, reason });
      toast.success(`Deploy ${model.version_tag} สำเร็จ`);
      setDeployOpen(false);
    } catch (error) {
      if (isAbortError(error)) {
        setDeployOpen(false);
        return;
      }
      throw error;
    } finally {
      setDeploying(false);
    }
  };

  return (
    <span className="flex flex-col gap-2" onClick={(e) => e.stopPropagation()}>
      <span className="flex gap-2">
        <Button
          variant="secondary"
          size="sm"
          loading={dryRun.isPending}
          onClick={runDryRun}
          title={model.is_active ? 'ทดสอบเวอร์ชันที่ใช้งานอยู่' : `ทดสอบ ${model.version_tag} ก่อน deploy`}
        >
          <FlaskConical size={14} aria-hidden="true" />
          Dry-run
        </Button>
        <Button
          variant={model.is_active ? 'secondary' : 'primary'}
          size="sm"
          onClick={() => setDeployOpen(true)}
          title={model.is_active ? `${model.version_tag} ใช้งานอยู่แล้ว — กดเพื่อ deploy ซ้ำพร้อมเหตุผล` : `Deploy ${model.version_tag} พร้อมระบุเหตุผล`}
        >
          <Rocket size={14} aria-hidden="true" />
          {model.is_active ? 'Deploy ซ้ำ' : 'Deploy'}
        </Button>
      </span>
      <DryRunResult result={dryRun.data} />
      <ConfirmDialog
        open={deployOpen}
        onClose={() => setDeployOpen(false)}
        onConfirm={confirmDeploy}
        title={`Deploy ${model.version_tag}`}
        description="ยืนยัน deploy โมเดลเวอร์ชันนี้ — ต้องระบุเหตุผล การ deploy จะประกาศให้ dashboard รีเฟรช"
        confirmLabel="Deploy"
        reasonRequired
        reasonLabel="เหตุผลการ deploy (บังคับ)"
        confirming={deploying}
      />
    </span>
  );
}

export default function ModelsPage() {
  const query = useModels();

  if (query.isPending) return <StatePanel state="loading" title="กำลังโหลดเวอร์ชันโมเดล" />;
  if (query.isError) {
    return (
      <>
        <PageHeader eyebrow="การดำเนินงาน" title="เวอร์ชันโมเดล" />
        <StatePanel
          state={query.error?.status === 0 ? 'offline' : 'error'}
          title="โหลดข้อมูลโมเดลไม่สำเร็จ"
          hint={query.error?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => query.refetch()}
        />
      </>
    );
  }

  const items = query.data.items;
  const active = items.find((m) => m.is_active) ?? null;
  const rest = items.filter((m) => m !== active);

  const columns = [
    {
      key: 'version',
      header: 'เวอร์ชัน',
      render: (m) => (
        <span className="flex items-center gap-2">
          <span className="font-mono text-sm font-bold">{m.version_tag}</span>
          {m.is_active && <Badge tone="success">ใช้งานอยู่</Badge>}
        </span>
      ),
    },
    { key: 'status', header: 'สถานะ', render: (m) => m.status },
    { key: 'miou', header: 'mIoU', render: (m) => <MetricValue label="mIoU" value={m.m_iou} /> },
    { key: 'aacc', header: 'aAcc', render: (m) => <MetricValue label="aAcc" value={m.a_acc} /> },
    { key: 'mdice', header: 'mDice', render: (m) => <MetricValue label="mDice" value={m.m_dice} /> },
    { key: 'deployed', header: 'Deploy ล่าสุด', render: (m) => <span className="whitespace-nowrap">{m.deployed_at ? formatDateTime(m.deployed_at) : '—'}</span> },
    { key: 'actions', header: 'ดำเนินการ', render: (m) => <ModelActions model={m} /> },
  ];

  return (
    <>
      <PageHeader eyebrow="การดำเนินงาน" title="เวอร์ชันโมเดล" description="Deploy และทดสอบโมเดลตรวจจับ" />

      {active && (
        <section aria-label="โมเดลที่ใช้งาน" className="mb-6 rounded-xl border-2 border-action bg-surface p-4 sm:p-5">
          <div className="flex flex-wrap items-center gap-2.5">
            <h2 className="text-base font-bold">ใช้งานอยู่: <span className="font-mono">{active.version_tag}</span></h2>
            <Badge tone="success" icon={<CheckCircle2 size={12} aria-hidden="true" />}>Active</Badge>
            <span className="ml-auto text-xs text-ink-muted">
              {active.deployed_at ? `deploy เมื่อ ${formatDateTime(active.deployed_at)}` : ''}
            </span>
          </div>
          <div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
            {[['mIoU', active.m_iou], ['aAcc', active.a_acc], ['mAcc', active.m_acc], ['mDice', active.m_dice]].map(([label, value]) => (
              <div key={label} className="rounded-lg border border-line/60 bg-elevated px-3 py-2.5">
                <p className="text-xs text-ink-muted">{label}</p>
                <p className="mt-0.5"><MetricValue label={label} value={value} /></p>
              </div>
            ))}
          </div>
          <div className="mt-3"><ModelActions model={active} /></div>
        </section>
      )}

      <section aria-label="เวอร์ชันทั้งหมด" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
        <h2 className="mb-2 text-base font-bold">เวอร์ชันทั้งหมด ({query.data.total})</h2>
        {rest.length === 0 && !active ? (
          <StatePanel state="empty" title="ยังไม่มีเวอร์ชันโมเดล" className="border-0" />
        ) : (
          <ResponsiveCollection
            columns={columns}
            rows={rest}
            rowKey={(m) => m.id}
            caption="รายการเวอร์ชันโมเดล"
            empty={<StatePanel state="empty" title="ไม่มีเวอร์ชันอื่น" className="border-0" />}
            renderCard={(m) => (
              <article aria-label={m.version_tag} className="rounded-xl border border-line bg-surface p-3.5" role="listitem">
                <div className="flex items-center gap-2">
                  <p className="font-mono text-sm font-bold">{m.version_tag}</p>
                  {m.is_active && <Badge tone="success">ใช้งานอยู่</Badge>}
                  <span className="ml-auto text-xs text-ink-muted">{m.status}</span>
                </div>
                <dl className="mt-2 grid grid-cols-3 gap-2 text-center">
                  {[['mIoU', m.m_iou], ['aAcc', m.a_acc], ['mDice', m.m_dice]].map(([label, value]) => (
                    <div key={label} className="rounded-lg bg-elevated px-2 py-1.5">
                      <dt className="text-[11px] text-ink-muted">{label}</dt>
                      <dd><MetricValue label={label} value={value} /></dd>
                    </div>
                  ))}
                </dl>
                <div className="mt-2.5"><ModelActions model={m} /></div>
              </article>
            )}
          />
        )}
      </section>
    </>
  );
}
