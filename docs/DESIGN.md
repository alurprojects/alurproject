# Design System: ALUR — Weekly Planner
**Project ID:** alur-mobile-v1

## 1. Visual Theme & Atmosphere

ALUR embodies a **calm, monochrome workspace** — the visual opposite of a cluttered productivity app. The interface feels like a **plain notebook page that got tidied up**: bold, confident typography sits on generous cream/off-white space, with a single solid black used sparingly as the anchor color for anything that matters right now (today's date, active task states, primary actions).

The mood is **quiet but assertive** — no gradients, no colorful badges, no motivational illustrations screaming for attention. Where warmth is needed (onboarding, empty states), a single hand-drawn line illustration is allowed — otherwise the interface stays flat, graphic, and editorial. This restraint is intentional: ALUR's backend does the thinking; the UI should never compete for it.

**Key Characteristics:**
- Near-black solid blocks used as the only strong visual signal (today's day header, primary CTA, active nav state)
- Flat design — no shadows, no gradients, borders instead of elevation
- Bold, oversized headline type for day names and section titles
- Generous whitespace between the weekly accordion blocks
- One accent illustration style (thin line art) reserved for onboarding/empty states only
- Icons are outline-style, single-weight, never filled except when active

## 2. Color Palette & Roles

### Primary Foundation
- **Warm Off-White** (#FAF9F7) — Primary background. Slightly warmer than pure white, used across the entire app shell.
- **Paper Gray** (#F0EFED) — Secondary surface for collapsed day-strips and inactive card backgrounds.

### Anchor & Interactive
- **Ink Black** (#111111) — The sole strong accent. Used for: active day header background, primary buttons (brain-dump FAB, "Let's go" style CTAs), active bottom-nav icon, checked task strike color reference.
- **Ink Black is never used decoratively** — every black surface on screen is either an active state or a primary action.

### Typography & Text Hierarchy
- **Charcoal** (#1A1A1A) — Primary text: day names, task titles, headlines.
- **Warm Gray** (#7A7772) — Secondary text: timestamps, metadata, placeholder text, collapsed day labels.
- **Hairline Gray** (#DEDBD6) — Borders, dividers between tasks, input outlines.

### Functional States (system feedback only)
- **Done Accent** — Completed task shown via strikethrough + Ink Black filled checkbox, no separate green needed for v1
- **Miss/Alert Terracotta** (#C1502E) — Missed-task follow-up chip accent, low-capacity warning (dev-only reference, never a loud banner)
- **Info Slate** (#6B7280) — Neutral system text (e.g. "AI sarankan pindah ke Rabu")

## 3. Typography Rules

**Primary Font Family:** Inter (or General Sans as a close alternative) — geometric grotesk, matches the bold/condensed headline style in the reference screens.

### Hierarchy & Weights
- **Day Headers (H1):** Extra-bold (800), tight letter-spacing (-0.02em), 2rem-2.5rem. E.g. "MONDAY" — always uppercase, always the loudest element on screen.
- **Section Labels (H2):** Bold (700), normal spacing, 1.25rem. E.g. "Upcoming", "All".
- **Task Title (Body-strong):** Medium (500), 1rem. No weight change when done — only strikethrough + gray-out.
- **Meta/Timestamp:** Regular (400), 0.8125rem, Warm Gray. Date, time, "(?)" marker.
- **Button/CTA Label:** Semi-bold (600), 0.9375rem, normal spacing.

### Spacing Principles
- Day header block: 1.5rem vertical padding top, 1rem bottom before task list starts
- Task rows: 0.875rem vertical padding each, separated by 1px Hairline Gray divider (no card wrapper — flat list, not boxed cards)
- 2rem gap between the active day block and the first collapsed day-strip below it

## 4. Component Stylings

### Day Header (Active/Expanded)
- **Background:** Warm Off-White (not black — reserve black for buttons/nav only, unlike the reference screens' black hero cards)
- **Typography:** H1 day name + meta line (date, time) directly beneath in Warm Gray
- **Corner Style:** None — this is a page-level header, not a card

### Day Strip (Collapsed)
- **Background:** Paper Gray, darkening slightly for days further in the future (subtle depth cue, mirrors the reference's cascading gray blocks)
- **Corner Style:** 16px rounded corners, full-width block
- **Typography:** Bold day name only, no meta line, vertically centered
- **Tap target:** Full strip height (min 56px)

### Task Row
- **Layout:** Checkbox (left) — Title (flex) — optional `(?)` marker (right)
- **Checkbox:** Outline circle, 20px, fills Ink Black with white check icon when tapped
- **Done state:** Title gets strikethrough + Warm Gray color shift, checkbox fills solid Ink Black
- **Ambiguous marker `(?)`:** Small Warm Gray superscript-style badge, tap opens inline input row (no modal)
- **Divider:** 1px Hairline Gray beneath each row, no card boxing

### Follow-up / Reschedule Chip
- **Style:** Full-width inline banner directly under the relevant task, Paper Gray background, 12px rounded corners
- **Typography:** Meta-size text (Info Slate), followed by 2-3 pill buttons (outline style, Ink Black border, transparent fill, fills Ink Black on tap)
- **Dismissable:** Swipe or explicit choice always removes the chip — never persists after a decision

### Buttons
- **Primary (Brain-dump FAB, "Add task" confirm):** Solid Ink Black background, white text/icon, fully rounded (pill shape, matching the reference's "Let's go!" button), comfortable padding (0.875rem vertical, 1.5rem horizontal)
- **Secondary (Reschedule "Terima"/"Abaikan"):** Outline Ink Black border, transparent background, 8px corners, fills black on press
- **Hover/Press State:** Simple opacity dip (0.85) on press, 150ms — no shadow lift, keeps the flat aesthetic

### Bottom Navigation
- Matches reference pattern directly: 3-4 icon-only items in a floating pill container (Warm Off-White background, Hairline Gray border), active item shown as solid Ink Black circle with white icon
- Icons: outline style, 22px, single stroke weight
- No text labels — icon-only, consistent with the minimal-surface philosophy

### Onboarding Illustration
- **Style:** Thin single-weight line art, monochrome (Charcoal strokes on Warm Off-White), small playful accents (stars, dots) allowed — this is the ONE place personality is allowed to show
- **Usage:** Only on first-launch onboarding and empty-state screens (e.g. "no tasks yet"). Never inside the daily accordion.

### Inputs (Add Task / Brain-dump)
- **Style:** Flat field, 1px Hairline Gray border, 8px corners, Warm Off-White background
- **Focus State:** Border shifts to Ink Black, no glow/shadow
- **Placeholder:** Warm Gray, plain
- **Brain-dump entry point:** Rendered as a distinct pill button (mic/sparkle icon + "Brain-dump" label) sitting beside the plain text input, both anchored at the bottom of the active day block

## 5. Layout Principles

### Grid & Structure
- **Single-column, mobile-only** for v1 — no responsive grid needed (no web dashboard in scope)
- **Max content width:** phone-native, no tablet layout considerations for MVP
- **Vertical stack order:** Active day header → task rows → add-task/brain-dump input → collapsed day strips (remaining week)

### Whitespace Strategy
- **Base unit:** 8px micro-spacing, 16px component spacing
- **Section margin:** 2rem between the active-day block and the collapsed strips list
- **Edge padding:** 1.25rem horizontal screen padding throughout

### Alignment & Visual Balance
- **Text alignment:** Left-aligned everywhere except onboarding hero text
- **Visual weight:** Deliberately low — the design's job is to disappear, letting task content and the single black accent carry all visual weight
- **No competing focal points:** At most one Ink Black surface visible per screen state (active nav icon OR a CTA — not both fighting for attention)

### Responsive Behavior & Touch
- **Touch targets:** Minimum 44x44px, checkboxes and chip buttons sized accordingly
- **Day strip tap:** Entire strip tappable to expand, not just a chevron icon
- **Reduced motion respected:** Expand/collapse animation under 250ms, disabled entirely if system reduce-motion is on

## 6. Design System Notes for Stitch/Codegen Generation

### Language to Use
- **Atmosphere:** "Calm monochrome workspace, flat and editorial, no shadows"
- **Accent usage:** "Ink Black used only for active states and primary actions — never decorative"
- **Illustration:** "Thin single-weight line art, monochrome, reserved for onboarding only"
- **Spacing:** "Generous but restrained — quiet whitespace, not gallery-scale"

### Color References
- Primary anchor: "Ink Black (#111111)"
- Background: "Warm Off-White (#FAF9F7)" / "Paper Gray (#F0EFED)"
- Text: "Charcoal (#1A1A1A)" / "Warm Gray (#7A7772)"

### Component Prompts
- "Create a day-strip block with 16px rounded corners, Paper Gray background, bold uppercase day name, full-width tap target"
- "Design a task row with an outline circle checkbox that fills Ink Black with a white check on completion, title strikethrough + gray on done"
- "Add a floating pill bottom nav with 4 outline icons, active icon shown as solid Ink Black circle with white icon"

### Incremental Iteration
1. Work on ONE component per pass (e.g., "refine the follow-up chip banner")
2. Be explicit about the delta (e.g., "increase task row vertical padding from 0.875rem to 1rem")
3. Never introduce shadows or gradients unless explicitly requested — it breaks the flat-design rule above
