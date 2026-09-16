import { STORAGE_URL } from './env.js';

/** Allow only http(s) absolute URLs or site-relative paths. Returns null for anything else. */
export function resolveMediaUrl(url) {
  if (!url || typeof url !== 'string') return null;
  const trimmed = url.trim();
  if (/^(https?:)?\/\//i.test(trimmed)) {
    if (/^javascript:|^data:(?!image\/)/i.test(trimmed)) return null;
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return STORAGE_URL ? `${STORAGE_URL.replace(/\/$/, '')}${trimmed}` : trimmed;
  }
  // Backend-relative path: resolve against the storage base.
  if (STORAGE_URL) return `${STORAGE_URL.replace(/\/$/, '')}/${trimmed.replace(/^\//, '')}`;
  return trimmed;
}

export const REPORT_CATEGORIES = [
  { value: '', label: 'ทุกหมวดหมู่' },
  { value: 'fake_slip', label: 'สลิปปลอม' },
  { value: 'investment', label: 'หลอกลงทุน' },
  { value: 'romance_scam', label: 'โรแมนซ์สแกม' },
  { value: 'online_shopping', label: 'ช็อปปิ้งออนไลน์' },
  { value: 'identity_theft', label: 'ขโมยตัวตน' },
  { value: 'ai_deepfake', label: 'AI deepfake' },
  { value: 'other', label: 'อื่น ๆ' },
];

export function categoryLabel(value) {
  return REPORT_CATEGORIES.find((c) => c.value === value)?.label ?? value ?? '—';
}

export const REPORT_STATUSES = [
  { value: '', label: 'ทุกสถานะ' },
  { value: 'pending', label: 'รอตรวจ' },
  { value: 'reviewing', label: 'กำลังตรวจ' },
  { value: 'approved', label: 'อนุมัติ' },
  { value: 'rejected', label: 'ปฏิเสธ' },
];
