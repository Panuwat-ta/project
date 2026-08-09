import { useState, useEffect } from "react";

import { Cpu, Rocket } from "lucide-react";

import { fetchModels, deployModel } from "@/lib/api";

export function ModelsList() {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalState, setModalState] = useState({ isOpen: false, model: null });

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
  }, []);

  const handleDeployModel = async (modelId) => {
    try {
      await deployModel(modelId);
      loadModels();
      closeModal();
    } catch (error) {
      console.error("Failed to deploy model", error);
    }
  };

  const openModal = (model) => {
    setModalState({ isOpen: true, model });
  };

  const closeModal = () => {
    setModalState({ isOpen: false, model: null });
  };

  const renderStatusBadge = (model) => (
    model.is_active ? (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800/50">
        Active
      </span>
    ) : (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
        Inactive
      </span>
    )
  );

  const renderDeployButton = (model) => (
    !model.is_active && (
      <button
        onClick={() => openModal(model)}
        className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors outline-none focus:ring-2 focus:ring-indigo-500"
      >
        <Rocket className="size-4 text-indigo-600 dark:text-indigo-400" />
        Deploy
      </button>
    )
  );

  return (
    <div className="flex flex-col gap-6 font-sans relative">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">AI Models</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          จัดการเวอร์ชันของโมเดล AI ตรวจจับ Scam Image และสลับใช้งานเวอร์ชันที่ต้องการ
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2 mb-1">
            <Cpu className="size-5 text-indigo-600 dark:text-indigo-400" />
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">Model Versions</h3>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">แสดงรายการโมเดล AI ทั้งหมดที่มีอยู่ในระบบ</p>
        </div>

        {/* Desktop table */}
        <div className="hidden md:block flex-1 overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 font-medium">Version Tag</th>
                <th className="px-4 py-3 font-medium">File Path</th>
                <th className="px-4 py-3 font-medium">Deploy Date</th>
                <th className="px-4 py-3 font-medium">สถานะ</th>
                <th className="px-4 py-3 font-medium text-right">จัดการ</th>
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
                    <td className="px-4 py-3 font-mono text-xs text-slate-500 dark:text-slate-400">
                      {model.file_path}
                    </td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-400">
                      {model.deployed_at ? new Date(model.deployed_at).toLocaleString('th-TH') : '-'}
                    </td>
                    <td className="px-4 py-3">{renderStatusBadge(model)}</td>
                    <td className="px-4 py-3 text-right">{renderDeployButton(model)}</td>
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
                <p className="font-mono text-xs text-slate-500 dark:text-slate-400 break-all">{model.file_path}</p>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-slate-500 dark:text-slate-400">
                    {model.deployed_at ? new Date(model.deployed_at).toLocaleString('th-TH') : '-'}
                  </span>
                  {renderDeployButton(model)}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Custom Modal */}
      {modalState.isOpen && modalState.model && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-xl max-w-md w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-slate-200 dark:border-slate-800">
            <div className="p-6">
              <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-2">
                ยืนยันการ Deploy โมเดล
              </h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                คุณกำลังจะตั้งค่าโมเดลเวอร์ชัน <span className="font-semibold text-slate-900 dark:text-slate-100">{modalState.model.version_tag}</span> ให้เป็น Active Model ระบบจะใช้โมเดลนี้ในการตรวจสอบรูปภาพทั้งหมดหลังจากนี้ แน่ใจหรือไม่?
              </p>
            </div>
            <div className="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3">
              <button 
                onClick={closeModal}
                className="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-md hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors outline-none focus:ring-2 focus:ring-slate-500"
              >
                ยกเลิก
              </button>
              <button 
                onClick={() => handleDeployModel(modalState.model.id)}
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900 flex items-center gap-2"
              >
                <Rocket className="size-4" />
                ยืนยันการ Deploy
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}