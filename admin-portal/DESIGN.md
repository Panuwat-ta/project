# ScamGuard Admin Portal — Design System (DESIGN.md)

<!-- impeccable:design-schema 1 -->

## Design Archetype
**Cyber-Forensics & Fraud Intelligence Console** (Operate Mode)
A high-density, precision-engineered security command station designed for Super Admins, fraud analysts, and AI researchers inspecting scam imagery.

## Visual Hierarchy & Ground
- **Dark Tactical Ground (Default):** Deep slate/zinc surfaces (`#090d16`, `#0f1623`, `#131c2d`, `#172133`) paired with hairline structural borders (`#1e2b40`)
- **Light Executive Ground:** Clean contrast surfaces (`#f8fafc`, `#ffffff`, `#f1f5f9`) with slate-200 borders
- **Primary Accent:** Precision Electric Cyan (`#00e5ff` / `#0891b2`) used strictly for active states, focus rings, and primary workflow triggers
- **No Cliché Slop:** No gratuitous blurred halos, no fake card stacks with giant isolated numbers, no emojis anywhere

## ScamGuard Risk Triad
Strict adherence to the 3-level severity scale:
- **Low Risk (0–39):** Crisp Emerald (`#10b981`)
- **Medium Risk (40–69):** Warning Amber (`#f59e0b`)
- **High Risk (70–100):** Alert Crimson/Rose (`#f43f5e`)

## Typography & Numerals
- **Typeface:** Geist Variable Sans
- **Numerics:** `tabular-nums font-mono` for all statistics, scan IDs, hashes, timestamps, and confidence percentages to ensure vertical scanning alignment

## Component Vocabulary
- **Button:** Precision rounded (`rounded-md`), clear focus-visible rings (`ring-2 ring-cyan-500`), tactile active scaling (`active:scale-[0.98]`), integrated loader states
- **Badge / StatusBadge / RiskBadge:** Pill containers with dot indicator pulses, contrasting foregrounds matching color theory
- **Card:** Thin border panels with separated headers, eliminating nested card anti-patterns
- **Modal:** Accessible dialog with background blur, focus trap, Escape key dismiss, and confirmation action slots
- **Toast:** In-app floating feedback system (success, error, warning, info) replacing browser native alerts
- **HeatmapComparator:** Signature forensic comparator for ScamGuard reports supporting Split Slider, Side-by-Side, and Adjustable Opacity Overlay for SegFormer segmentation masks
- **CommandPalette (`Ctrl+K`):** Instant keyboard wayfinding and global search across reports, users, scans, and system routes

## Responsive Architecture
- Desktop (1440px): Two-column layout with fixed high-density navigation sidebar and sticky top telemetry bar
- Mobile / Tablet (390px - 768px): Collapsible slide-out drawer with backdrop blur, stacked data cards, fluid tables
