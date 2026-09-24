---
name: Mabar Finder UI
colors:
  surface: '#13131b'
  surface-dim: '#13131b'
  surface-bright: '#393841'
  surface-container-lowest: '#0d0d15'
  surface-container-low: '#1b1b23'
  surface-container: '#1f1f27'
  surface-container-high: '#292932'
  surface-container-highest: '#34343d'
  on-surface: '#e4e1ed'
  on-surface-variant: '#c3c9af'
  inverse-surface: '#e4e1ed'
  inverse-on-surface: '#303038'
  outline: '#8d937c'
  outline-variant: '#434935'
  surface-tint: '#a3d724'
  primary: '#ffffff'
  on-primary: '#253500'
  primary-container: '#bef443'
  on-primary-container: '#506e00'
  inverse-primary: '#4b6700'
  secondary: '#c7bfff'
  on-secondary: '#2a039d'
  secondary-container: '#422db2'
  on-secondary-container: '#b4abff'
  tertiary: '#ffffff'
  on-tertiary: '#003919'
  tertiary-container: '#6dfe9c'
  on-tertiary-container: '#007439'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#bef443'
  primary-fixed-dim: '#a3d724'
  on-primary-fixed: '#141f00'
  on-primary-fixed-variant: '#384e00'
  secondary-fixed: '#e4dfff'
  secondary-fixed-dim: '#c7bfff'
  on-secondary-fixed: '#170065'
  on-secondary-fixed-variant: '#422db2'
  tertiary-fixed: '#6dfe9c'
  tertiary-fixed-dim: '#4de082'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005227'
  background: '#13131b'
  on-background: '#e4e1ed'
  surface-variant: '#34343d'
  surface-base: '#14141C'
  surface-card: '#1E1E29'
  surface-elevated: '#282837'
  surface-border: '#2E2E3E'
  text-primary: '#F5F3EE'
  text-muted: '#9E9EAF'
  signal-online: '#4ADE80'
  signal-alert: '#FF6B5E'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1.25rem
  gutter-mobile: 0.75rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system crafts an energetic, warm, and highly approachable dark gaming aesthetic. Departing from aggressive, hyper-militaristic esports themes, it embraces a welcoming social lounge vibe where finding teammates feels natural, joyful, and effortless.

The aesthetic fuses modern dark-mode software interfaces with social-first gaming platforms:
- **Tone & Mood:** Friendly, vibrant, communal, optimistic, and low-friction.
- **Visual Style:** Deep charcoal-violet foundations accented by high-voltage electric lime (`#C8FF4D`) and soft gamer violet (`#8B7CFF`). Pill-shaped contours, generous inner padding, and soft luminescent glows elevate key interactive touchpoints without visual clutter.
- **Copywriting Voice:** Casual, conversational, and energetic. UI copy avoids robotic jargon and aggressive uppercase labels, preferring supportive phrases like "Gas mabar!", "Cari squad baru", and "Lagi santai".

## Colors

The color palette is built on layered obsidian surfaces, allowing the chromatic accents to pop with intent.

### Palette Hierarchy
- **Base Surfaces (`#14141C`, `#1E1E29`, `#282837`):** Deep ink-toned darks with blue-violet undertones, eliminating sterile pure black while maintaining OLED contrast.
- **Primary Accent (`#C8FF4D`):** Electric Lime is reserved for primary CTAs, active states, key level metrics, and subtle ambient glows. Text rendered directly on this lime uses the dark base color `#14141C` for WCAG AAA contrast.
- **Secondary Accent (`#8B7CFF`):** Digital Violet defines social contexts—rank badges, active lobby tags, and avatar profile rings.
- **Status Indicators:** Vibrant emerald green (`#4ADE80`) reflects active "In-Game" or "Ready to Play" states, while coral red (`#FF6B5E`) denotes full parties or disconnects.
- **Borders (`#2E2E3E`):** Low-contrast structural lines that partition containers cleanly against the dark backdrop.

## Typography

The type scale combines the rounded, friendly punch of **Plus Jakarta Sans** with the utilitarian precision of **Inter**.

- **Display & Headings:** Rendered in Plus Jakarta Sans (Bold/ExtraBold). Curved terminal strokes maintain a youthful, energetic aesthetic without feeling juvenile.
- **Body & Controls:** Rendered in Inter for optimal legibility during rapid scanning of gamer tags, server pings, and matchmaking bios.
- **Rule of Thumb:** Never apply heavy letter-spacing or universal uppercase transforms across section headlines. Keep headings in natural sentence capitalization to maintain an informal, welcoming tone.

## Layout & Spacing

A fluid responsive 12-column grid anchors the platform across widescreen desktop environments, reflowing to 6 columns on tablet and 4 columns on mobile.

