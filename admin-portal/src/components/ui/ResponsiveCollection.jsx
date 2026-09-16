import { Fragment } from 'react';

/**
 * Renders a semantic table on desktop and a card list on mobile.
 * columns: [{ key, header, render(row), cardLabel? }]
 * Mobile cards keep label/value relationships via definition-list semantics.
 */
export default function ResponsiveCollection({
  columns,
  rows,
  rowKey,
  caption,
  onRowClick,
  renderCard,
  empty = null,
}) {
  if (rows.length === 0) return empty;

  return (
    <>
      <div className="hidden md:block">
        <table className="w-full border-collapse text-[13px]">
          {caption && <caption className="sr-only">{caption}</caption>}
          <thead>
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  scope="col"
                  className="border-b border-line px-3 py-2 text-left text-xs font-semibold text-ink-muted"
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr
                key={rowKey(row)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={onRowClick ? 'cursor-pointer hover:bg-surface-2' : undefined}
              >
                {columns.map((col) => (
                  <td key={col.key} className="border-b border-line/60 px-3 py-3 align-middle">
                    {col.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="flex flex-col gap-3 md:hidden" role="list">
        {rows.map((row) => (
          <Fragment key={rowKey(row)}>{renderCard(row)}</Fragment>
        ))}
      </div>
    </>
  );
}
