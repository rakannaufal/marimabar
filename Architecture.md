# Architecture — Teman Mabar

**Status:** Rancangan implementasi MVP. **Sumber utama:** `prd.md` v1.0. **Kontrak data:** `Schema.d`. **Aturan wajib:** `Rules.md`. Bila dokumen berbeda, kebutuhan produk/privasi di PRD menang; keputusan teknis baru harus dicatat dan diuji sebelum diimplementasikan.

## 1. Batas sistem

Web responsif untuk MLBB, PUBG Mobile, Free Fire, Valorant. Tidak ada integrasi API game, verifikasi rank/ID game, undangan di dalam game, rekomendasi AI, pembayaran, atau voice chat. Data rank diisi pengguna dan ditandai **belum terverifikasi**. Status siap mabar bersifat manual, bukan kehadiran real-time.

```
Browser (Vue 3 + TypeScript + Vite)
  ├─ Vue Router: navigasi; guard UX, bukan otorisasi
  ├─ Pinia: sesi, katalog, filter UI; bukan sumber izin
  └─ Supabase client: Auth + query aman + Realtime + Storage
       ├─ Auth: identitas, email verification, reset password
       ├─ PostgreSQL: migrasi, RLS, view/RPC, transaksi
       ├─ Realtime: perubahan pesan/notifikasi yang berizin
       ├─ Storage: avatar dan bukti laporan di bucket terpisah
       └─ Edge Functions: operasi istimewa yang memerlukan service role,
          throttling terdistribusi, dan penghapusan akun
```

Browser hanya menerima URL dan publishable/anon key. `service_role` tidak pernah dikirim ke browser; Edge Function juga wajib memvalidasi JWT, identitas, peran, objek, dan state. Service role bukan pengganti pemeriksaan akses. Semua waktu kejadian disimpan UTC; slot jadwal disimpan sebagai hari/jam lokal + zona IANA.

## 2. Modul dan batas tanggung jawab

| Modul | Tanggung jawab | Sumber kebenaran |
| --- | --- | --- |
| Auth | Registrasi, verifikasi email, login/logout, reset sesi | Supabase Auth (`auth.users`) |
| Profil | Profil umum, preferensi, jadwal, avatar, pengaturan visibilitas | `profiles`, `availability_slots` |
| Katalog | Game, season, opsi rank/mode/role/region/map/hero/agent | `games`, `game_seasons`, `game_catalog_options` |
| Profil game | Satu profil aktif per game; rank terkait mode; atribut per game | `game_profiles`, relasi opsi |
| Jelajah | Filter server-side, pengecualian blokir, skor deterministik, pagination | RPC pencarian atas tabel ber-RLS |
| Ajakan | Kirim, batalkan, terima, tolak, abaikan hingga kedaluwarsa | `invites` + transaksi RPC |
| Chat | Percakapan 1:1 setelah penerimaan; ID game dibagi eksplisit | `conversations`, `messages`, `game_id_shares` |
| Keselamatan | Blokir, laporan, bukti, moderasi, banding, audit | `blocks`, `reports`, `moderation_actions`, `appeals` |
| Notifikasi | Status ajakan/pesan/moderasi; tidak berisi data sensitif dalam payload | `notifications` |

Susun `src/` per fitur: `app/` (router, provider), `features/{auth,profiles,catalog,search,invites,chat,moderation}/` (views, components, composables, services, schemas), `shared/` (UI, utilitas, types), `lib/supabase/`. Migrasi SQL dan seed katalog di `supabase/migrations/` dan `supabase/seed.sql`; Edge Functions di `supabase/functions/`. Pisahkan DTO publik dari row database: jangan pernah `select('*')` untuk hasil publik.

## 3. Alur kritis

