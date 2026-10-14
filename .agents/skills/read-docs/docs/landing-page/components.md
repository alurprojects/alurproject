# ALUR — Spesifikasi Komponen & Layout (Tailwind)

> **Tanggal:** 2026-10-08 | **Status:** Vibe-Coding Ready
> **Cakupan:** UI Components untuk Landing Page
> **Ketergantungan:** `design-system.md` (Tokens)
> **Konteks Produk:** ALUR by BakwanSpace Studio

Dokumen ini mendefinisikan struktur molekuler dari setiap bagian di Landing Page beserta kelas utilitas Tailwind yang direkomendasikan. Struktur diperbarui untuk mencerminkan hierarki *Product by Studio*.

---

## 1. Navbar (Navigation Header)

Header minimalis, melekat di atas dengan latar transparan yang membaur dengan kanvas utama. Menampilkan ALUR sebagai fokus utama.

**Tailwind Blueprint:**
```html
<header class="w-full bg-alur-off-white py-6 px-6 md:px-12 flex justify-between items-center max-w-6xl mx-auto">
  <div class="flex items-baseline gap-2">
    <div class="font-black text-2xl tracking-[-0.04em] uppercase text-alur-charcoal">ALUR</div>
  </div>
  <nav class="hidden md:flex gap-8">
    <a href="#fitur" class="font-medium text-sm text-alur-warm-gray hover:text-alur-charcoal transition-colors">Fitur</a>
    <a href="#cara-kerja" class="font-medium text-sm text-alur-warm-gray hover:text-alur-charcoal transition-colors">Cara Kerja</a>
  </nav>
  <a href="/login" class="font-semibold text-sm text-alur-charcoal hover:opacity-70 transition-opacity">Masuk / Daftar &rarr;</a>
</header>
```

---

## 2. Button (CTA)

Satu-satunya elemen solid dengan warna dominan (Ink Black) di halaman.

**Tailwind Blueprint:**
```html
<button class="bg-alur-ink text-white font-semibold text-base py-4 px-8 rounded-lg transition-opacity duration-200 hover:opacity-85 flex items-center justify-center gap-2">
  Mulai Gratis dengan Google
  <svg class="w-4 h-4" ...>&rarr;</svg>
</button>
```

---

## 3. Hero Section

Bagian pahlawan yang menekankan teks dengan layout terpusat (center-aligned), memasukkan credit "Built by BakwanSpace".

**Tailwind Blueprint:**
```html
<section class="max-w-4xl mx-auto px-6 pt-20 pb-16 text-center flex flex-col items-center">
  <div class="mb-4 inline-block border border-alur-hairline rounded-full px-4 py-1 text-xs font-semibold text-alur-warm-gray tracking-wider uppercase">
    Built by BakwanSpace Labs
  </div>
  <h1 class="font-black text-5xl md:text-6xl leading-[1.05] tracking-[-0.04em] uppercase text-alur-charcoal mb-6">
    TEMAN YANG JUJUR SOAL KAPASITASMU.
  </h1>
  <p class="font-normal text-lg md:text-xl text-alur-warm-gray max-w-2xl mb-10 leading-relaxed">
    Bukan to-do list yang bilang "kamu pasti bisa". ALUR tahu kapan kamu sudah penuh — dan bilang terus terang.
  </p>
  <div class="flex flex-col items-center gap-3">
    <!-- CTA Button Here -->
    <span class="text-xs text-alur-warm-gray">Tanpa password. Tanpa kartu kredit. Langsung pakai.</span>
  </div>
</section>
```

---

## 4. Feature Cards (Value Proposition)

Kartu datar tanpa bayangan (flat paper style) yang menjelaskan masalah dan solusi.

**Tailwind Blueprint (Single Card):**
```html
<div class="bg-alur-paper p-8 rounded-xl border-none shadow-none flex flex-col gap-4">
  <div class="w-12 h-12 flex items-center justify-center border border-alur-hairline rounded-lg bg-alur-off-white mb-2">
    <!-- Icon SVG here (stroke: #1A1A1A) -->
  </div>
  <h3 class="font-bold text-xl text-alur-charcoal tracking-tight">Pagi Tanpa Bingung</h3>
  <p class="text-alur-charcoal font-normal text-base leading-relaxed">
    Bingung mau mulai dari mana? AI menyusun 3 prioritas utama yang muat di kapasitasmu hari ini.
  </p>
</div>
```