- **Grid Alignments:** 
  - Desktop (≥1200px): Max container width `1280px`, centered with `margin: 2rem` and `gutter: 1.25rem`.
  - Tablet (768px - 1199px): `margin: 1.5rem` and `gutter: 1rem`.
  - Mobile (<768px): Fluid full-width with `margin: 1rem` and compact vertical stack layouts.
- **Rhythm:** Spacing follows an 8pt incremental module (`space-xs` = 4px, `space-sm` = 8px, `space-md` = 16px, `space-lg` = 24px, `space-xl` = 32px).
- **Matchmaking Stream Flow:** Squad finder lists use vertical stacks with `space-md` between party cards to maximize screen density while keeping touch boundaries thumb-friendly.

## Elevation & Depth

Visual depth is achieved through **tonal layering** and **selective luminescent diffusion** rather than muddy black drop shadows:

- **Level 0 (Canvas):** Pure `#14141C`. Serves as the backdrop for all content.
- **Level 1 (Default Containers & Cards):** `#1E1E29` bordered with 1px stroke of `#2E2E3E`. 
- **Level 2 (Hover / Elevated Popovers / Modals):** Surface rises to `#282837`. An outer ambient shadow of `0 12px 32px -4px rgba(0, 0, 0, 0.45)` separates active dialogs.
- **Luminescent Accent Glows:** Active Lime elements (`#C8FF4D`) and primary CTA buttons cast an intentional colored bloom on hover:
  - `box-shadow: 0 0 20px -2px rgba(200, 255, 77, 0.35)`
- **Social Rings:** Secondary violet elements utilize a subtle violet halo on hover:
  - `box-shadow: 0 0 16px -2px rgba(139, 124, 255, 0.3)`

## Shapes

The design system embraces high roundedness (Level 3 - Pill-shaped) to reinforce the soft, approachable, and playful gaming nature of the platform.

- **Primary Interactive Elements (Buttons, Badges, Chips, Pills):** Full pill curvature (`border-radius: 9999px`).
- **Cards & Match Containers:** Generously rounded corners (`border-radius: 1.5rem` to `2rem` / `24px` to `32px`), softening the interface and drawing the eye inward toward member rosters and game tags.
- **Avatars:** Strictly circular (`rounded-full`) complemented by 2px to 3px solid accent borders (`#8B7CFF` or `#C8FF4D`).

## Components

### Buttons
- **Primary CTA ("Ajak Mabar"):** Full pill radius (`rounded-full`), solid background `#C8FF4D`, bold dark text `#14141C`. On hover, scale smoothly (`transform: scale(1.02)`) accompanied by the signature lime bloom (`rgba(200, 255, 77, 0.35)`).
- **Secondary Action:** Pill container with `#282837` fill and `#2E2E3E` border. Text in `#F5F3EE`. On hover, border illuminates to `#8B7CFF`.
- **Ghost / Utility:** Transparent fill with `#9E9EAF` text, transitioning to `#F5F3EE` on hover with a subtle `#1E1E29` surface wash.

### Chips & Badges
- **Pill Badges:** Height 28px, `rounded-full`, inner padding `4px 12px`.
- **Rank & Game Mode Badges:** Subtle tinted backgrounds (`rgba(139, 124, 255, 0.15)`) with `#8B7CFF` solid text and a small dot icon.
- **Party Availability:** `#C8FF4D` background with dark text for high-urgency notifications (e.g., "Butuh 1 Player!").

### Cards & Squad Containers
- Constructed on `#1E1E29` background with a crisp 1px `#2E2E3E` border and `rounded-2xl` (24px) corners.
- Padding: `24px` on desktop, `16px` on mobile.
- Interior elements stack member avatars in an overlapping row, followed by game tags (e.g., "Valorant", "Ranked", "Mic On").
- Hover transitions subtly raise the surface to `#282837` with border transition to `#3E3E52`.

### Avatars & Status Rings
- Circular avatar silhouettes wrapped in a distinct 2px ring:
  - Online/Searching: `#C8FF4D`
  - In Party: `#8B7CFF`
  - Offline/Idle: `#2E2E3E`
- Active indicator: Mini green dot (`#4ADE80`) docked bottom-right at 45 degrees.

### Form Inputs & Search Bars
- Background: `#14141C` inset within cards, or `#1E1E29` on base canvas.
- Radius: `rounded-full` for search bars; `rounded-xl` for multi-line request prompts.
- Border: 1px `#2E2E3E`. Focus state replaces border with `#C8FF4D` and a 2px inner ring without shifting layout geometry.
- Text: `#F5F3EE` input, placeholder in `#9E9EAF`.