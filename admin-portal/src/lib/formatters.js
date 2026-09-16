const numberFmt = new Intl.NumberFormat('th-TH');
const dateFmt = new Intl.DateTimeFormat('th-TH', { dateStyle: 'medium', timeStyle: 'short' });
const dateOnlyFmt = new Intl.DateTimeFormat('th-TH', { dateStyle: 'medium' });
const rtf = new Intl.RelativeTimeFormat('th-TH', { numeric: 'auto' });

export function formatNumber(value) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return '—';
  return numberFmt.format(Number(value));
}

export function formatMetric(value, digits = 2) {
  if (value === null || value === undefined) return null;
  return Number(value).toFixed(digits);
}

export function formatDateTime(value) {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return dateFmt.format(d);
}

export function formatDate(value) {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return dateOnlyFmt.format(d);
}

export function formatWaitingTime(value) {
  if (!value) return '—';
  const then = new Date(value).getTime();
  if (Number.isNaN(then)) return '—';
  const diffMin = Math.max(0, Math.floor((Date.now() - then) / 60000));
  if (diffMin < 1) return 'เมื่อสักครู่';
  if (diffMin < 60) return `${formatNumber(diffMin)} นาที`;
  const hours = Math.floor(diffMin / 60);
  if (hours < 24) {
    const mins = diffMin % 60;
    return mins === 0 ? `${formatNumber(hours)} ชม.` : `${formatNumber(hours)} ชม. ${formatNumber(mins)} น.`;
  }
  const days = Math.floor(hours / 24);
  if (days < 30) return rtf.format(-days, 'day');
  return formatDate(value);
}

export function formatFileSize(bytes) {
  if (bytes === null || bytes === undefined) return '—';
  const n = Number(bytes);
  if (Number.isNaN(n)) return '—';
  if (n < 1024) return `${formatNumber(n)} B`;
  const units = ['KB', 'MB', 'GB'];
  let size = n / 1024;
  let unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  return `${size.toFixed(1)} ${units[unit]}`;
}

/** Normalize risk_distribution keys (case-insensitive) to low/medium/high buckets. */
export function normalizeRiskDistribution(distribution) {
  const buckets = { high: 0, medium: 0, low: 0, unknown: 0 };
  if (!distribution || typeof distribution !== 'object') return buckets;
  for (const [rawKey, count] of Object.entries(distribution)) {
    const key = String(rawKey).toLowerCase();
    const n = Number(count) || 0;
    if (/(critical|high|severe)/.test(key)) buckets.high += n;
    else if (/(medium|moderate|mid)/.test(key)) buckets.medium += n;
    else if (/(low|safe|minimal)/.test(key)) buckets.low += n;
    else buckets.unknown += n;
  }
  return buckets;
}

export function riskLevelForScore(score) {
  if (score === null || score === undefined) return 'unknown';
  if (score >= 70) return 'high';
  if (score >= 40) return 'medium';
  return 'low';
}