1. **Pendaftaran:** Auth membuat user; trigger/server membuat `profiles` dan `user_roles(user)` secara idempoten. Periksa deklarasi usia 18+ saat registrasi; verifikasi email server-side sebelum ajakan/pesan. Bootstrap admin manual melalui prosedur server-side teraudit.
2. **Onboarding:** Simpan profil umum, preferensi, jadwal, dan profil game. Validasi option ID terhadap game, jenis, season serta status saat penulisan; opsi lama tetap tersimpan sebagai referensi historis.
3. **Pencarian:** RPC menerima game + filter tervalidasi + cursor. Batasi pada profil aktif, game aktif, akun aktif, visibilitas publik, tak ada blokir dua arah. Anon dapat melihat daftar/detail publik; konteks pemirsa diambil dari JWT, bukan parameter `viewer_id`. Dalam kategori multi-select berlaku OR, antarkategori AND. Rank Free Fire wajib memilih konteks BR/CS; rank PUBG Mobile terkait mode. Skor kecocokan deterministik; utamakan data segar dan tie-breaker `(updated_at, id)` stabil. Gunakan keyset cursor yang mengikat filter, sort, dan tie-breaker; perubahan data antarhalaman dapat menggeser hasil, sehingga deduplikasi ID tetap dilakukan di klien. Tetapkan definisi skor/ambang dalam uji sebelum implementasi; jangan klaim aturan rank kompatibel tanpa data resmi.
4. **Ajakan:** RPC transaksional mengunci/menegakkan pasangan pengguna tak berurutan + game untuk satu `pending`, termasuk arah balik; cek verifikasi email, akun, blokir, target aktif, profil game relevan, dan rate limit. `expires_at = created_at + interval '7 days'`; ajakan expired tidak boleh diterima walau job penanda expiry terlambat. Terima ajakan dan buat percakapan tepat sekali dalam satu transaksi; penolakan, pembatalan, expiry memiliki transisi eksplisit.
5. **Chat/berbagi ID:** Hanya kedua peserta percakapan yang diterima dan tidak diblokir boleh membaca/menulis. Setiap kirim diverifikasi di server. ID game hanya dikirim melalui tindakan berbagi eksplisit pemilik setelah penerimaan; tidak otomatis membuka ID kedua pihak. Cabut akses setelah blokir; kebijakan retensi riwayat ditetapkan sebelum rilis.
6. **Moderasi:** Pengguna membuat laporan dengan bukti opsional privat. Admin membaca laporan/bukti terkait saja, mencatat alasan dan audit untuk setiap tindakan, mengirim notifikasi tindakan dan menyediakan jalur banding. Admin tidak memiliki kebijakan baca umum isi chat.

## 4. Otorisasi dan permukaan data

- Aktifkan RLS pada semua tabel yang diekspos ke Supabase client; default deny, `FORCE ROW LEVEL SECURITY` bila sesuai untuk tabel sensitif. Pisahkan `user_roles` dari metadata yang dapat diedit user. Kunci penulisan katalog dan tindakan admin melalui RPC/Edge Function terproteksi.
- `profiles`/`game_profiles`: pemilik dapat mengedit miliknya; pembacaan pengguna lain **hanya** melalui projection/RPC publik eksplisit tanpa email atau `game_id_private`. Hindari kebocoran lewat join, count, error, filter, dan Realtime. Privasi dan blokir diterapkan di database pada semua pembacaan publik, bukan filter setelah data tiba di browser.
- `invites`: hanya dua pihak membaca; hanya pengirim membatalkan, penerima menerima/menolak. `conversations`/`messages`: hanya peserta yang berhak. `reports`: pelapor melihat status miliknya; admin akses kasus sesuai fungsi terproteksi. Bukti laporan memakai signed URL singkat lewat fungsi berotorisasi, tidak URL publik.
- Fungsi `SECURITY DEFINER` harus mempunyai `SET search_path = ''`, nama tabel fully qualified, izin `EXECUTE` minimum, dan pemeriksaan `auth.uid()`/role eksplisit. Jangan percaya `user_id`, role, status, atau email yang dikirim klien sebagai dasar otorisasi.
- Realtime menyiarkan hanya row yang diizinkan RLS; subscription per percakapan peserta, refetch setelah mutasi. Jangan kirim ID game, bukti, isi chat, atau email ke analitik/log/notifikasi umum.

## 5. Operasional, uji, keputusan tertunda

- Lingkungan Supabase development dan production terpisah; migrasi SQL berversi, seed katalog terkontrol, `.env.example`, redirect Auth resmi per lingkungan. Rollback perubahan destruktif via migrasi baru dan backup; jangan menghapus opsi katalog yang direferensikan.
- Batasi ukuran/tipe unggahan di klien **dan** server; hapus EXIF/metadata sensitif, batasi bucket avatar sesuai visibilitas profil, bukti laporan selalu privat. Terapkan rate limit terdistribusi per identitas/IP untuk ajakan, awal chat, laporan, dan auth; log request ID, durasi, status tanpa payload sensitif.
- Target PRD: WCAG 2.2 AA pada alur utama; p75 LCP ≤2,5 detik; p95 pencarian ≤1 detik setelah kapasitas target ditetapkan. Uji RLS/RPC sebagai anon, pemilik, orang lain, admin, akun dibatasi; uji race ajakan berlawanan, expiry, blokir, visibilitas, kebocoran field, pagination, serta rank per mode.
- Sebelum rilis, putuskan penyedia login (email/OAuth), taksonomi katalog berdasar sumber resmi, kapasitas uji beban, retensi chat/laporan, alur banding, mekanisme age assurance dan tinjauan UU PDP. Mockup di `design/`/`desain.md` adalah referensi UI, bukan izin membuka ID game otomatis atau mengganti aturan PRD.
