import { AlertTriangle, Ban, CloudOff, Inbox, Loader2, Lock } from 'lucide-react';
import Button from './Button.jsx';

const CONFIG = {
  loading: { icon: Loader2, spin: true, title: 'กำลังโหลด', hint: null },
  empty: { icon: Inbox, title: 'ยังไม่มีข้อมูล', hint: null },
  emptyFilter: { icon: Inbox, title: 'ไม่พบผลจากตัวกรอง', hint: 'ลองปรับคำค้นหาหรือตัวกรอง' },
  error: { icon: AlertTriangle, title: 'เกิดข้อผิดพลาด', hint: null },
  offline: { icon: CloudOff, title: 'ออฟไลน์', hint: 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต' },
  permission: { icon: Lock, title: 'ไม่มีสิทธิ์เข้าถึง', hint: null },
  disabled: { icon: Ban, title: 'บัญชีถูกปิดใช้งาน', hint: 'ติดต่อผู้ดูแลระบบ' },
};

export default function StatePanel({
  state = 'loading',
  title,
  hint,
  actionLabel,
  onAction,
  className = '',
}) {
  const config = CONFIG[state] ?? CONFIG.loading;
  const Icon = config.icon;
  return (
    <div role="status" className={`flex flex-col items-center gap-2 rounded-xl border border-line bg-surface px-6 py-10 text-center ${className}`}>
      <Icon size={28} aria-hidden="true" className={`text-ink-muted ${config.spin ? 'animate-spin' : ''}`} />
      <p className="text-sm font-semibold text-ink">{title ?? config.title}</p>
      {(hint ?? config.hint) && <p className="max-w-sm text-[13px] text-ink-2">{hint ?? config.hint}</p>}
      {actionLabel && onAction && (
        <div className="mt-2">
          <Button variant="secondary" size="sm" onClick={onAction}>
            {actionLabel}
          </Button>
        </div>
      )}
    </div>
  );
}
