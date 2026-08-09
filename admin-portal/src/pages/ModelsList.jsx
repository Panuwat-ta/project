import { useState, useEffect } from "react";
import { Cpu, Rocket, Activity, CheckCircle2, XCircle, RotateCcw } from "lucide-react";
import { fetchModels, deployModel, dryRunModel } from "@/lib/api";

export function ModelsList() {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState({ isOpen: false, model: null, isRollback: false });
  const [deployReason, setDeployReason] = useState("");
  const [isDeploying, setIsDeploying] = useState(false);
  
  const [dryRunState, setDryRunState] = useState({ isLoading: false, result: null, modelId: null });

  const loadModels = async () => {
    try {
      const data = await fetchModels();
      setModels(data.items || []);
    } catch (error) {
      console.error("Failed to fetch models", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadModels();
    const interval = setInterval(() => {
      loadModels(true); // Assuming loadModels doesn't flash loading if we pass true or we just let it run silently
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleDeployModel = async (e) => {
    e.preventDefault();
    if (!deployReason.trim()) return;
    
    setIsDeploying(true);
    try {
      await deployModel(modalState.model.id, deployReason);
      await loadModels();
      closeModal();
    } catch (error) {
      console.error("Failed to deploy model", error);
      alert(`Deployment failed: ${error.message}`);
    } finally {
      setIsDeploying(false);
    }
  };

  const handleDryRun = async (model) => {
    setDryRunState({ isLoading: true, result: null, modelId: model.id });
    try {
      const res = await dryRunModel(model.id);
      setDryRunState({ isLoading: false, result: res, modelId: model.id });
    } catch (error) {
      setDryRunState({ isLoading: false, result: { success: false, message: error.message }, modelId: model.id });
    }
  };

  const openModal = (model, isRollback = false) => {
    setModalState({ isOpen: true, model, isRollback });
    setDeployReason(isRollback ? "Rollback to previous version" : "");
    setTimeout(() => {
      document.getElementById('deploy-reason-input')?.focus();
    }, 50);
  };

  const closeModal = () => {
    if (isDeploying) return;
    setModalState({ isOpen: false, model: null, isRollback: false });
    setDeployReason("");
  };

  const renderStatusBadge = (model) => {
    switch (model.status) {
      case 'active':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/50">
            Active
          </span>
        );
      case 'failed':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 border border-red-200 dark:border-red-800/50">
            Failed
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
            Inactive
          </span>
        );
    }
  };

  const renderActions = (model) => (
    <div className="flex items-center justify-end gap-2">
      <button
        onClick={() => handleDryRun(model)}
        disabled={dryRunState.isLoading && dryRunState.modelId === model.id}
        className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors outline-none focus:ring-2 focus:ring-slate-500 disabled:opacity-50"
      >
        <Activity className="size-4 text-slate-500" />
        Dry Run
      </button>

      {model.status !== 'active' && (
        <button
          onClick={() => openModal(model, model.deployment_history?.length > 0)}
          className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 transition-colors outline-none focus:ring-2 focus:ring-indigo-500"
        >
          {model.deployment_history?.length > 0 ? (
            <RotateCcw className="size-4" />
          ) : (
            <Rocket className="size-4" />
          )}
          {model.deployment_history?.length > 0 ? "Rollback" : "Deploy"}
        </button>
      )}
    </div>
  );

  return (
    <div className="flex flex-col gap-6 font-sans relative">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">AI Models</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          จัดการและประเมินเวอร์ชันของโมเดล AI ตรวจจับ Scam Image อย่างปลอดภัย
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2 mb-1">
            <Cpu className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">Model Operations</h3>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">ตรวจสอบสถานะ ทำ Dry Run และจัดการการ Deploy โมเดล</p>
        </div>

        {/* Desktop table */}
        <div className="hidden md:block flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">Version Tag</th>
                <th className="px-4 py-3 font-medium">Framework</th>
                <th className="px-4 py-3 font-medium">Metrics</th>
                <th className="px-4 py-3 font-medium">Deploy Date</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <td colSpan="6" className="px-4 py-3">
                      <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : models.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">
                    ไม่พบข้อมูลโมเดล
                  </td>
                </tr>
              ) : (
                models.map((model) => (
                  <tr key={model.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">{model.version_tag}</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-400 capitalize">{model.framework_compatibility || "Unknown"}</td>
                    <td className="px-4 py-3 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                      aAcc: {model.a_acc ? (model.a_acc*100).toFixed(1)+'%' : '-'} | mAcc: {model.m_acc ? (model.m_acc*100).toFixed(1)+'%' : '-'}<br/>
                      mIoU: {model.m_iou ? (model.m_iou*100).toFixed(1)+'%' : '-'} | mDice: {model.m_dice ? (model.m_dice*100).toFixed(1)+'%' : '-'}
                    </td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-400">
                      {model.deployed_at ? new Date(model.deployed_at).toLocaleString('th-TH') : '-'}
                    </td>
                    <td className="px-4 py-3">{renderStatusBadge(model)}</td>
                    <td className="px-4 py-3 text-right">{renderActions(model)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Mobile card layout */}
        <div className="md:hidden flex flex-col divide-y divide-slate-200 dark:divide-slate-800">
          {loading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div key={`skeleton-m-${i}`} className="p-4">
                <div className="h-12 bg-slate-100 dark:bg-slate-800/40 rounded-md w-full animate-pulse"></div>
              </div>
            ))
          ) : models.length === 0 ? (
            <div className="px-4 py-12 text-center text-slate-500 dark:text-slate-400">ไม่พบข้อมูลโมเดล</div>
          ) : (
            models.map((model) => (
              <div key={model.id} className="p-4 flex flex-col gap-3">
                <div className="flex items-start justify-between gap-3">
                  <span className="font-medium text-slate-900 dark:text-slate-100">{model.version_tag}</span>
                  {renderStatusBadge(model)}
                </div>
                <div className="flex flex-col gap-1 text-xs text-slate-500 dark:text-slate-400">
                  <span>Framework: <span className="capitalize text-slate-700 dark:text-slate-300">{model.framework_compatibility}</span></span>
                  <span>Metrics: aAcc {model.a_acc ? (model.a_acc*100).toFixed(1)+'%' : '-'} | mIoU {model.m_iou ? (model.m_iou*100).toFixed(1)+'%' : '-'}</span>
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs text-slate-500 dark:text-slate-400">
                    {model.deployed_at ? new Date(model.deployed_at).toLocaleString('th-TH') : '-'}
                  </span>
                </div>
                <div className="pt-2 border-t border-slate-100 dark:border-slate-800 mt-1">
                  {renderActions(model)}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Dry Run Result Alert */}
      {dryRunState.result && (
        <div className={`p-4 rounded-lg border ${dryRunState.result.success ? 'bg-emerald-50 dark:bg-emerald-900/10 border-emerald-200 dark:border-emerald-800/30' : 'bg-red-50 dark:bg-red-900/10 border-red-200 dark:border-red-800/30'} flex items-start gap-3`}>
          {dryRunState.result.success ? (
            <CheckCircle2 className="size-5 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
          ) : (
            <XCircle className="size-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
          )}
          <div>
            <h4 className={`text-sm font-semibold ${dryRunState.result.success ? 'text-emerald-800 dark:text-emerald-300' : 'text-red-800 dark:text-red-300'}`}>
              Dry Run Result (Model #{dryRunState.modelId})
            </h4>
            <p className={`text-sm mt-1 ${dryRunState.result.success ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'}`}>
              {dryRunState.result.message}
            </p>
            {dryRunState.result.details && (
              <pre className="mt-2 p-2 bg-white/50 dark:bg-black/20 rounded text-xs overflow-x-auto text-slate-700 dark:text-slate-300 font-mono">
                {JSON.stringify(dryRunState.result.details, null, 2)}
              </pre>
            )}
          </div>
          <button 
            onClick={() => setDryRunState({ isLoading: false, result: null, modelId: null })}
            className="ml-auto text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
          >
            &times;
          </button>
        </div>
      )}

      {/* Deploy/Rollback Modal */}
      {modalState.isOpen && modalState.model && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div 
            className="bg-white dark:bg-slate-900 rounded-xl shadow-xl max-w-md w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-slate-200 dark:border-slate-800"
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-title"
          >
            <form onSubmit={handleDeployModel}>
              <div className="p-6">
                <h3 id="modal-title" className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-2">
                  {modalState.isRollback ? "ยืนยันการ Rollback โมเดล" : "ยืนยันการ Deploy โมเดล"}
                </h3>
                <p className="text-sm text-slate-500 dark:text-slate-400 mb-4">
                  คุณกำลังจะตั้งค่าโมเดลเวอร์ชัน <span className="font-semibold text-slate-900 dark:text-slate-100">{modalState.model.version_tag}</span> ให้เป็น Active Model ระบบจะรัน Health Check ก่อน หากไม่ผ่าน ระบบจะระงับการ Deploy อัตโนมัติ
                </p>
                
                <div className="space-y-1.5">
                  <label htmlFor="deploy-reason-input" className="text-sm font-medium text-slate-700 dark:text-slate-300">
                    เหตุผล (Reason) <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="deploy-reason-input"
                    type="text"
                    required
                    disabled={isDeploying}
                    value={deployReason}
                    onChange={(e) => setDeployReason(e.target.value)}
                    placeholder="เช่น ปรับปรุงความแม่นยำในการตรวจจับสลิป"
                    className="w-full px-3 py-2 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-sm text-slate-900 dark:text-slate-100 rounded-lg outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 disabled:opacity-50"
                  />
                </div>
              </div>
              <div className="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={closeModal}
                  disabled={isDeploying}
                  className="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors outline-none focus:ring-2 focus:ring-slate-500 disabled:opacity-50"
                >
                  ยกเลิก
                </button>
                <button 
                  type="submit"
                  disabled={isDeploying || !deployReason.trim()}
                  className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900 flex items-center gap-2 disabled:opacity-50"
                >
                  {isDeploying ? (
                    <div className="size-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : modalState.isRollback ? (
                    <RotateCcw className="size-4" />
                  ) : (
                    <Rocket className="size-4" />
                  )}
                  {isDeploying ? "กำลังตรวจสอบ..." : "ยืนยัน"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
