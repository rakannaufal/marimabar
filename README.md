# Teman Mabar — Platform Pencarian Rekan Bermain

> Temukan rekan main yang cocok berdasarkan game, rank, role, jadwal, dan gaya bermain.

[![Vue 3](https://img.shields.io/badge/Vue-3.x-42b883?style=flat-square&logo=vue.js)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178c6?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-6.x-646cff?style=flat-square&logo=vite)](https://vitejs.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-3ecf8e?style=flat-square&logo=supabase)](https://supabase.com/)

---

## Daftar Isi

- [Tentang Proyek](#tentang-proyek)
- [Fitur Utama](#fitur-utama)
- [Tech Stack](#tech-stack)
- [Arsitektur](#arsitektur)
- [Memulai](#memulai)
- [Konfigurasi](#konfigurasi)
- [Struktur Proyek](#struktur-proyek)
- [Pengujian](#pengujian)
- [Sebelum Produksi](#sebelum-produksi)

---

## Tentang Proyek

**Teman Mabar** adalah platform web responsif yang membantu pemain game mobile menemukan rekan bermain (*mabar*) yang cocok. Pengguna membuat profil umum, menambahkan profil untuk satu atau lebih game, lalu menelusuri pemain lain dengan filter khusus per game.

### Masalah yang Diselesaikan

- Sulit mencari rekan dengan rank, role, mode bermain, dan waktu aktif yang cocok
- Komunitas umum tidak menyediakan filter detail yang berbeda untuk tiap game
- Berbagi ID game atau kontak publik berisiko spam dan pelecehan

### Solusi

Platform multi-peran dengan profil per game yang terstruktur, filter pencarian canggih berbasis server, sistem ajakan transaksional, chat 1:1 privat, serta kontrol privasi penuh atas identitas akun game.

**Game yang didukung (MVP):** Mobile Legends: Bang Bang, PUBG Mobile, Free Fire, Valorant
**Pasar awal:** Indonesia
**Platform:** Web responsif

> Catatan MVP: Aplikasi tidak terhubung ke API resmi game. Rank dan statistik diisi pengguna dan diberi label belum terverifikasi.

---

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| Autentikasi | Daftar/login via email dan Google OAuth; verifikasi email; reset password |
| Profil Umum | Nama tampilan, avatar, bio, zona waktu, preferensi voice chat, jadwal mingguan |
| Profil Per Game | Atribut spesifik per game: rank, role, mode, hero/agent favorit, region |
| Pencarian & Filter | Filter multi-dimensi berbasis server; pagination keyset; skor kecocokan deterministik |
| Sistem Ajakan | Kirim, terima, tolak, batalkan ajakan; auto-expire 7 hari; transaksional |
| Chat 1:1 | Chat setelah penerimaan ajakan; berbagi ID game eksplisit oleh pemilik |
| Keselamatan | Blokir pengguna, laporan dengan bukti, moderasi admin, sistem banding |
| Notifikasi | Status ajakan, pesan masuk, tindakan moderasi |
| Panel Admin | Kelola atribut game, musim, moderasi laporan |

---

## Tech Stack

```
Frontend
- Vue 3               Komposisi reaktif dengan Composition API
- TypeScript 5        Type safety end-to-end
- Vite 6              Dev server dan bundler cepat
- Vue Router 4        Routing SPA dengan navigation guard
- Pinia 3             State management (sesi, katalog, filter UI)

Backend (BaaS)
- Supabase Auth       Identitas, verifikasi email, OAuth, reset password
- PostgreSQL          Database utama dengan migrasi berversi dan Row Level Security
- Supabase Realtime   Perubahan pesan dan notifikasi real-time
- Supabase Storage    Avatar dan bukti laporan di bucket terpisah
- Edge Functions      Operasi privilege, rate limiting terdistribusi, penghapusan akun
```

---

## Arsitektur

```
Browser (Vue 3 + TypeScript + Vite)
  |- Vue Router: navigasi; guard UX, bukan otorisasi
  |- Pinia: sesi, katalog, filter UI; bukan sumber izin
  +- Supabase client: Auth + query aman + Realtime + Storage
       |- Auth: identitas, email verification, reset password
       |- PostgreSQL: migrasi, RLS, view/RPC, transaksi
       |- Realtime: perubahan pesan/notifikasi yang berizin
       |- Storage: avatar dan bukti laporan di bucket terpisah
       +- Edge Functions: operasi istimewa (service role),
          throttling terdistribusi, dan penghapusan akun
```

**Prinsip keamanan:**
- Browser hanya menerima URL dan publishable/anon key — service_role tidak pernah dikirim ke browser
- RLS aktif pada semua tabel; default deny
- Otorisasi selalu diverifikasi di database, bukan hanya di frontend
- Privasi dan blokir diterapkan di database pada semua pembacaan publik

Lihat `Architecture.md` untuk detail lengkap modul, alur kritis, dan keputusan tertunda.

---

## Memulai

### Prasyarat

- Node.js versi 18 atau lebih baru
- npm versi 9 atau lebih baru
- Akun Supabase dengan project development
- (Opsional) Akun Google Cloud untuk OAuth

### Langkah Instalasi

**1. Clone dan install dependensi**

```bash
git clone <repo-url>
cd marimabar
npm ci
```

**2. Setup Supabase**

Buat proyek Supabase development baru. Jalankan migrasi dari folder `supabase/migrations/` secara berurutan melalui Supabase Dashboard > SQL Editor, lalu jalankan `supabase/seed.sql`.

Baca `BACKEND.md` untuk bootstrap akun admin dan konfigurasi izin database.

**3. Konfigurasi environment**

```bash
cp .env.example .env
```

Isi `.env` dengan nilai dari Supabase Dashboard > Settings > API:

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<publishable-anon-key>
```

Gunakan anon/publishable key, bukan service-role key. Jangan commit file `.env`.

**4. Jalankan dev server**

```bash
npm run dev
```

Buka `http://127.0.0.1:5173` di browser.

---

## Konfigurasi

### Supabase Auth

Di Supabase Dashboard > Authentication > Settings:

| Setting | Nilai |
|---|---|
| Site URL | `http://127.0.0.1:5173` (dev) / origin produksi |
| Redirect URLs | `http://127.0.0.1:5173/auth/callback*` |
| Email Verification | Aktif |
| Password Recovery | Aktif |

### Google OAuth (Opsional)

1. Buat OAuth credentials di Google Cloud Console
2. Daftarkan callback: `https://<project-ref>.supabase.co/auth/v1/callback`
3. Aktifkan provider Google di Supabase Auth > Providers
4. Jalankan migrasi `202609240003_google_adult_declaration.sql`

Pendaftaran via Google memerlukan deklarasi usia 18+. Akun baru diarahkan ke halaman deklarasi terlebih dahulu.

### Atribut Game

Migrasi `202609240004_game_attributes.sql` menambahkan 54 atribut untuk MLBB, PUBG Mobile, Free Fire, dan Valorant. Jalankan setelah migrasi 001-003. Admin dapat mengelola atribut melalui Admin > Atribut Game.

---

## Struktur Proyek

```
marimabar/
+-- src/
|   +-- app/                  Router, provider global
|   +-- features/
|   |   +-- auth/             Login, register, reset password
|   |   +-- profiles/         Profil umum dan per game
|   |   +-- catalog/          Game, season, opsi rank/role/mode
|   |   +-- search/           Pencarian dan filter
|   |   +-- invites/          Sistem ajakan mabar
|   |   +-- chat/             Percakapan 1:1
|   |   +-- moderation/       Blokir, laporan, moderasi
|   +-- shared/               Komponen UI, utilitas, types
|   +-- lib/
|       +-- supabase/         Supabase client
+-- supabase/
|   +-- migrations/           Migrasi SQL berversi
|   +-- seed.sql              Data katalog awal
|   +-- functions/            Edge Functions
+-- design/                   Rancangan UI (referensi, bukan produksi)
+-- tests/
|   +-- sql/                  SQL smoke tests
+-- prd.md                    Product Requirements Document
+-- Architecture.md           Arsitektur dan keputusan teknis
+-- Schema.md                 Kontrak data dan skema database
+-- BACKEND.md                Panduan bootstrap backend dan admin
+-- Rules.md                  Aturan wajib pengembangan
```

---

## Pengujian

```bash
# Type check
npm run typecheck

# Semua test (unit + SQL smoke test)
npm test

# Build produksi
npm run build
```

**Cakupan pengujian yang direkomendasikan:**

- RLS/RPC sebagai: anon, pemilik, pengguna lain, admin, akun terbatas
- Race condition ajakan berlawanan arah
- Expiry ajakan dan transisi status
- Blokir dua arah dan filter visibilitas
- Kebocoran field sensitif (email, game_id_private)
- Pagination dan deduplikasi hasil pencarian
- Rank per mode (Free Fire BR vs CS; PUBG TPP vs FPP)

Build lokal dan SQL smoke test bukan pengganti pengujian di Supabase nyata dengan akun multiuser.

---

## Sebelum Produksi

- [ ] Validasi privasi dan RLS di instance PostgreSQL/Supabase nyata
- [ ] Matriks pengujian peran (anon, user, admin)
- [ ] Pembatasan permintaan (rate limit) per identitas/IP
- [ ] Kebijakan retensi dan penghapusan data
- [ ] Age assurance dan tinjauan UU PDP
- [ ] Izin aset desain
- [ ] Proses moderasi dan jalur banding
- [ ] Pengujian keamanan (OWASP, SQL injection, XSS)
- [ ] Target performa: p75 LCP maksimal 2.5 detik, p95 pencarian maksimal 1 detik
- [ ] WCAG 2.2 AA pada alur utama
- [ ] Review legal dan privasi data

---

*Dokumentasi teknis lengkap tersedia di `Architecture.md`, `BACKEND.md`, `Schema.md`, dan `Rules.md`.*
