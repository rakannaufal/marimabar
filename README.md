# Mabar Finder

Vue 3 + TypeScript + Vite + Supabase. Implementasi mengikuti `prd.md`, `Architecture.md`, `Rules.md`, `Schema.md`; `desain.md` dan seluruh `design/*/code.html` merupakan **desain asli**, bukan inspirasi opsional. Inventaris setiap halaman dan rute: `design-coverage.json`. Perilaku, privasi, dan angka harus tetap sesuai PRD; HTML Stitch memuat data contoh, bukan otorisasi produksi.

## Demo lokal tanpa Supabase

`npm install && npm run dev` tanpa `.env`. Banner **MODE DEMO — DATA SINTETIS** selalu terlihat; pilih persona Naya/Bima (pemain) atau Rani (admin) di banner, tanpa kata sandi. Coba cari/filter pemain, ubah profil sendiri, kirim/terima/tolak ajakan, buka chat, kirim pesan, bagikan ID game secara eksplisit, atau tambah opsi katalog/moderasi sebagai admin. Data demo disimpan hanya di `localStorage` browser pada key `mabar-finder.synthetic-demo.v1`; persona di `mabar-finder.synthetic-demo.persona.v1`. Hapus kedua key untuk reset. Data tersebut contoh sintetis, bukan akun atau data produksi; tidak dikirim ke Supabase. ID game privat tidak tampil di pencarian dan hanya dibaca peserta chat setelah dibagikan.

## Menjalankan dengan Supabase

1. `npm install`
2. Buat proyek Supabase development. Jalankan seluruh migrasi di `supabase/migrations/` berurutan; isi katalog dari `supabase/seed.sql` jika tersedia.
3. Salin `.env.example` ke `.env`, isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` (publishable). **Jangan masukkan `service_role` ke Vite.**
4. Konfigurasi Supabase Auth Site URL `http://127.0.0.1:5173` dan redirect yang diizinkan; verifikasi email aktif.
5. `npm run dev`. Uji dengan dua akun beremail terverifikasi; admin harus dibootstrap secara server-side sesuai `BACKEND.md`.

`npm run build`, `npm test`, `npm run typecheck`. Tanpa kredensial, aplikasi menjalankan demo sintetis lokal terpisah; dengan kredensial valid, tetap memakai Supabase. Migrasi/RLS Auth dan alur multiuser harus diuji di proyek Supabase nyata sebelum rilis. Lihat `BACKEND.md` untuk prasyarat khusus backend.

## Batasan rilis

Kebijakan retensi, age assurance, tinjauan UU PDP, taksonomi rank/season, batas rate limit, dan uji beban belum diputuskan di PRD. Jangan promosikan ke production sebelum keputusan dan uji keamanan/akses selesai.
