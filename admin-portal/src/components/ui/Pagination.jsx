import { ChevronLeft, ChevronRight } from 'lucide-react';
import Button from './Button.jsx';
import { formatNumber } from '../../lib/formatters.js';

export default function Pagination({ page, total, limit, onChange }) {
  const totalPages = Math.max(1, Math.ceil(total / Math.max(1, limit)));
  if (totalPages <= 1) return null;
  return (
    <nav aria-label="แบ่งหน้า" className="flex items-center gap-3">
      <Button
        variant="secondary"
        size="sm"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
        aria-label="หน้าก่อนหน้า"
      >
        <ChevronLeft size={16} aria-hidden="true" />
        ก่อนหน้า
      </Button>
      <span className="text-sm text-ink-2" aria-live="polite">
        หน้า {formatNumber(page)} / {formatNumber(totalPages)} (ทั้งหมด {formatNumber(total)} รายการ)
      </span>
      <Button
        variant="secondary"
        size="sm"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
        aria-label="หน้าถัดไป"
      >
        ถัดไป
        <ChevronRight size={16} aria-hidden="true" />
      </Button>
    </nav>
  );
}
