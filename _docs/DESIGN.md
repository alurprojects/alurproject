# Design System: ALUR — Weekly Planner
**Project ID:** alur-mobile-v1

## 1. Visual Theme & Atmosphere

ALUR embodies a **calm, matte paper workspace** — the visual feeling of a physical notebook page with clean, quiet structure. Bold, confident grotesk typography sits on warm matte paper with stepped monochromatic shading across days (Monday is the lightest paper shade, cascading progressively deeper toward Sunday). A single vibrant **vermilion orange** accent is used exclusively for completed tasks and active confirmation.

The mood is **clean, tactile, and editorial** — no loud shadows, no rainbow badges, no clutter. The interface stays flat, graphic, and calm, letting daily execution feel as lightweight and deliberate as scribbling on paper.

**Key Characteristics:**
- Warm matte paper background with a smooth 7-step monochromatic gradient from Monday to Sunday
- Bold, heavy all-caps grotesque typography for day headers (H1 ~38px, ExtraBold/Black 900)
- Rounded-square checkboxes (17x17px, 3.5px border radius)
- Vibrant vermilion orange accent (`#FF5420`) used for completed tasks (checkbox fill + strikethrough title)
- Generous breathing space between the task list and the "Add a new task..." entry point (~48px)
- Tall, comfortable collapsed day strips (~88px height) with full-width tap targets

## 2. Color Palette & Roles

### Primary Foundation
- **Light Paper Surface** (#EDEBE7) — Primary canvas (Monday). Matte, warm, easy on the eyes.
- **Dark Graphite Surface** (#4A4947) — Primary canvas for Dark Mode (Monday).

### 7-Day Stepped Monochromatic Cascade
A smooth cascading gradient gives depth across the full week:
- **Monday (Day 0):** Light `#EDEBE7` / Dark `#4A4947`
- **Tuesday (Day 1):** Light `#E2E0DC` / Dark `#403F3D`
- **Wednesday (Day 2):** Light `#D7D5CF` / Dark `#363533`
- **Thursday (Day 3):** Light `#CCCAC4` / Dark `#2C2B29`
- **Friday (Day 4):** Light `#C1BFB9` / Dark `#232221`
- **Saturday (Day 5):** Light `#B5B3AC` / Dark `#1B1A19`
- **Sunday (Day 6):** Light `#AAA8A1` / Dark `#131211`

### Typography & Text Hierarchy
- **Deep Charcoal** (#22201D light / #F0EEEA dark) — Primary text: day headers, task titles.
- **Muted Warm Gray** (#8C8A84 light / #A8A6A0 dark) — Secondary text: date/time subtitle, metadata, "(?)" marker.
- **Placeholder Gray** (#AFAEA8 light / #7A7873 dark) — "Add a new task..." prompt.
- **Checkbox Outline** (#42403D light / #9E9C96 dark) — 1.4px sharp outline for unchecked tasks.

### Functional States & Accent
- **Vermilion Orange** (#FF5420 / #FF5722) — Checked task accent. Fills the square checkbox with white check icon, and colors the strikethrough title.
- **Info Slate** (#6B7280) — Neutral system info text.

## 3. Typography Rules

**Primary Font Family:** Inter — geometric grotesk, tight tracking, crisp editorial feel.

### Hierarchy & Weights
- **Day Headers (H1):** Extra-bold (900), tight letter-spacing (-1.2px), 38px. E.g. "MONDAY" — always uppercase, prominent, confident anchor of each day.
- **Date & Time Subtitle:** Regular (400), 13.5px, letter-spacing -0.2px, Muted Warm Gray. E.g. "April, 14 2025 – 9:41am".
- **Task Title:** Regular (400), 15px, letter-spacing -0.1px. When completed: orange strikethrough.
- **Meta / Duration Tag:** Regular (400), 12.5px, Muted Warm Gray. E.g. "45m", "(?)".
- **Placeholder / Add Prompt:** Regular (400), 14.5px, Placeholder Gray.

### Spacing Principles
- **Day Header block padding:** 24px horizontal, 24px top padding, 32px bottom padding.
- **Header to Subtitle:** 5px vertical gap.
- **Subtitle to First Task:** 22px vertical gap.
- **Task Rows:** 4.5px vertical padding per row (~9px between task lines).
- **Task to "Add a new task...":** Generous 48px vertical breathing gap.
- **Collapsed Day Strips:** 88px height, 24px horizontal padding, vertically centered H1 type.

## 4. Component Stylings

### Day Header (Active/Expanded)
- **Background:** Matched to the day's stepped shade (`lightDayShades[dayIndex]`).
- **Typography:** H1 day name (38px, w900, uppercase) + Date Subtitle beneath in Muted Warm Gray.
- **Padding:** 24px horizontal, 24px top, 32px bottom.

### Day Strip (Collapsed)
- **Background:** Cascading stepped shade for that day.
- **Height:** 88px full-width tap target.
- **Typography:** 38px, w900, uppercase day name, vertically centered.

### Task Row
- **Checkbox:** Square, 17x17px, 3.5px border radius, 1.4px border.
  - *Unchecked:* Transparent fill, Checkbox Outline border.
  - *Checked:* Solid Vermilion Orange fill + border, white check icon.
- **Title:** 15px, 11px margin from checkbox.
  - *Unchecked:* Deep Charcoal.
  - *Checked:* Vermilion Orange with matching strikethrough line.
- **Ambiguous Marker `(?)`:** 14px Muted Warm Gray text next to task title; tap expands inline clarification.

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
- **Atmosphere:** "High contrast black and white, flat and editorial, bold typography, no shadows"
- **Accent usage:** "Pure Black used for active states, prominent headings, and pill buttons"
- **Illustration:** "Thin line art inside an organic blob outline, solid black accents"
- **Typography:** "Inter (geometric grotesk), bold uppercase headlines, clean readability"

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
