---
name: Elevated Social Matchmaking Hub
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
  on-surface-variant: '#c8c4d6'
  inverse-surface: '#e4e1ed'
  inverse-on-surface: '#303038'
  outline: '#928f9f'
  outline-variant: '#474554'
  surface-tint: '#c7bfff'
  primary: '#c7bfff'
  on-primary: '#2a039d'
  primary-container: '#8e7fff'
  on-primary-container: '#24008c'
  inverse-primary: '#5a49cb'
  secondary: '#abe02e'
  on-secondary: '#253500'
  secondary-container: '#91c300'
  on-secondary-container: '#374c00'
  tertiary: '#4de082'
  on-tertiary: '#003919'
  tertiary-container: '#00a755'
  on-tertiary-container: '#003115'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c7bfff'
  on-primary-fixed: '#170065'
  on-primary-fixed-variant: '#422db2'
  secondary-fixed: '#bef443'
  secondary-fixed-dim: '#a3d724'
  on-secondary-fixed: '#141f00'
  on-secondary-fixed-variant: '#384e00'
  tertiary-fixed: '#6dfe9c'
  tertiary-fixed-dim: '#4de082'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005227'
  background: '#13131b'
  on-background: '#e4e1ed'
  surface-variant: '#34343d'
typography:
  display:
    fontFamily: Outfit
    fontSize: 56px
    fontWeight: '800'
    lineHeight: 64px
    letterSpacing: -0.03em
  display-mobile:
    fontFamily: Outfit
    fontSize: 38px
    fontWeight: '800'
    lineHeight: 46px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Outfit
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: 0em
  body-lg:
    fontFamily: DM Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0em
  body-md:
    fontFamily: DM Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-sm:
    fontFamily: DM Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: DM Sans
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: DM Sans
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: DM Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 3rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

The design system establishes a warm, lively, and mature social-gaming hub. It bridges youthful energy with high-end digital craftsmanship, replacing chaotic "gamer tropes" with crisp visual discipline.

### Personality & Emotional Response
- **Ceria & Hangat (Lively & Warm):** Built on an intimate, rich ink foundation rather than sterile pitch black. It immediately communicates camaraderie, welcoming community rooms, and approachable play.
- **Mature Modern Playfulness:** Grounded, geometric shapes and bold solid accents project clarity and trustworthiness without losing spontaneous party-play excitement.
- **Frictionless Camaraderie:** The interface evokes the immediate tactile relief of stepping into a vibrant discord room or community lounge where everything is clear, legible, and ready to go.

### Design Movement & Core Philosophy
The aesthetic combines **Flat Contemporary Functionalism** with **Bold Solid Color Blocking**:
- **Zero Gradients:** Every surface, button, background, and accent is rendered in flat, uncompromised solid color tokens. Depth is created via tonal surface stacking, precise solid borders, and controlled single-color solid drop-shadows.
- **Clarity Over Clutter:** Interfaces eliminate decorative visual gimmicks—no unicode emojis in badges, no decorative sequential numerals, no dual-color headline gimmickry, and no trailing directional arrows on copy. Every decorative or functional mark relies exclusively on clean geometric iconography.

## Colors

The palette uses a warm dark structure punctuated by vivid, uncompromising flat accents. Gradients, multi-stop radial glows, and soft fades are forbidden across all components and viewports.

### Palette Architecture
- **Primary Violet (`#8B7CFF`):** The signature anchor for social features, community badges, interactive avatar highlights, active chat channels, and level indicators.
- **Secondary Lime (`#C8FF4D`):** The high-contrast kinetic accent dedicated strictly to top-level transactional CTAs, hero actions, live statistics, and primary key state alerts.
- **Tertiary & Status Signals:**
  - Positive / Active / Ready: `#4ADE80` (Signal Teal)
  - Alert / In-Match / Busy: `#FF6B5E` (Alert Coral)
- **Neutrals & Dark Architecture:**
  - Base Canvas (`#14141C`): Warm dark ink with slight chromatic violet undertones.
  - Card Surface (`#1E1E29`): Primary raised containers and panels.
  - Elevated Container (`#272736`): Nested rows, input fields, badge backings, and active list selections.
  - Border Subdued (`#343447`): Structural crisp divider and component bounds.
  - Text Primary (`#F5F3EE`): Warm paper white, engineered to prevent eye strain against dark surfaces.
  - Text Secondary (`#9D9BB0`): Neutralized soft lilac-grey for helper text and secondary labels.

### Image and Overlay Rules
- Media card backdrops and game hero images must never use linear dark-to-transparent fades. Overlays must consist solely of a flat, uniform tint: `rgba(20, 20, 28, 0.75)`.

## Typography

The typographic hierarchy pairs the confident geometric presence of **Outfit** with the readability of **DM Sans**.

### Strict Editorial Rules
- **Solid Headline Color:** Headlines must maintain a uniform single color (`#F5F3EE`). Dual-colored words, partial word styling, and wavy underlines are prohibited.
- **No Uppercase Eyebrows:** Category labels or subtitles above headings must use standard sentence casing and must never be forced into all-caps tags.
- **Plain Text Integrity:** Do not mix symbols like middle dots (`·`) or em dashes (`—`) to join metadata chunks. Use distinct card layout slots, small structural badges, or dedicated flex items.
- **Copy Actions:** Never append arrows or directional pointers (`→`, `->`, `>`) to button text or text links. Button text must describe the direct action concisely.

