# DESIGN.md — web-ScamGuard t01-sidebar layout contract

Mode: Read. Thai-first. No emoji. Light-only. Vanilla CSS, no CDN.
Base: `web-ScamGuard/templates/t01-sidebar/index.html` + token source `web-ScamGuard/assets/css/site.css` (reuse, do not reinvent).

## Tokens (frozen)
Each token line below is normative; generated pages must reference these token names, not hardcode copies.
- token --navy: #0B1F3A — header, hero base, dark-band, footer accents
- token --teal: #0E7C7B — primary buttons, links, active states
- token --teal-dark: #0A5E5D — link/hover depth, hero gradient end
- token --low #1B7A4D / --med #9A6B12 / --high #B3372F — risk colors only
- token --bg #FFFFFF / --soft #F2F6F7 / --card #FFFFFF / --line #DCE6E8 / --radius 12px
- token --font: "Sarabun","TH Sarabun New",Tahoma,"Leelawadee UI",Arial,sans-serif — Thai-first stack, no webfont download
- token usage rule: page `<style>` may add t01-* layout classes but must not redefine token values

## Shell (all pages)
- `<html lang="th">`, skip link `.skip` → `#content`.
- Header `.site-head`: brand left (shield SVG + "ScamGuard Docs"), nav right with 4 Thai links (ภาพรวม / หลายชั้น / คะแนนเสี่ยง / สถาปัตยกรรม).
- Layout `.docs`: grid `240px 1fr`, gap 24px. Sidebar `.side` sticky top:16px, bordered card.
- Footer `.site-foot`: muted one-liner + back link. No emoji anywhere.

## Sidebar groups (exact, frozen order)
1. เริ่มต้น — เริ่มใช้งาน (count "3 ขั้น"), การวิเคราะห์หลายชั้น (count "3")
2. ทำความเข้าใจผลลัพธ์ — คะแนนความเสี่ยง (count "3 ระดับ"), อ่าน Heatmap
3. เชิงลึก — สถาปัตยกรรม, คำถามพบบ่อย (count "5")
- Group labels use `.t01-side-group` (uppercase micro-label style). Links carry 14px teal SVG icon + optional `.count`.
- Below nav: `.t01-legend` risk meter rows (Low/Med/High + bar + range).

## Hero (frozen)
- `.t01-hero`: navy→teal gradient, white text, radius 16px, padding 40px 32px; dotted radial overlay via ::after.
- Order: eyebrow pill (`.t01-eyebrow`, "คู่มือฉบับภาษาไทย — อ่านใน 5 นาที") → h1 (max 20ch) → lede (max 58ch, #D7E6E6) → `.badges` → `.t01-cta` (solid btn + ghost btn) → `.t01-stats` (3 stats, top border).
- Hero badges are the risk-band source of truth (see below).

## Risk badges (frozen)
- Bands: Low 0–39 เสี่ยงต่ำ / Medium 40–69 ควรตรวจสอบเพิ่ม / High 70–100 เสี่ยงสูง. No "Safe" level ever.
- Classes `.badge .b-low/.b-med/.b-high` from site.css. Same badges + meter bars reused in legend, risk table, layers.
- Risk table `.t01-risk`: 3 rows, each badge + bar (30/55/85%) + range + Thai action text.

## Content sections (frozen order)
quickstart (3 steps `.t01-steps`) → layers (3 `.t01-layer` cards, top borders teal/med/high) → risk (table) → heatmap (3-step ol) → arch (`.dark-band`) → faq (5 `<details>`, first open) → `.t01-next` closer.

## 390px rules (frozen)
- `@media(max-width:760px)`: `.docs` → 1fr, `.side` static (stacks above content), steps/layers → 1fr, hero padding 28px 20px, h1 1.55rem.
- `@media(max-width:390px)`: risk table `display:block; overflow-x:auto` (horizontal scroll, no page overflow); hero padding 24px 16px, radius 12px, h1 1.35rem; stats gap 14px; CTA buttons `flex:1` full-width stacked.
- site.css 390px: body 15px, header wraps, nav gap 10px, grid 1fr. Zero horizontal overflow at 390px is a hard gate.
