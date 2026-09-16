import { AlertTriangle, CheckCircle2, Clock, MinusCircle } from 'lucide-react';
import Badge from '../../components/ui/Badge.jsx';
import { riskLevelForScore } from '../../lib/formatters.js';

const RISK_CONFIG = {
  high: { label: 'เสี่ยงสูง', tone: 'danger', icon: <AlertTriangle size={12} aria-hidden="true" /> },
  medium: { label: 'เสี่ยงกลาง', tone: 'warning', icon: <AlertTriangle size={12} aria-hidden="true" /> },
  low: { label: 'เสี่ยงต่ำ', tone: 'success', icon: <CheckCircle2 size={12} aria-hidden="true" /> },
  unknown: { label: 'ไม่ทราบ', tone: 'neutral', icon: <MinusCircle size={12} aria-hidden="true" /> },
};

export function RiskBadge({ score, grade }) {
  const level = grade ? String(grade).toLowerCase() : riskLevelForScore(score);
  const config = RISK_CONFIG[level] ?? RISK_CONFIG.unknown;
  return (
    <Badge tone={config.tone} icon={config.icon}>
      {score ?? '—'} · {config.label}
    </Badge>
  );
}

export function RiskScore({ score }) {
  const level = riskLevelForScore(score);
  const color = level === 'high' ? 'text-bad' : level === 'medium' ? 'text-warn' : level === 'low' ? 'text-ok' : 'text-ink-muted';
  return (
    <span className={`tnum text-[15px] font-bold ${color}`}>
      {score ?? '—'}
    </span>
  );
}

const STATUS_CONFIG = {
  pending: { label: 'รอตรวจ', tone: 'warning', icon: <Clock size={12} aria-hidden="true" /> },
  reviewing: { label: 'กำลังตรวจ', tone: 'info', icon: <Clock size={12} aria-hidden="true" /> },
  approved: { label: 'อนุมัติ', tone: 'success', icon: <CheckCircle2 size={12} aria-hidden="true" /> },
  rejected: { label: 'ปฏิเสธ', tone: 'danger', icon: <AlertTriangle size={12} aria-hidden="true" /> },
};

export function StatusBadge({ status }) {
  const config = STATUS_CONFIG[String(status).toLowerCase()] ?? { label: status, tone: 'neutral', icon: null };
  return (
    <Badge tone={config.tone} icon={config.icon}>
      {config.label}
    </Badge>
  );
}
