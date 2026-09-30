import { useState } from "react";
import {
  Cpu,
  RefreshCw,
  Rocket,
  RotateCcw,
  CheckCircle2,
  AlertTriangle,
  Play,
} from "lucide-react";
import { fetchModels, deployModel, dryRunModel } from "@/lib/api";
import { useAdminQuery } from "@/lib/use-admin-query";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { Select, Textarea } from "@/components/ui/Input";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { useToast } from "@/components/ui/ToastContext";
import { formatOptionalDate, formatOptionalMetric } from "@/lib/display-state";

export function ModelsList() {
  const {
    data: models,
    isLoading: loading,
    isRefreshing,
    reload: loadModels,
  } = useAdminQuery(
    async () => {
      const data = await fetchModels();
      return (data.items || []).slice().sort((a, b) => {
        const aActive = Boolean(a.is_active || a.status === "active");
        const bActive = Boolean(b.is_active || b.status === "active");
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;

        if (a.version_tag && b.version_tag) {
          return b.version_tag.localeCompare(a.version_tag, undefined, { numeric: true, sensitivity: "base" });
        }
        return (b.id || 0) - (a.id || 0);
      });
    },
    {
      initialData: [],
      resetOnError: false,
      successMessage: "รีเฟรชข้อมูลโมเดล AI สำเร็จ",
      errorMessage: "ไม่สามารถโหลดข้อมูลโมเดลได้",
      logPrefix: "Load models failed:",
    }
  );

  // Deploy / Rollback Modal
  const [deployModal, setDeployModal] = useState({
    isOpen: false,
    model: null,
    currentModel: null,
    isRollback: false,
  });
  const [deployReason, setDeployReason] = useState("");
  const [deployReasonError, setDeployReasonError] = useState("");
  const [deployTargetError, setDeployTargetError] = useState("");
  const [isDeploying, setIsDeploying] = useState(false);

  // Dry-run state
  const [dryRunState, setDryRunState] = useState({
    isLoading: false,
    modelId: null,
    result: null,
  });

  const toast = useToast();

  const handleDryRun = async (model) => {
    setDryRunState({ isLoading: true, modelId: model.id, result: null });
    try {
      const res = await dryRunModel(model.id);
      setDryRunState({ isLoading: false, modelId: model.id, result: res });
      toast.success(`ทดสอบโมเดล ${model.version_tag || model.name || model.version} สำเร็จ`);
    } catch (err) {
      setDryRunState({
        isLoading: false,
        modelId: model.id,
        result: { success: false, message: err.message },
      });
      toast.error(`ทดสอบโมเดลไม่ผ่าน: ${err.message}`);
    }
  };

  const openDeployModal = (model) => {
    setDeployModal({ isOpen: true, model, currentModel: null, isRollback: false });
    setDeployReason("");
    setDeployReasonError("");
    setDeployTargetError("");
  };

  const openRollbackModal = (currentModel) => {
    setDeployModal({ isOpen: true, model: null, currentModel, isRollback: true });
    setDeployReason("");
    setDeployReasonError("");
    setDeployTargetError("");
  };

  const resetDeployModal = () => {
    setDeployModal({ isOpen: false, model: null, currentModel: null, isRollback: false });
    setDeployReason("");
    setDeployReasonError("");
    setDeployTargetError("");
  };

  const closeDeployModal = () => {
    if (isDeploying) return;
    resetDeployModal();
  };

  const handleExecuteDeploy = async () => {
    if (!deployModal.model) {
      setDeployTargetError("กรุณาเลือกเวอร์ชันเป้าหมายก่อนดำเนินการ");
      return;
    }
    if (!deployReason.trim()) {
      setDeployReasonError("กรุณาระบุเหตุผลในการเปลี่ยนโมเดล");
      return;
    }

    setIsDeploying(true);
    try {
      await deployModel(deployModal.model.id, deployReason.trim());
      toast.success(
        deployModal.isRollback
          ? `ย้อนกลับไปใช้โมเดล ${deployModal.model.version_tag || deployModal.model.name} แล้ว`
          : `นำโมเดล ${deployModal.model.version_tag || deployModal.model.name} ไปใช้งานแล้ว`
      );
      resetDeployModal();
      await loadModels();
    } catch (err) {
      toast.error("เปลี่ยนโมเดลไม่สำเร็จ: " + err.message);
    } finally {
      setIsDeploying(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2.5">
            <span>โมเดล AI</span>
          </h2>
          <p className="text-[13px] text-muted-foreground mt-0.5">
            ดูเวอร์ชัน ทดสอบ และเลือกโมเดลที่ระบบใช้งาน
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshing}
            onClick={() => loadModels(true)}
          >
            รีเฟรช
          </Button>
        </div>
      </div>

      {loading ? (
        <TableSkeleton rows={4} cols={3} />
      ) : models.length === 0 ? (
        <Card className="border-dashed border-border p-12 text-center flex flex-col items-center justify-center space-y-3">
          <div className="size-12 rounded-xl bg-muted border border-border flex items-center justify-center text-muted-foreground">
            <Cpu className="size-6 text-muted-foreground" />
          </div>
          <div className="space-y-1">
            <h3 className="text-sm font-semibold text-foreground">ไม่พบข้อมูลโมเดล AI ในระบบ</h3>
            <p className="text-xs text-muted-foreground max-w-sm">
              ยังไม่มีโมเดลที่พร้อมใช้งานในระบบ
            </p>
          </div>
          <Button variant="outline" size="sm" icon={RefreshCw} onClick={() => loadModels(true)}>
            ตรวจสอบอีกครั้ง
          </Button>
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <div className="hidden lg:grid grid-cols-[minmax(220px,1.4fr)_repeat(4,minmax(70px,.55fr))_minmax(160px,.9fr)_minmax(230px,1.2fr)] gap-3 px-4 py-3 border-b border-border bg-muted/50 text-xs font-semibold text-muted-foreground">
            <span>เวอร์ชัน</span><span>mIoU</span><span>aAcc</span><span>mAcc</span><span>mDice</span><span>เริ่มใช้งาน</span><span className="text-right">การจัดการ</span>
          </div>
          <div className="divide-y divide-border-subtle">
            {models.map((model) => {
              const isActive = model.is_active || model.status === "active";
              const isTesting = dryRunState.isLoading && dryRunState.modelId === model.id;
              const dryResult = dryRunState.modelId === model.id ? dryRunState.result : null;
              const metric = (value) => value != null ? `${(value * 100).toFixed(2)}%` : "—";
              return (
                <section key={model.id} className={isActive ? "bg-primary-subtle/30" : "bg-card"}>
                  <div className="grid grid-cols-1 lg:grid-cols-[minmax(220px,1.4fr)_repeat(4,minmax(70px,.55fr))_minmax(160px,.9fr)_minmax(230px,1.2fr)] gap-3 items-center px-4 py-4">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <Cpu className={isActive ? "size-4 text-primary" : "size-4 text-muted-foreground"} />
                        <span className="text-sm font-semibold text-foreground">{model.version_tag ? `SegFormer ${model.version_tag}` : "ไม่ระบุเวอร์ชัน"}</span>
                        {isActive && <span className="text-xs font-semibold text-primary">กำลังใช้งาน</span>}
                      </div>
                      <div className="mt-1 text-xs text-muted-foreground">
                        <span className="font-mono">ID #{model.id}</span> · {model.framework_compatibility || "ไม่ระบุสถาปัตยกรรม"}
                      </div>
                      <div className="mt-2 lg:hidden grid grid-cols-4 gap-2 text-xs">
                        <div><span className="block text-muted-foreground">mIoU</span><span className="font-mono font-semibold text-foreground">{metric(model.m_iou)}</span></div>
                        <div><span className="block text-muted-foreground">aAcc</span><span className="font-mono font-semibold text-foreground">{metric(model.a_acc)}</span></div>
                        <div><span className="block text-muted-foreground">mAcc</span><span className="font-mono font-semibold text-foreground">{metric(model.m_acc)}</span></div>
                        <div><span className="block text-muted-foreground">mDice</span><span className="font-mono font-semibold text-foreground">{metric(model.m_dice)}</span></div>
                      </div>
                    </div>
                    <span className="hidden lg:block font-mono text-[13px] font-semibold text-foreground">{metric(model.m_iou)}</span>
                    <span className="hidden lg:block font-mono text-[13px] font-semibold text-foreground">{metric(model.a_acc)}</span>
                    <span className="hidden lg:block font-mono text-[13px] font-semibold text-foreground">{metric(model.m_acc)}</span>
                    <span className="hidden lg:block font-mono text-[13px] font-semibold text-foreground">{metric(model.m_dice)}</span>
                    <div className="text-xs text-muted-foreground">
                      <span className="lg:hidden mr-2">เริ่มใช้งาน:</span>
                      <span className="font-mono text-foreground">{formatOptionalDate(model.deployed_at)}</span>
                    </div>
                    <div className="flex items-center gap-2 lg:justify-end">
                      <Button variant="outline" size="xs" icon={Play} isLoading={isTesting} onClick={() => handleDryRun(model)}>ทดสอบ</Button>
                      {!isActive ? (
                        <Button variant="primary" size="xs" icon={Rocket} onClick={() => openDeployModal(model)}>นำไปใช้งาน</Button>
                      ) : (
                        <Button variant="secondary" size="xs" icon={RotateCcw} onClick={() => {
                          const hasTarget = models.some((m) => m.id !== model.id && !(m.is_active || m.status === "active"));
                          if (hasTarget) openRollbackModal(model); else toast.warning("ไม่มีโมเดลเวอร์ชันอื่นสำหรับย้อนกลับ");
                        }}>ย้อนกลับ</Button>
                      )}
                    </div>
                  </div>
                  <div className="px-4 pb-4 grid grid-cols-1 md:grid-cols-3 gap-2 text-xs text-muted-foreground">
                    <div>ชุดข้อมูล: <span className="text-foreground font-mono">{model.dataset_reference || "ไม่ระบุ"}</span></div>
                    <div className="min-w-0">Checksum: <span className="text-foreground font-mono break-all">{model.artifact_checksum || "ไม่ระบุ"}</span></div>
                    <div className="min-w-0">ไฟล์: <span className="text-foreground font-mono break-all">{model.file_path ? model.file_path.split("/").pop() : "ไม่ระบุ"}</span></div>
                  </div>
                  {dryResult && (
                    <div className={`mx-4 mb-4 rounded-md border px-3 py-2.5 text-xs ${dryResult.success !== false ? "bg-success-subtle border-success-border" : "bg-danger-subtle border-danger-border"}`}>
                      <div className="flex items-center gap-1.5 font-semibold text-foreground">
                        {dryResult.success !== false ? <CheckCircle2 className="size-3.5 text-success" /> : <AlertTriangle className="size-3.5 text-danger" />}
                        <span>{dryResult.success !== false ? "ทดสอบผ่าน" : "ทดสอบไม่ผ่าน"}</span>
                      </div>
                      <div className="mt-1 text-muted-foreground">Latency: {formatOptionalMetric(dryResult.details?.latency_ms ?? dryResult.latency_ms, { suffix: " ms" })} · Memory: {formatOptionalMetric(dryResult.details?.memory_usage_mb, { suffix: " MB" })}</div>
                      {dryResult.message && <div className="mt-1 text-foreground break-words">{dryResult.message}</div>}
                    </div>
                  )}
                </section>
              );
            })}
          </div>
        </Card>
      )}

      {/* Deployment & Rollback Confirmation Modal */}
      <Modal
        isOpen={deployModal.isOpen}
        onClose={closeDeployModal}
        title={
          deployModal.isRollback
            ? "ย้อนกลับเวอร์ชันโมเดล"
            : `นำโมเดล ${deployModal.model?.version_tag || "ไม่ระบุเวอร์ชัน"} ไปใช้งาน?`
        }
        description="การเปลี่ยนแปลงจะมีผลกับการวิเคราะห์รูปภาพครั้งถัดไป กรุณาตรวจสอบเป้าหมายและระบุเหตุผล"
        footer={
          <>
            <Button variant="ghost" size="sm" onClick={closeDeployModal} disabled={isDeploying}>
              ยกเลิก
            </Button>
            <Button
              variant="primary"
              size="sm"
              isLoading={isDeploying}
              onClick={handleExecuteDeploy}
              className={deployModal.isRollback ? "bg-warning text-warning-foreground hover:bg-warning/90" : ""}
            >
              {deployModal.isRollback ? "ยืนยันย้อนกลับ" : "ยืนยันใช้งานโมเดล"}
            </Button>
          </>
        }
      >
        <div className="space-y-4 pt-2">
          {deployModal.isRollback && (
            <Select
              label="เวอร์ชันเป้าหมาย"
              value={deployModal.model?.id || ""}
              onChange={(event) => {
                const target = models.find((model) => String(model.id) === event.target.value) || null;
                setDeployModal((current) => ({ ...current, model: target }));
                setDeployTargetError("");
              }}
              error={deployTargetError}
              aria-label="เลือกเวอร์ชันโมเดลสำหรับย้อนกลับ"
            >
              <option value="">เลือกเวอร์ชัน...</option>
              {models
                .filter((model) => model.id !== deployModal.currentModel?.id && !(model.is_active || model.status === "active"))
                .map((model) => (
                  <option key={model.id} value={model.id}>
                    {model.version_tag || "ไม่ระบุเวอร์ชัน"} · ID #{model.id}
                  </option>
                ))}
            </Select>
          )}

          <div className="p-3 rounded-lg bg-muted/40 border border-border text-xs text-foreground space-y-2">
            {deployModal.isRollback && (
              <div className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 pb-2 border-b border-border-subtle">
                <span className="text-muted-foreground">ปัจจุบัน</span>
                <span className="font-mono font-semibold">{deployModal.currentModel?.version_tag || "ไม่ระบุ"} · ID #{deployModal.currentModel?.id ?? "—"}</span>
                <span className="text-muted-foreground">เป้าหมาย</span>
                <span className="font-mono font-semibold">{deployModal.model ? `${deployModal.model.version_tag || "ไม่ระบุ"} · ID #${deployModal.model.id}` : "ยังไม่ได้เลือก"}</span>
              </div>
            )}
            <div>Checksum: <span className="font-mono">{deployModal.model?.artifact_checksum || "ไม่ระบุ"}</span></div>
            <div>สถาปัตยกรรม: <span className="font-mono">{deployModal.model?.framework_compatibility || "ไม่ระบุ"}</span></div>
            <div>mIoU: {deployModal.model?.m_iou != null ? `${(deployModal.model.m_iou * 100).toFixed(2)}%` : "ไม่ได้รายงาน"}</div>
          </div>

          <Textarea
            label="เหตุผลในการเปลี่ยนโมเดล *"
            required
            value={deployReason}
            onChange={(e) => {
              setDeployReason(e.target.value);
              setDeployReasonError("");
            }}
            placeholder="เช่น ปรับปรุงโมเดลประจำรอบ หรือแก้ปัญหา False Positive..."
            error={deployReasonError}
            rows={4}
          />
        </div>
      </Modal>
    </div>
  );
}
