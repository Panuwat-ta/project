---
name: ScamGuard Documentation
description: A Thai-first evidence field manual for navigating and verifying ScamGuard technical records.
colors:
  paper: "#f4f7f6"
  surface: "#ffffff"
  surface-muted: "#eaf0ef"
  ink: "#142728"
  muted: "#5b6c6d"
  rule: "#cdd9d7"
  teal-index: "#087f78"
  teal-ink: "#05635e"
  teal-wash: "#d9f1ee"
  warning-ink: "#8b5b10"
  warning-wash: "#fff4d6"
  danger-ink: "#a33b35"
  danger-wash: "#ffebe8"
  info-wash: "#e6f1f7"
  code-surface: "#102223"
  code-ink: "#e9f4f2"
  dark-paper: "#0c1516"
  dark-surface: "#111d1e"
  dark-surface-muted: "#182829"
  dark-ink: "#e8f0ef"
  dark-muted: "#a5b7b5"
  dark-rule: "#304342"
  dark-teal-index: "#59c8be"
  dark-teal-ink: "#86ddd5"
  dark-teal-wash: "#163c3a"
  dark-warning-ink: "#f4c36a"
  dark-warning-wash: "#382b16"
  dark-danger-ink: "#ff9b91"
  dark-danger-wash: "#3a2220"
  dark-info-wash: "#172d38"
  dark-code-surface: "#081112"
typography:
  display:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "clamp(2.4rem, 5vw, 4rem)"
    fontWeight: 700
    lineHeight: 0.98
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "clamp(1.75rem, 3vw, 2.75rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.035em"
  headline-mobile:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "clamp(1.75rem, 7vw, 2.25rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.035em"
  title:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "1.72rem"
    fontWeight: 700
    lineHeight: 1.32
    letterSpacing: "-0.025em"
  body:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.72
    letterSpacing: "normal"
  label:
    fontFamily: "Sarabun, Tahoma, sans-serif"
    fontSize: "0.78rem"
    fontWeight: 700
    lineHeight: 1.45
    letterSpacing: "0.08em"
  code:
    fontFamily: "Noto Sans Mono, SFMono-Regular, Consolas, monospace"
    fontSize: "0.84rem"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "normal"
rounded:
  inline: "0.3rem"
  copy: "0.4rem"
  nav-item: "0.45rem"
  input: "0.5rem"
  control: "0.55rem"
  code: "0.65rem"
  dialog: "0.8rem"
  pill: "999px"
spacing:
  viewport-edge: "10px"
  xs: "0.35rem"
  sm: "0.55rem"
  md: "0.8rem"
  lg: "1rem"
  xl: "1.5rem"
  xxl: "2rem"
components:
  control:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.5rem 0.8rem"
    height: "2.6rem"
  control-hover:
    backgroundColor: "{colors.teal-wash}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.5rem 0.8rem"
  navigation-current:
    backgroundColor: "{colors.teal-wash}"
    textColor: "{colors.teal-ink}"
    rounded: "{rounded.nav-item}"
    padding: "0.42rem 0.55rem"
  search-field:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.input}"
    padding: "0.55rem 0.75rem"
    height: "2.8rem"
  tag:
    textColor: "{colors.muted}"
    rounded: "{rounded.pill}"
    padding: "0.16rem 0.55rem"
  code-block:
    backgroundColor: "{colors.code-surface}"
    textColor: "{colors.code-ink}"
    typography: "{typography.code}"
    rounded: "{rounded.code}"
    padding: "1.2rem"
  info-callout:
    backgroundColor: "{colors.info-wash}"
    textColor: "{colors.ink}"
    padding: "1rem 1.1rem"
  evidence-strip:
    textColor: "{colors.ink}"
    padding: "1.1rem 0"
  diagram-frame:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
---

# Design System: ScamGuard Documentation

## Overview

**Creative North Star: "The Evidence Field Manual"**

ScamGuard Documentation is a Read-mode technical record, not a product marketing page. Its world is a quiet evidence field: cool paper, dark ink, teal indexing marks, crisp dividers, and square data surfaces. The visual hierarchy helps developers and evaluators locate a system area, follow verified links, and retain source context while reading Thai-first material with English technical terms.

The interface behaves like a workbench. Edge-anchored support rails surround a fluid middle track whose article and prose measures remain bounded; metadata, tags, tables, code, callouts, and diagrams are evidence instruments rather than decoration. Expression is restrained so the documentation can carry dense architecture and research material without feeling clinical or promotional.

This design record applies only to the generated static documentation under `web-ScamGuard`. It does not replace or modify the design guidance for the Admin Portal or Mobile App.

**Key Characteristics:**

- Thai-first, self-hosted typography that remains fully usable offline.
- A paper, ink, and restrained teal palette with a deliberately authored dark counterpart.
- A full-width three-column desktop workbench with edge-anchored support rails and a centered article.
- Crisp rules and tonal fills instead of generic card stacks.
- Active reading position, source context, and technical diagrams treated as first-class evidence.
- Accessible keyboard, focus, motion, responsive, and print behavior built into the reading system.

## Colors