## Layout & Spacing

The layout is built on a responsive 12-column grid system (switching to 4 columns on mobile) designed to maximize content legibility and direct user navigation toward room lobbies and matchmaking cards.

### Layout Mechanics
- **Max Content Constraint:** Desktop layouts center within a max container width of `1240px` with an outer section margin of `3rem`.
- **Vertical Rhythm:** Main page sections separate cleanly with `5rem` (80px) on desktop and `3rem` (48px) on mobile viewports.
- **Component Breathing Space:** Cards and room panels maintain generous internal padding (`space-lg`: 24px) to preserve a spacious, uncrowded atmosphere.
- **Form Adaptation:** Matchmaking rosters display as multi-column card arrays on desktop/tablet and reflow into fluid single-column feeds on mobile with standard 16px row gaps.

## Elevation & Depth

This system intentionally avoids blur-heavy neumorphism, diffused atmospheric backdrops, and gradient glows. Visual weight and hierarchy rely entirely on tonal container layering, solid outlines, and deliberate flat shadows.

### Elevation Hierarchy
- **Level 0 (Canvas Base):** Solid `#14141C`. Foundation for page views, full canvas flows, and outer layouts.
- **Level 1 (Card & Module Layer):** Solid `#1E1E29` enclosed by a 1px solid `#343447` border. Used for game cards, player profiles, and lobby listings.
- **Level 2 (Nested Group & Overlay Surfaces):** Solid `#272736`. Used for input elements, floating modal drawers, and highlighted member blocks.
- **Interactive Action Shadow:** Primary active elements utilize a single-color, solid-tinted drop-shadow without multi-stop color blending:
  - Lime CTAs: `box-shadow: 0 4px 18px rgba(200, 255, 77, 0.22)`
  - Violet Social Highlights: `box-shadow: 0 4px 18px rgba(139, 124, 255, 0.25)`
  - Standard Elevation: `box-shadow: 0 6px 20px rgba(0, 0, 0, 0.40)`

## Shapes

The design system uses a base roundedness factor of `2` (`0.5rem` / 8px). This geometry balances soft playfulness with structural authority:

- **Base Components (`rounded` / 8px):** Checkboxes, form fields, filter tags, and status dots.
- **Cards & Lobby Panels (`rounded-lg` / 16px to `rounded-xl` / 24px):** Feed cards, matchmaking rosters, dialog frames, and leaderboard modules.
- **Buttons & Chips (Full Pill / 9999px):** All interactive buttons, pill filters, badge indicators, and interactive avatar rings utilize continuous rounded capsules to reinforce tactile warmth.

## Components

### Buttons
- **Primary CTA (Solid Lime):** Background `#C8FF4D`, label text `#14141C` (bold `Outfit` or `DM Sans`), oversized full pill shape (`border-radius: 9999px`), vertical padding 14px, horizontal padding 28px. No trailing arrows. Hover state shifts to solid `#D7FF75` with `box-shadow: 0 4px 18px rgba(200, 255, 77, 0.30)`.
- **Secondary Social (Solid Violet):** Background `#8B7CFF`, label text `#14141C` or `#F5F3EE`, full pill shape. Active hover shifts to solid `#9E91FF`.
- **Tertiary / Ghost:** Transparent background with a 1.5px solid `#343447` border, label text `#F5F3EE`. On hover, background fills with solid `#272736`.

### Chips & Badges
- Capsule shaped (`border-radius: 9999px`), internal padding 6px 14px.
- Background uses solid `#272736` with single-color text (`#F5F3EE` or `#9D9BB0`).
- Status indicator chips use a solid 6px circular dot (`#4ADE80` for available/open lobby, `#FF6B5E` for team full/in-game).
- Strict exclusion: No emojis inside chips or badges. Use inline monochrome SVG icons where visual indicators are needed.

### Cards & Lobby Cells
- Background `#1E1E29`, border 1px solid `#343447`, corner radius 16px to 24px.
- Internal content stacks cleanly with 16px gaps. Roster avatars feature 2px solid `#8B7CFF` rings for community captains.
- Image backplates must be dimmed strictly via a flat `rgba(20, 20, 28, 0.75)` color overlay.

### Form Inputs
- Background `#272736`, border 1.5px solid `#343447`, corner radius 12px.
- Text color `#F5F3EE`, placeholder color `#9D9BB0`.
- Focus state: border turns to solid `#8B7CFF` with zero diffused glow.

### Checkboxes & Radios
- Size 20px by 20px, corner radius 6px (checkbox) or circular (radio).
- Inactive state: background `#272736`, border 1.5px solid `#343447`.
- Selected state: background `#C8FF4D` (or `#8B7CFF`), icon/check mark rendered in `#14141C`.

### Step Counters
- Numeric sequences (`01`, `02`, `03`) are strictly reserved for functional multi-step onboarding or lobby creation screens. They may not be used as decorative background labels.