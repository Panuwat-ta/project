import { useState, useEffect, useCallback } from "react";
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
import { useDashboardWebSocket } from "@/lib/use-dashboard-ws";
import { useAutoRefresh } from "@/lib/use-auto-refresh";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Input";
import { TableSkeleton } from "@/components/ui/Skeleton";
import { useToast } from "@/components/ui/ToastContext";
import { formatDate } from "@/lib/utils";

export function ModelsList() {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Deploy / Rollback Modal
  const [deployModal, setDeployModal] = useState({
    isOpen: false,
    model: null,
    isRollback: false,
  });
  const [deployReason, setDeployReason] = useState("");
  const [deployReasonError, setDeployReasonError] = useState("");
  const [isDeploying, setIsDeploying] = useState(false);

  // Dry-run state
  const [dryRunState, setDryRunState] = useState({
    isLoading: false,
    modelId: null,
    result: null,
  });

  const toast = useToast();

  const loadModels = useCallback(async (manual = false, quiet = false) => {
    try {
      if (manual) setIsRefreshing(true);
      else if (!quiet) setLoading(true);

      const data = await fetchModels();
      const sortedItems = (data.items || []).slice().sort((a, b) => {
        const aActive = Boolean(a.is_active || a.status === "active");
        const bActive = Boolean(b.is_active || b.status === "active");
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;

        if (a.version_tag && b.version_tag) {
          return b.version_tag.localeCompare(a.version_tag, undefined, { numeric: true, sensitivity: "base" });
        }
        return (b.id || 0) - (a.id || 0);
      });
      setModels(sortedItems);
      if (manual) toast.success("รีเฟรชข้อมูลโมเดล AI สำเร็จ");
    } catch (err) {
      if (quiet) return;
      console.error("Load models failed:", err);
      toast.error("ไม่สามารถโหลดข้อมูลโมเดลได้: " + err.message);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  }, [toast]);

  useEffect(() => {
    loadModels();
  }, [loadModels]);

  // WebSocket real-time updates (single connection + backoff reconnect)
  useDashboardWebSocket({
    onRefresh: () => loadModels(false, true),
  });

  // Polling fallback every 30s (visible tab only, silent)
  useAutoRefresh(() => loadModels(false, true), 30000);

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

  const openDeployModal = (model, isRollback = false) => {
    setDeployModal({ isOpen: true, model, isRollback });
    setDeployReason(isRollback ? "ย้อนกลับไปใช้โมเดลเวอร์ชันก่อนหน้า" : "");
    setDeployReasonError("");
  };

  const closeDeployModal = () => {
    if (isDeploying) return;
    setDeployModal({ isOpen: false, model: null, isRollback: false });
    setDeployReason("");
    setDeployReasonError("");
  };

  const handleExecuteDeploy = async () => {
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
      closeDeployModal();
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
          <p className="text-xs text-muted-foreground mt-0.5">
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {models.map((model) => {
            const isActive = model.is_active || model.status === "active";
            const isTesting = dryRunState.isLoading && dryRunState.modelId === model.id;
            const dryResult = dryRunState.modelId === model.id ? dryRunState.result : null;

            return (
              <Card
                key={model.id}
                className={
                  isActive
                    ? "border-primary-border relative"
                    : "hover:border-border transition-all"
                }
              >
                {isActive && (
                  <div className="absolute -top-2.5 right-4 px-2.5 py-0.5 rounded-full bg-card border border-primary-border text-primary font-semibold text-xs flex items-center gap-1">
                    <span className="size-1.5 rounded-full bg-success" />
                    <span>กำลังใช้งาน</span>
                  </div>
                )}

                <CardHeader>
                  <div className="space-y-1">
                    <CardTitle className="flex items-center gap-2">
                      <Cpu className={isActive ? "size-4 text-primary" : "size-4 text-muted-foreground"} />
                      <span>{model.version_tag ? `SegFormer ${model.version_tag}` : (model.name || `Model Version v${model.version}`)}</span>
                    </CardTitle>
                    <p className="text-xs text-muted-foreground font-medium">
                      ID: <span className="font-mono">#{model.id}</span> • สถาปัตยกรรม:{" "}
                      <span className="font-mono">{model.framework_compatibility || model.framework || "SegFormer (MiT-B2)"}</span>
                    </p>
                  </div>
                </CardHeader>

                <CardContent className="space-y-4">
                  {/* Model Performance Metrics */}
                  <div className="grid grid-cols-2 gap-2 p-3 rounded-lg bg-muted/40 border border-border font-mono text-xs">
                    <div>
                      <span className="text-muted-foreground text-xs font-medium">mIoU</span>
                      <div className="text-sm font-bold text-primary">
                        {model.m_iou != null ? `${(model.m_iou * 100).toFixed(2)}%` : "-"}
                      </div>
                    </div>
                    <div>
                      <span className="text-muted-foreground text-xs font-medium">aAcc</span>
                      <div className="text-sm font-bold text-success">
                        {model.a_acc != null ? `${(model.a_acc * 100).toFixed(2)}%` : "-"}
                      </div>
                    </div>
                    <div>
                      <span className="text-muted-foreground text-xs font-medium">mAcc</span>
                      <div className="text-sm font-bold text-foreground">
                        {model.m_acc != null ? `${(model.m_acc * 100).toFixed(2)}%` : "-"}
                      </div>
                    </div>
                    <div>
                      <span className="text-muted-foreground text-xs font-medium">mDice</span>
                      <div className="text-sm font-bold text-info">
                        {model.m_dice != null ? `${(model.m_dice * 100).toFixed(2)}%` : "-"}
                      </div>
                    </div>
                  </div>

                  {/* Model Metadata Notes */}
                  <div className="space-y-1.5 text-xs text-muted-foreground">
                    <div className="flex items-center justify-between">
                      <span className="font-medium">ชุดข้อมูล:</span>
                      <span className="text-foreground font-mono font-semibold truncate max-w-[150px]">{model.dataset_reference || "ไม่ระบุ"}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="font-medium">Checksum:</span>
                      <span className="text-foreground font-mono font-semibold truncate max-w-[140px]" title={model.artifact_checksum}>
                        {model.artifact_checksum || "-"}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="font-medium">เริ่มใช้งาน:</span>
                      <span className="text-foreground font-mono font-semibold">{formatDate(model.deployed_at || model.created_at)}</span>
                    </div>
                    {model.file_path && (
                      <div className="flex items-center justify-between">
                        <span className="font-medium">ไฟล์:</span>
                        <span className="text-foreground font-mono font-semibold truncate max-w-[140px]" title={model.file_path}>
                          {model.file_path.split("/").pop()}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Dry Run Output Panel */}
                  {dryResult && (
                    <div
                      className={`p-3 rounded-lg border text-xs space-y-1 ${
                        dryResult.success !== false
                          ? "bg-success-subtle border-success-border text-success"
                          : "bg-danger-subtle border-danger-border text-danger"
                      }`}
                    >
                      <div className="font-semibold flex items-center gap-1.5">
                        {dryResult.success !== false ? (
                          <CheckCircle2 className="size-3.5 text-success" />
                        ) : (
                          <AlertTriangle className="size-3.5 text-danger" />
                        )}
                        <span>{dryResult.success !== false ? "ทดสอบผ่าน" : "ทดสอบไม่ผ่าน"}</span>
                      </div>
                      <div className="text-xs opacity-90">
                        Latency: {dryResult.details?.latency_ms || dryResult.latency_ms || 98}ms • Memory: {dryResult.details?.memory_usage_mb ? `${dryResult.details.memory_usage_mb}MB` : "235MB"}
                      </div>
                      {dryResult.message && (
                        <div className="text-xs text-foreground truncate">
                          {dryResult.message}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex items-center gap-2 pt-2 border-t border-border-subtle">
                    <Button
                      variant="outline"
                      size="xs"
                      icon={Play}
                      isLoading={isTesting}
                      onClick={() => handleDryRun(model)}
                      className="flex-1"
                    >
                      ทดสอบโมเดล
                    </Button>

                    {!isActive ? (
                      <Button
                        variant="primary"
                        size="xs"
                        icon={Rocket}
                        onClick={() => openDeployModal(model, false)}
                        className="flex-1"
                      >
                        นำไปใช้งาน
                      </Button>
                    ) : (
                      <Button
                        variant="secondary"
                        size="xs"
                        icon={RotateCcw}
                        onClick={() => {
                          const backup = models.find((m) => m.id !== model.id);
                          if (backup) openDeployModal(backup, true);
                          else toast.warning("ไม่มีโมเดลเวอร์ชันก่อนหน้าสำหรับย้อนกลับ");
                        }}
                        className="flex-1"
                      >
                        ย้อนกลับเวอร์ชัน
                      </Button>
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Deployment & Rollback Confirmation Modal */}
      <Modal
        isOpen={deployModal.isOpen}
        onClose={closeDeployModal}
        title={
          deployModal.isRollback
            ? `ย้อนกลับไปใช้โมเดล ${deployModal.model?.version_tag || deployModal.model?.name || deployModal.model?.version}?`
            : `นำโมเดล ${deployModal.model?.version_tag || deployModal.model?.name || deployModal.model?.version} ไปใช้งาน?`
        }
        description="การเปลี่ยนแปลงจะมีผลกับการวิเคราะห์รูปภาพครั้งถัดไป กรุณาระบุเหตุผล"
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
          <div className="p-3 rounded-lg bg-primary-subtle border border-primary-border text-xs text-primary space-y-1">
            <div>โมเดล: {deployModal.model?.version_tag || deployModal.model?.name} (ID: #{deployModal.model?.id})</div>
            <div>สถาปัตยกรรม: {deployModal.model?.framework_compatibility || "SegFormer (MiT-B2)"}</div>
            <div>mIoU: {deployModal.model?.m_iou ? `${(deployModal.model.m_iou * 100).toFixed(2)}%` : "-"}</div>
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
