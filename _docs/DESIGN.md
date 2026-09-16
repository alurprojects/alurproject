# Design System: ALUR — Weekly Planner
**Project ID:** alur-mobile-v1

## 1. Visual Theme & Atmosphere

ALUR embodies a **bold, high-contrast, friendly monochrome workspace**. The interface feels modern, playful yet clean: heavily rounded, confident typography sits on stark pure white space, with pure solid black used as the dominant anchor color for active states, primary actions, and prominent cards.

The mood is **friendly and highly legible** — no gradients, no colorful badges. The design relies entirely on stark black-and-white contrast, generous border radii (pill shapes, blobs), and a distinct rounded typeface to provide personality. ALUR's backend does the complex thinking; the UI provides a welcoming, effortless, and slightly playful surface.

**Key Characteristics:**
- Pure black solid blocks and pure white backgrounds for maximum contrast
- Flat design — no shadows, no gradients; uses thin black outlines or solid black fills to define shapes
- Friendly, rounded, oversized headline typography
- Organic "blob" shapes or fully rounded pills for containers and illustrations
- Icons are thin outline-style, enclosed in circular borders or floating cleanly

## 2. Color Palette & Roles

### Primary Foundation
- **Pure White** (#FFFFFF) — Primary background for the entire app shell and empty surfaces.
- **Light Gray** (#F5F5F5) — Used very sparingly for inactive states or subtle dividers, though white/black contrast is preferred.

### Anchor & Interactive
- **Pure Black** (#000000) — The dominant accent and text color. Used for: headings, primary buttons (pill-shaped), active icons, selected checkboxes, and prominent data cards (like progress banners).

### Typography & Text Hierarchy
- **Pure Black** (#000000) — Primary text: day names, task titles, headlines.
- **Medium Gray** (#9CA3AF) — Secondary text: timestamps, metadata, placeholder text, unselected days.
- **Thin Black / Dark Gray** — Borders for unselected items, categories, and inputs.

### Functional States (system feedback only)
- **Done Accent** — Solid Pure Black filled circle with a white checkmark.
- **Miss/Alert Terracotta** (#C1502E) — Kept only for dev-reference if absolutely necessary, but visually, errors/misses rely on outline vs solid black patterns.
- **Info Slate** (#6B7280) — Neutral system text.

## 3. Typography Rules

**Primary Font Family:** A rounded, friendly, bold sans-serif (e.g., **Fredoka**, **Nunito**, **Quicksand**, or similar). This is crucial for the app's playful yet clean identity.

### Hierarchy & Weights
- **Large Headers (H1):** Extra-bold or Black (800/900), very large (e.g., 2.5rem - 3rem), tight letter-spacing. Used for page titles or active day headers. Sentence case is preferred for a friendlier tone (e.g., "Break your bad habits", "My challenges").
- **Section Labels (H2):** Bold (700), 1.25rem - 1.5rem.
- **Body / Task Title (Body-strong):** Medium or Semi-bold (500/600), 1rem - 1.125rem. Rounded font makes it highly readable.
- **Meta/Timestamp:** Regular (400), 0.75rem - 0.875rem, Medium Gray.
- **Button/CTA Label:** Bold (700), 1rem, inside fully rounded pill buttons.

### Spacing Principles
- **Generous Padding:** Components breathe. Large padding inside buttons and cards.
- **Task rows:** separated by ample whitespace, often utilizing circular day-selectors instead of standard square checkboxes.

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
- **Primary:** Solid Pure Black background, white text/icon, **fully rounded (pill shape)**, very generous padding (e.g., 1rem vertical, 2rem horizontal). Often spans full width or aligns right.
- **Secondary:** Thin black outline, transparent background, fully rounded pill shape.
- **Hover/Press State:** Opacity dip, no shadow.

### Bottom Navigation

Standar flat bottom bar dengan background Pure White (bukan floating pill), dipisahkan dari konten dengan divider garis sangat tipis atau whitespace. 3 ikon tetap (CONST-02):

| Posisi | Ikon | Tab |
|---|---|---|
| Kiri | `checklist` / home outline | To-do list (accordion mingguan) |
| Tengah | `calendar` / chart outline | Calendar (time-block view) |
| Kanan | `person`/`user` outline | Profile (settings + Goals) |

Active item ditandai dengan ikon solid/bolder ATAU label teks kecil di bawah ikon (misal "My challenges"). Inactive items menggunakan icon outline tipis berwarna abu-abu/hitam tanpa teks.

### Illustrations & Imagery
- **Style:** Thin single-weight line art, monochrome (black strokes on white).
- **Background Shape:** Illustrations sit inside **organic, asymmetrical "blob" shapes** with a thin black outline, adding to the playful, rounded aesthetic. Some areas of the illustration (like hair or clothes) may use solid black fill for contrast.
- **Usage:** Onboarding, empty states, or hero banners.

### Inputs (Add Task / Brain-dump)
- **Style:** Flat field, 1px Hairline Gray border, 8px corners, Warm Off-White background
- **Focus State:** Border shifts to Ink Black, no glow/shadow
- **Placeholder:** Warm Gray, plain
- **Brain-dump entry point:** Rendered as a distinct pill button (mic/sparkle icon + "Brain-dump" label) sitting beside the plain text input, both anchored at the bottom of the active day block

### Calendar Tab Components

> CONST-07 applies: tidak ada warna baru. Semua warna mengacu pada palet di Section 2.

#### Timeline / Time-Block View
- **Layout:** Vertical scroll, jam sebagai sumbu (mis. 06:00–22:00), garis Hairline Gray tiap jam, label jam di kiri dalam Warm Gray.
- **Task/habit block:** Solid Paper Gray background, 8px rounded corners, judul task (Charcoal), durasi ditunjukkan lewat tinggi block relatif terhadap skala jam. **TIDAK ada checkbox di sini** (read-only, lihat PRD.md Calendar Tab).
- **Event Google Calendar (Tahap B):** Visual dibedakan tipis — border-dashed 1px Hairline Gray, background transparan (bukan Paper Gray solid), tanpa aksi tap selain "lihat detail". Tidak memakai warna baru di luar palet (CONST-07).
- **Unscheduled section:** Strip di atas timeline (sebelum jam 06:00), berisi task tanpa waktu spesifik — style sama seperti Day Strip collapsed di To-do list, supaya konsisten secara visual antar-tab.
- **Navigasi hari:** Swipe kiri/kanan atau date-picker minimal di header, tidak perlu month-grid penuh di v1 — cukup 1 hari dalam fokus, mirip pola To-do list yang sudah auto-expand 1 hari aktif.

### Profile Tab — Goals Section

Goals ditampilkan sebagai section dalam tab Profile, bukan tab terpisah (CONST-03). Pola visual menggunakan komponen yang sudah ada — tidak ada komponen baru:

- **Goal list item:** Menggunakan pola visual task row yang sudah ada — title (Charcoal, Body-strong) + status label (Warm Gray, Meta size) + deadline (Warm Gray, Meta size). Tidak ada card wrapper, tidak ada shadow.
- **Status badge:** Text label inline (ACTIVE / DONE / ARCHIVED) dalam Warm Gray — bukan chip berwarna.
- **Tap target:** Seluruh baris tappable, expand ke daftar sub-task/progres goal.
- **Empty state:** Thin line-art illustration + CTA "Tambah goal pertamamu" (pola onboarding, sesuai Section 4 Onboarding Illustration).

## 5. Layout Principles

### Grid & Structure
- **Single-column, mobile-only** for v1 — no responsive grid needed (no web dashboard in scope)
- **Max content width:** phone-native, no tablet layout considerations for MVP
- **Vertical stack order (To-do list tab):** Active day header → task rows → add-task/brain-dump input → collapsed day strips (remaining week)
- **Vertical stack order (Calendar tab):** Date navigation header → Unscheduled strip → Time-block grid (06:00–22:00)
- **Vertical stack order (Profile tab):** User info → Settings section → Goals section

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
- **Atmosphere:** "High contrast black and white, heavily rounded, friendly and playful, no shadows"
- **Accent usage:** "Pure Black used for active states, prominent headings, and pill buttons"
- **Illustration:** "Thin line art inside an organic blob outline, solid black accents"
- **Typography:** "Must use a rounded, friendly sans-serif font (like Fredoka or Nunito)"

### Color References
- Primary anchor: "Pure Black (#000000)"
- Background: "Pure White (#FFFFFF)"
- Inactive/Secondary: "Medium Gray (#9CA3AF)"

### Component Prompts
- "Create a pill-shaped primary button, pure black with white text"
- "Design a task row with circular day indicators; active day is a solid black circle with white text, inactive is an outline circle"
- "Add a flat white bottom nav with 3 outline icons (checklist, calendar, user), active icon has a bold state or small label"

### Incremental Iteration
1. Work on ONE component per pass (e.g., "refine the follow-up chip banner")
2. Be explicit about the delta (e.g., "increase task row vertical padding from 0.875rem to 1rem")
3. Never introduce shadows or gradients unless explicitly requested — it breaks the flat-design rule above
