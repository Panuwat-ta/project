export default function PageHeader({ eyebrow, title, description, metadata, actions }) {
  return (
    <div className="mb-5 flex flex-col gap-4 sm:mb-6 md:flex-row md:items-start">
      <div className="min-w-0">
        {eyebrow && (
          <p className="text-xs font-semibold uppercase tracking-wider text-action">{eyebrow}</p>
        )}
        <h1 className="mt-0.5 text-[28px] font-bold leading-tight md:text-[32px]">{title}</h1>
        {description && <p className="mt-1 max-w-2xl text-sm text-ink-2">{description}</p>}
        {metadata && <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-ink-muted">{metadata}</div>}
      </div>
      {actions && <div className="flex shrink-0 items-center gap-2.5 md:ml-auto">{actions}</div>}
    </div>
  );
}