---

## 5. Brain-Dump Interactive Simulator (Hero / Feature Showcase)

Simulator mini interaktif (fake UI) yang menunjukkan bagaimana input bebas diubah menjadi task terstruktur.

**Tailwind Blueprint:**
```html
<div class="w-full max-w-lg mx-auto bg-alur-paper rounded-xl p-4 md:p-6 border border-alur-hairline flex flex-col gap-4">
  <!-- Fake AI message bubble -->
  <div class="self-start max-w-[80%] bg-alur-off-white border border-alur-hairline p-3 rounded-lg text-sm text-alur-charcoal">
    Ada yang mau kamu pindahkan dari kepala ke jadwal hari ini?
  </div>
  
  <!-- Fake User message bubble -->
  <div class="self-end max-w-[80%] bg-alur-off-white p-3 rounded-lg text-sm text-alur-charcoal">
    Besok harus kelarin laporan keuangan sama review presentasi
  </div>

  <!-- Fake AI extracted tasks -->
  <div class="self-start max-w-[90%] bg-alur-off-white border border-alur-hairline p-4 rounded-lg flex flex-col gap-3 w-full mt-2">
    <div class="text-xs font-semibold text-alur-warm-gray uppercase tracking-widest mb-1">Extracted Tasks</div>
    <!-- Task Item 1 -->
    <div class="flex items-center gap-3">
      <div class="w-5 h-5 rounded-full border border-alur-hairline flex-shrink-0"></div>
      <div class="flex flex-col">
        <span class="text-sm font-medium text-alur-charcoal line-clamp-1">Selesaikan laporan keuangan</span>
        <span class="text-xs text-alur-warm-gray">Besok &bull; ~60 mnt</span>
      </div>
    </div>
    <!-- ... -->
  </div>
</div>
```

---

## 6. Footer (Product by Studio)

Penutup halaman yang rapi dan editorial, menegaskan Alur sebagai flagship product dari BakwanSpace.

**Tailwind Blueprint:**
```html
<footer class="w-full max-w-6xl mx-auto px-6 py-12 border-t border-alur-hairline mt-24">
  <div class="flex flex-col md:flex-row justify-between items-start gap-8 md:gap-0">
    <div class="flex flex-col gap-2 max-w-sm">
      <span class="font-bold text-lg text-alur-charcoal tracking-tight uppercase">ALUR</span>
      <p class="text-sm text-alur-warm-gray">ALUR is an intelligent product experiment designed to bring honest capacity planning to daily life.</p>
      <div class="mt-4 flex items-center gap-2 text-xs text-alur-warm-gray font-medium">
        <span>Built with care by</span>
        <a href="https://bakwanspace.id" class="text-alur-charcoal font-semibold hover:underline border border-alur-hairline px-2 py-1 rounded">BakwanSpace Studio</a>
      </div>
    </div>
    
    <div class="flex gap-16">
      <div class="flex flex-col gap-4">
        <span class="text-xs font-bold text-alur-charcoal uppercase tracking-widest">Produk</span>
        <a href="#" class="text-sm text-alur-warm-gray hover:text-alur-charcoal">Fitur</a>
        <a href="#" class="text-sm text-alur-warm-gray hover:text-alur-charcoal">Cara Kerja</a>
      </div>
      <div class="flex flex-col gap-4">
        <span class="text-xs font-bold text-alur-charcoal uppercase tracking-widest">Legal</span>
        <a href="#" class="text-sm text-alur-warm-gray hover:text-alur-charcoal">Privasi</a>
        <a href="#" class="text-sm text-alur-warm-gray hover:text-alur-charcoal">Ketentuan</a>
      </div>
    </div>
  </div>
  <div class="w-full mt-12 pt-6 border-t border-alur-hairline flex justify-between items-center">
    <span class="text-xs text-alur-warm-gray">&copy; 2026 BakwanSpace. All rights reserved.</span>
  </div>
</footer>
```