The light scheme reads as cool archival paper marked with ink navy and restrained teal; the dark scheme preserves the same semantic roles instead of inverting the page mechanically.

### Primary

- **Teal Index:** The scarce active mark for the shield, focus outline, numbered reading paths, active section indicators, and interactive borders.
- **Teal Ink:** The stronger teal used for links and selected navigation text where contrast and authority matter.
- **Teal Wash:** A low-emphasis field behind selected or hovered navigation and controls.

### Secondary

- **Evidence Warning:** Amber ink and a pale amber field identify warnings without competing with the main teal navigation voice.
- **Evidence Danger:** Brick-red ink and a pale red field identify important or dangerous material.
- **Evidence Information:** A cool blue-green wash separates informational callouts from the paper field.

### Neutral

- **Cool Paper:** The page-wide reading ground.
- **Clean Surface:** The slightly brighter layer for controls, tables, navigation drawers, dialogs, and source disclosures.
- **Muted Surface:** The low-contrast layer for table headings, inline code, and quiet hover feedback.
- **Ink Navy:** The default text and structural foreground.
- **Reference Gray:** Metadata, secondary labels, inactive navigation, and supporting descriptions.
- **Archive Rule:** The recurring one-pixel divider that carries most of the system's structure.
- **Code Night / Code Paper:** The dark code field and its pale foreground remain stable, including in the light reading scheme.

### Named Rules

**The Teal Index Rule.** Teal marks location, action, or focus; it is never used as broad decoration.

**The Semantic Counterpart Rule.** Every light-scheme role has a purpose-built dark-scheme counterpart with the same meaning; do not generate dark mode with filters or blanket inversion.

**The Diagram Paper Rule.** Rendered diagrams stay on white so their exported labels, lines, and fills remain faithful in both themes.

## Typography

**Display Font:** Sarabun (with Tahoma and sans-serif fallback)

**Body Font:** Sarabun (with Tahoma and sans-serif fallback)

**Label/Mono Font:** Noto Sans Mono (with SFMono-Regular, Consolas, and monospace fallback)

**Character:** Sarabun gives Thai and Latin text one calm, institutional voice across reading and interface roles. Local Thai and Latin font files are supplied at weights 400, 600, 700, and 800 so the site remains typographically complete under `file://` without external requests.

### Hierarchy

- **Display:** Reserved for the home-page statement; its tight line-height, negative tracking, balanced wrap, short measure, and 4rem ceiling create one strong orientation moment.
- **Headline:** Used for article titles and capped at 2.75rem (44px) and 24ch so long Thai and bilingual titles remain scannable. On mobile it follows a separate clamp(1.75rem, 7vw, 2.25rem) range.
- **Title:** Used for major article sections; a top rule and generous preceding space make section boundaries explicit.
- **Body:** The default reading rhythm is spacious, with prose held to a maximum of 72 characters and article leads held to 64 characters.
- **Label:** Small uppercase text with wider tracking identifies navigation and section-index regions; it is not used for body copy.
- **Code:** A compact monospaced voice with tabular alignment for source, code blocks, inline code, metadata numbers, and zoom status.

### Named Rules

**The One Reading Voice Rule.** Sarabun carries both Thai and Latin prose; introduce no decorative display face into the documentation.

**The Evidence Measure Rule.** Long-form prose stays at or below 72 characters per line even when the surrounding shell has more room.

## Layout

The desktop masthead and document shell span the full viewport width with exactly 10px of horizontal padding and no centering margin or global width cap. The three-column grid uses a fluid 15rem-to-18rem category rail, a minmax(0, 1fr) middle track, and a fluid 16rem-to-20rem live section index, separated by a clamp(1.5rem, 2.5vw, 3rem) gap. This puts both support rails exactly 10px from their respective viewport edges.

Within the middle track, the article is centered and capped at 72rem while long-form prose remains capped at 72ch. The masthead, category rail, and section index remain in view while the article scrolls.

At 1120px and below, the shell becomes two columns: a 15rem category rail and the article; the live section index disappears. At 760px and below, the shell becomes one column while both the masthead and document shell retain the exact 10px side padding. The masthead contracts, secondary labels disappear, and the category rail becomes a fixed off-canvas drawer no wider than 20rem or 88vw. Homepage evidence counters stack, path metadata drops away, and the document catalog changes from two columns to one.

Spacing follows the content hierarchy rather than a card grid: compact spacing inside controls and metadata, about one article rhythm between related blocks, and large 2.4rem-to-3.6rem pauses before headings. Tables and code remain horizontally scrollable instead of shrinking into unreadable text.

For print, navigation chrome, breadcrumbs, copy controls, diagram toolbars, and source panels are removed. The document returns to black on white at 11pt, the title becomes 26pt, prose uses the full printable width, links remain underlined, and diagrams and tables avoid internal page breaks where possible.

### Named Rules

**The Workbench Collapse Rule.** Remove supporting rails before compressing the article; reading width and evidence legibility take priority.

**The Print Is Evidence Rule.** Printed output strips interaction but preserves semantic text, underlined links, tables, and diagrams.

## Elevation & Depth

