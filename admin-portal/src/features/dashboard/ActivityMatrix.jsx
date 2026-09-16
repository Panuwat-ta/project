import { formatDate } from '../../lib/formatters.js';

/**
 * Compact activity matrix for scan_trend (SVG/CSS only, no canvas).
 * Every cell is keyboard-focusable with a Thai tooltip; a visually-hidden
 * table summarizes the same data for screen readers. No entrance animation.
 */
export default function ActivityMatrix({ trend }) {
  if (!trend || trend.length === 0) return null;
  const counts = trend.map((t) => t.count);
  const max = Math.max(1, ...counts);
  const total = counts.reduce((a, b) => a + b, 0);
  const peak = trend.reduce((best, t) => (t.count > best.count ? t : best), trend[0]);
  const dates = trend.map((t) => t.date);
  const rangeLabel = dates.length > 1 ? `${formatDate(dates[0])} – ${formatDate(dates[dates.length - 1])}` : formatDate(dates[0]);

  const level = (count) => {
    if (count === 0) return 'bg-surface-2';
    const ratio = count / max;
    if (ratio > 0.75) return 'bg-bad';
    if (ratio > 0.5) return 'bg-warn';
    if (ratio > 0.25) return 'bg-action';
    return 'bg-action/30';
  };

  return (
    <section aria-label="กิจกรรมการสแกน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <div className="flex flex-wrap items-baseline gap-x-6 gap-y-1">
        <h2 className="text-base font-bold">แผนที่สัญญาณการสแกน</h2>
        <p className="text-xs text-ink-muted">
          {rangeLabel} · รวม {total.toLocaleString('th-TH')} ครั้ง
        </p>
      </div>
      <dl className="mt-3 flex flex-wrap gap-x-6 gap-y-1 text-[13px]">
        <div className="flex gap-2">
          <dt className="text-ink-2">สูงสุดต่อวัน</dt>
          <dd className="tnum font-bold">{peak.count.toLocaleString('th-TH')} <span className="font-normal text-ink-muted">({formatDate(peak.date)})</span></dd>
        </div>
        <div className="flex gap-2">
          <dt className="text-ink-2">เฉลี่ยต่อวัน</dt>
          <dd className="tnum font-bold">{Math.round(total / trend.length).toLocaleString('th-TH')}</dd>
        </div>
      </dl>
      <div className="mt-3 flex flex-wrap gap-1.5" role="group" aria-label="จำนวนสแกนรายวัน">
        {trend.map((item) => (
          <button
            key={item.date}
            type="button"
            title={`${formatDate(item.date)}: ${item.count.toLocaleString('th-TH')} ครั้ง`}
            aria-label={`${formatDate(item.date)} สแกน ${item.count.toLocaleString('th-TH')} ครั้ง`}
            className={`h-7 min-w-7 rounded-md px-1 text-[11px] font-semibold text-white transition-colors duration-150 hover:ring-2 hover:ring-focus focus-visible:outline-2 focus-visible:outline-focus ${level(item.count)}`}
          >
            {item.count}
          </button>
        ))}
      </div>
      <table className="sr-only">
        <caption>จำนวนสแกนรายวัน {rangeLabel}</caption>
        <tbody>
          {trend.map((item) => (
            <tr key={item.date}>
              <th scope="row">{formatDate(item.date)}</th>
              <td>{item.count} ครั้ง</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
