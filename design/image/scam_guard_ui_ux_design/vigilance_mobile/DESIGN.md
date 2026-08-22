---
name: Vigilance Mobile
colors:
  surface: '#f7f9ff'
  surface-dim: '#d1dbe9'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#edf4ff'
  surface-container: '#e4effd'
  surface-container-high: '#dfe9f7'
  surface-container-highest: '#d9e3f1'
  on-surface: '#121c26'
  on-surface-variant: '#3d484e'
  inverse-surface: '#27313c'
  inverse-on-surface: '#e8f2ff'
  outline: '#6e797f'
  outline-variant: '#bdc8cf'
  surface-tint: '#006685'
  primary: '#006685'
  on-primary: '#ffffff'
  primary-container: '#00a6d6'
  on-primary-container: '#003649'
  inverse-primary: '#6cd2ff'
  secondary: '#006e2d'
  on-secondary: '#ffffff'
  secondary-container: '#7cf994'
  on-secondary-container: '#007230'
  tertiary: '#855300'
  on-tertiary: '#ffffff'
  tertiary-container: '#d68900'
  on-tertiary-container: '#492b00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bfe9ff'
  primary-fixed-dim: '#6cd2ff'
  on-primary-fixed: '#001f2a'
  on-primary-fixed-variant: '#004d65'
  secondary-fixed: '#7ffc97'
  secondary-fixed-dim: '#62df7d'
  on-secondary-fixed: '#002109'
  on-secondary-fixed-variant: '#005320'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f7f9ff'
  on-background: '#121c26'
  surface-variant: '#d9e3f1'
  danger: '#DC2626'
  bg-light: '#F6F8FB'
  surface-light: '#FFFFFF'
  bg-dark: '#0F1720'
  surface-dark: '#162230'
  text-secondary: '#5E6B78'
  border: '#D8E0EA'
typography:
  display-hero:
    fontFamily: Sarabun
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Sarabun
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-lg-mobile:
    fontFamily: Sarabun
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  title-md:
    fontFamily: Sarabun
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  section-header:
    fontFamily: Sarabun
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-base:
    fontFamily: Sarabun
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  button-label:
    fontFamily: Sarabun
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
  caption:
    fontFamily: Sarabun
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  code-data:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  safe-margin: 20px
  gutter: 12px
---

## Brand & Style

The design system is engineered for **Scam Image Detection**, a utility where trust and speed are the highest priorities. The brand personality is **reliable, secure, and minimalist**. It avoids decorative flourishes to maintain a "fast-acting" utility feel, ensuring users feel protected rather than overwhelmed.

The chosen style is **Corporate / Modern** with a focus on **Tonal Hierarchy**. It utilizes a systematic approach to information density, ensuring that high-stakes data (risk scores) is immediately legible. The aesthetic is clean and professional, using subtle depth and a clinical color palette to evoke the feeling of a sophisticated security tool. 

Key principles:
- **Clarity over Decoration:** Every element must serve a functional purpose.
- **Immediate Feedback:** Real-time status indicators using semantic color coding.
- **Security-First:** A UI that feels robust and engineered, not fragile.

## Colors

The color system is strictly semantic, mapped to risk assessment levels. **Trust Blue** serves as the primary interactive color, while the "traffic light" system provides instant cognitive shortcuts for safety.

### Functional Mapping
- **Primary (#00A6D6):** Action-oriented elements, active states, and brand identification.
- **Success (#16A34A):** Low risk (0-39 score).
- **Warning (#F59E0B):** Medium risk (40-69 score).
- **Danger (#DC2626):** High risk (70-100 score).

### Dark Mode
This design system supports a native dark mode. In dark mode, surfaces shift to `#162230` to maintain depth against the `#0F1720` background, and text scales to high-contrast whites and light greys to ensure Thai glyphs remain legible.

## Typography

The system uses **Sarabun** as its cornerstone. This Choice ensures that both Thai and English text share the same vertical rhythm and weight, which is critical for a "clean" and professional look in multi-language environments. 

**Inter** is reserved for technical data strings, metadata, and numerical risk scores to provide a slight "scientific" contrast against the more humanist Sarabun.

- **Headlines:** Use Bold (700) weights to establish clear hierarchy.
- **Thai Readability:** Line heights are slightly expanded (1.4x+) to accommodate Thai vowel and tone marks without clipping.
- **Numerical Data:** Always use tabular figures for risk scores to prevent "jumping" during analysis animations.

## Layout & Spacing

This design system employs a **Fluid Grid** model specifically optimized for mobile viewports. It follows a strict **4-point grid rhythm** to ensure alignment across different screen densities.

### Structure
- **Margins:** A standard 20px "Safe Margin" is used on the left and right of the screen.
- **Cards:** Content is grouped into white surface cards with 16px internal padding.
- **Analysis Stepper:** Elements are vertically stacked with 24px (lg) spacing to allow the eye to track progress clearly.

### Breakpoints
- **Mobile (< 600px):** Single column stack. Cards span the full width of the safe margin.
- **Tablet (> 600px):** Content width is capped at 540px and centered to maintain scanability and prevent overly long line lengths for body text.

## Elevation & Depth

To convey security and organization, the system uses **Tonal Layers** combined with **Ambient Shadows**.

- **Level 0 (Background):** `#F6F8FB`. The foundation.
- **Level 1 (Cards):** `#FFFFFF`. Used for all primary content containers. These use a very soft, diffused shadow: `0px 4px 12px rgba(23, 33, 43, 0.05)`.
- **Level 2 (Modals/Overlays):** These use a more pronounced shadow to indicate focus: `0px 8px 24px rgba(23, 33, 43, 0.12)`.
- **Dark Mode Elevation:** In dark mode, depth is achieved through color lighting rather than shadows. Higher elevation levels use lighter shades of the surface color (`darkSurface` vs a slightly lighter `darkSurfaceLight`).

## Shapes

The shape language is **Rounded**, striking a balance between approachable technology and professional structure. 

- **Standard Radius:** 12px for small cards and input fields.
- **Large Radius:** 16px for primary feature cards and risk gauges.
- **Interactive Targets:** Buttons and chips maintain a minimum touch target of 44px, even if the visual container is smaller.
- **Risk Badges:** Use a "Pill" shape (fully rounded) to differentiate them from functional buttons.

## Components

### Buttons
- **Primary:** Trust Blue background, White text. 16px Rounded. Solid fill for main actions (Upload, Detect).
- **Secondary:** Transparent with Trust Blue border. Used for "Cancel" or "History".

### Risk Indicators
- **RiskBadge:** Pill-shaped, small text, using semantic colors (Success, Warning, Danger). Background should be a 10% opacity tint of the text color for a modern, "soft" look.
- **RiskGauge:** A semi-circular progress bar at the top of the results screen. The stroke color shifts dynamically based on the score.

### Inputs & Cards
- **Upload Card:** Dotted border (`border` color), large center icon, and clear instructions.
- **Analysis Card:** White surface, 12px corner radius. Features a "Scanning" animation using a horizontal Trust Blue pulse.

### Navigation
- **Bottom Navigation:** Clean line icons with labels. Active state uses Trust Blue; inactive state uses `text-secondary`. No shadows on the bar itself—use a top border of 1px `#D8E0EA` for separation.

### Interactive Heatmap
- **Heatmap Viewer:** An overlay component with an adjustable Alpha slider at the bottom. The slider track should be neutral, with a Trust Blue thumb.