The reading surface is flat by default. One-pixel rules, tonal fills, and sticky positioning establish hierarchy without turning every block into a floating card. A single ambient shadow appears only on modal search and expanded-diagram dialogs and on the mobile navigation drawer. The sticky masthead uses a nearly opaque surface with a restrained 14px backdrop blur to keep location stable over moving content.

### Shadow Vocabulary

- **Ambient Overlay:** A broad, low-contrast shadow (`0 12px 32px rgba(20, 39, 40, .14)` in light mode; `0 12px 32px rgba(0, 0, 0, .34)` in dark mode) separates temporary layers from the evidence field.

### Named Rules

**The Flat Evidence Rule.** Articles, tables, callouts, catalogs, and diagrams are structured by rules and tonal changes; shadows are reserved for temporary layers that sit above the document.

## Shapes

The system distinguishes instruments from evidence. Interactive controls use gently compact corners, ranging from the inline-code radius through the dialog radius, and metadata tags use a full pill. Data-bearing surfaces—tables, callouts, evidence strips, and diagram frames—remain square with crisp one-pixel borders. This contrast makes action areas easy to identify without softening the technical record into a generic card interface.

**The Square Data Rule.** Do not round containers whose job is to present evidence; reserve curvature for controls, code blocks, and lightweight tags.

## Components

### Masthead Controls

- **Shape:** Compact rounded rectangles with a 1px archive rule and a minimum height of 2.6rem.
- **Default:** Clean surface, ink text, and restrained 1.1rem line icons.
- **Hover:** Teal wash with a teal border, transitioned over 180ms ease-out.
- **Focus:** A global 3px teal outline with 3px offset remains visible around every keyboard-focusable control.

### Navigation

- **Desktop category rail:** Sticky, independently scrollable groups use native disclosure behavior and crisp top rules. The current page uses teal ink, teal wash, and stronger weight.
- **Live section index:** A quiet right rail tracks visible headings; the active link changes both border and text color and receives `aria-current="location"`.
- **Mobile drawer:** The category rail slides in over a dark backdrop, marks itself inert and hidden while closed, traps keyboard focus while open, closes with Escape or backdrop activation, and restores focus to the invoking control.

### Search

- **Trigger:** Search is available from the masthead and through Ctrl/Cmd+K.
- **Dialog:** A native modal dialog uses the clean surface, ambient overlay shadow, and a 46rem maximum width.
- **Field:** The input uses the paper background, 1px rule, compact radius, and a 2.8rem minimum height.
- **Results:** Results show category, title, and excerpt in a ranked list; feedback is announced through a polite live region. Clicking outside the dialog closes it.

### Theme Control

The control switches explicit light and dark semantic schemes, updates its Thai label and accessible name, follows the operating-system preference when no saved value exists, and persists the reader's selection locally. Theme changes do not alter diagram paper.

### Tags

Tags are small outlined pills for article metadata and catalog counts. They use muted text and a one-pixel rule; they are labels, not interactive chips.

### Tables and Callouts

Tables sit on a clean surface with square borders and muted header rows. Their wrapper is a labeled, keyboard-focusable horizontal scroll region. Informational, warning, and danger callouts use semantic tonal fills and ink colors while retaining the same square evidence shape.

### Code

Code blocks use Code Night, pale code text, a compact rounded edge, horizontal scrolling, and syntax accents limited to teal, amber, muted gray, and coral. The copy control reports success in Thai, falls back to selecting the source when clipboard access is unavailable, and restores its original label after 1.6 seconds. Inline code uses the muted surface and a small radius.

### Diagram Viewer

Diagram frames keep rendered assets on white and expose a toolbar, source disclosure, and native expanded dialog. Expanded diagrams pan inside a contained viewport and zoom from 75% to 200% in 25-point increments, with the current percentage shown in tabular numerals. The backdrop establishes modality without recoloring the diagram itself.

### Homepage Evidence Index

The home page opens with one large editorial statement, then an unrounded three-part evidence strip, a numbered start path, and a complete document catalog. Counts and leading-zero path numbers behave like index marks, not promotional metrics or calls to action.

## Do's and Don'ts

### Do:

- **Do** preserve the three-part reading model: category navigation, bounded article, and live section index where viewport width permits.
- **Do** use Sarabun's local Thai and Latin files and retain the established monospaced fallback stack for code.
- **Do** keep source path, update metadata, tags, diagrams, and tables visibly connected to the article they support.
- **Do** preserve semantic HTML, skip navigation, visible focus, focus restoration, live announcements, reduced-motion handling, and keyboard-scrollable tables.
- **Do** author light, dark, responsive, and print treatments together when adding a new documentation component.

### Don't:

- **Don't** turn this Read-mode surface into a promotional landing page, dashboard, or floating-card gallery.
- **Don't** use teal as decoration, use emojis, or add unverified claims to make the documentation feel more marketable.
- **Don't** recolor technical diagrams for dark mode or sacrifice their white evidence paper.
- **Don't** compress dense tables, code, or diagrams until they become illegible; preserve horizontal scrolling and expansion behavior.
- **Don't** apply this documentation-specific system to the Admin Portal or Mobile App; those surfaces retain their own design guidance.
