# Stitch Prompt — Home Mobile (Dark Edition)

> Cara pakai: tempel **Prompt 1**, sematkan gambar referensi, lalu tempel **Prompt 2**. Prompt 3 untuk state lain.
> Semua angka dan judul task = sample data; ganti setelah generate.

---

## Prompt 1 — Home screen

```
Design one mobile screen, 390x844, for "ALUR" — a daily planner for people overwhelmed by their list.

STYLE (strict):
- Dark, flat, editorial. No shadows, gradients, glow, glass, or texture.
- bg #0A0A0A · card #161616 · text #F5F4F1 · muted #8F8B84 · hairline 1px rgba(255,255,255,0.10).
- One accent only: vermilion #FF5420. Use it on the FAB, the active nav item, the 4px active dot, one phrase in the brief, and the capacity bar only when overloaded. Text on accent is #0A0A0A, never white.
- Inter. Day title: Black 900, uppercase, 48px, tracking -0.04em. Meta and labels: Regular 400, 10-11px, uppercase, tracking +0.08em.
- Radius 4-12px, 24px side padding, left aligned, lots of empty space.

LAYOUT:
1. Header, no card: "SELASA" huge; below it one muted mono line "28 OKT · 4 TUGAS". Top-right: one 32px circle with 1px hairline border and the initials "RA" in muted mono — the profile entry. No accent on it.
2. Morning brief: card #161616, hairline border, radius 12, padding 20. Mono eyebrow "MORNING BRIEF". One sentence (16px): "Empat tugas, total 2 jam. Sisanya bisa besok." Only the phrase "Sisanya bisa besok" in #FF5420. No icons.
3. Capacity: one mono line "KAPASITAS 2 JAM DARI 4 JAM", then a 2px full-width track (hairline base) filled with #F5F4F1 for the used portion. Accent appears here only in the overload state. No percentage, no ring, no badge.
4. Top 3 priorities: mono label "PRIORITAS". Three hairline-separated rows, read-only preview — NO checkboxes on this screen:
   - "Review laporan Q3", 16px #F5F4F1, meta "45 MNT"
   - "Balas email vendor", meta "15 MNT"
   - "Meeting sync tim desain", meta "60 MNT"
5. Quick actions: one row, both ghost text only — left "+ TAMBAH TUGAS", right "BRAIN-DUMP KE CHAT", muted uppercase mono 11px. Never filled buttons.
6. FAB: circle 56px #FF5420, "+" in #0A0A0A, bottom right, above the nav. The only filled accent surface.
7. Bottom nav: exactly three items, in this order — HOME / TO-DO / CHAT. Hairline top border, mono 10px labels. Active HOME in #FF5420 with a 4px dot; the other two in #8F8B84. The bar ends after CHAT.
   Draw three nav items. Then count them. If the count is not three, remove the extra and redraw.

HARD NOs: nothing else in the nav bar (no calendar entry, no profile entry, no overflow or "more" button), no week strip or week toggle, no mini calendar, no checkbox on Home, no progress ring, no streak, no badge, no chart, no stat tile, no photo avatar (initials only), no thumbnail, no emoji, no second filled button, no pure black #000000, no pure white #FFFFFF.

MOOD: quiet, high-contrast, a black paper notebook — not a SaaS dashboard.
```

---

## Prompt 2 — Instruksi untuk gambar referensi (paste bersama gambar)

```
Use the attached image only as a visual-direction reference, not as content to copy.

TAKE: near-black background with slightly lighter cards; heavy tight uppercase headings plus small wide-tracked labels; one saturated accent in a few small places with dark text on top; flat hairlines, moderate radius, no shadows or gradients; calm spacing, left aligned.

DO NOT TAKE: any words, numbers, icons, logos, photos, menus, buttons, layout, sections, or branding from the image. No gradient, glow, blur, 3D, glass or texture, even if present.

Apply that direction to the ALUR home screen with: bg #0A0A0A, card #161616, text #F5F4F1, muted #8F8B84, hairline rgba(255,255,255,0.10), accent #FF5420. Keep the structure: day title + one meta line + round profile initials top right, one brief card, one capacity line, 3 read-only priority rows, one ghost quick-action row, one circular FAB, and a bottom nav with three items only (HOME / TO-DO / CHAT). Copy stays Indonesian.
```

---

## Prompt 3 — State (generate terpisah, struktur sama)

```
Same ALUR dark home screen with the same three nav items (HOME / TO-DO / CHAT). Keep the header, capacity line, FAB and nav. Replace only the priorities area.

EMPTY: thin off-white line-art of an open notebook, ~60% opacity, one #FF5420 dot. Text: "Belum ada rencana untuk hari ini." Muted line: "Mulai dari satu tugas kecil."

OVERLOAD: the capacity line reads "KAPASITAS 5 JAM DARI 4 JAM" in #FF5420 and the track fill turns #FF5420. Below it one muted line: "Terlalu padat. Pindahkan satu tugas ke besok?" No buttons — the suggestion lives in Chat.

OFFLINE: thin line-art of a crossed cloud. Text: "Gagal memuat tugas." Muted line: "Periksa koneksi, lalu coba lagi." Outlined retry button, mono label "COBA LAGI".

LOADING: 3 flat #161616 skeleton rows, radius 4, no shimmer. Header and nav fully rendered.
```

---

## Catatan eksekusi

- **Nav = tiga item: HOME, TO-DO, CHAT.** Profile bukan item nav (avatar di kanan atas). Kalau hasil generate punya item keempat, regenerate — jangan tambal.
- **Home hanya ringkasan.** Prioritas read-only, tanpa checkbox; aksi mencentang dan menambah hidup di TO-DO. Tap satu baris prioritas → buka TO-DO di hari itu (interaksi, bukan elemen visual baru).
- **Satu primary action:** FAB `+`. Dua quick action sengaja ghost text, bukan tombol.
- Muncul shadow/gradient/emoji → regenerate dengan tambahan: `Flat #161616 cards only, no shadows anywhere.`
- Aksen kepakai di terlalu banyak tempat → tambahan: `Accent only on: FAB, active nav item, active dot, one phrase in the brief, and the capacity bar only when over capacity. Nothing else.`
- Jangan menambah kontrol minggu di Home. Kalau perlu, itu layar lain, bukan tambahan dekoratif.
