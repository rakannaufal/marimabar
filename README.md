# Mabar Finder

Vue 3 + TypeScript + Vite + Supabase. `prd.md`, `Rules.md`, `Architecture.md`, dan `Schema.md` menjadi aturan produk. `desain.md` dan 32 `design/*/code.html` adalah rancangan asli; peta layar dan rute di `design-coverage.json`. Data contoh dalam HTML tidak digunakan sebagai data produksi.

## Menjalankan

1. `npm ci`.
2. Buat proyek Supabase **development**. Jalankan migrasi `supabase/migrations/` secara berurutan, lalu katalog `supabase/seed.sql`. Baca `BACKEND.md` untuk bootstrap admin dan izin database.
3. Salin `.env.example` menjadi `.env`; isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` **publishable**, bukan service-role. Jangan commit `.env`.
4. Konfigurasi Supabase Auth: verifikasi email aktif, Site URL origin aplikasi, redirect URL `http://127.0.0.1:5173/auth/callback*` (sesuaikan port/origin aktual, misalnya `5174`) dan origin produksi yang tepat, serta pemulihan kata sandi. Aktifkan provider Google di Supabase Auth dengan OAuth Client ID/Secret dari Google Cloud; daftarkan callback Google `https://<project-ref>.supabase.co/auth/v1/callback` sebagai Authorized redirect URI. Daftarkan origin aplikasi di Authorized JavaScript origins. Jangan simpan Client Secret di Vite. Jalankan migrasi `202609240003_google_adult_declaration.sql` sebelum memakai daftar Google. Jalankan `npm run dev`. Pendaftaran Google memerlukan deklarasi 18+ serta persetujuan kebijakan; akun Google baru yang masuk lewat tombol Masuk diarahkan ke Daftar untuk deklarasi. Ini pernyataan mandiri, bukan verifikasi usia.
5. `npm run typecheck && npm test && npm run build`. Uji akun dewasa terverifikasi, akun admin yang di-bootstrap server-side, profil publik, ajakan, chat, laporan, blokir, dan RLS di proyek Supabase nyata.

Tanpa variabel lingkungan, aplikasi menampilkan status **layanan belum dikonfigurasi**. Tidak ada persona atau data demo; tindakan data memerlukan Supabase.

## Atribut game

Migrasi `202609240004_game_attributes.sql` menambahkan 54 definisi atribut untuk Mobile Legends, PUBG Mobile, Free Fire, dan Valorant; jalankan setelah migrasi 001–003. Katalog opsi lama dan data profil tidak ditimpa. Admin dapat mengubah definisi di **Admin → Atribut Game**; input profil game ada pada **Onboarding langkah 2**, filter berdasarkan atribut muncul di **Cari teman**. Opsi katalog lama tetap terpisah. Nilai statistik/rank diisi pengguna dan **belum diverifikasi**. Daftar hero/karakter/agent dinamis belum tersedia karena belum ada sumber katalog tepercaya; filter tag belum ditampilkan sampai opsinya diisi admin. Rating dari pengguna lain, jumlah mabar berhasil, verifikasi akun game, serta status online/terakhir aktif belum disediakan sebagai filter karena belum ada data tepercaya. Jalankan `node tests/sql/game_attributes_smoke.mjs` untuk memeriksa skema dan perilaku SQL lokal. Akses dan RLS pada Supabase nyata tetap perlu diuji.

## Sebelum produksi

Validasi privasi dan izin RLS memakai instance PostgreSQL/Supabase nyata beserta matriks peran. Pastikan pembatasan permintaan (rate limit), retensi dan penghapusan data, age assurance, kebijakan perlindungan data, izin aset desain, serta proses moderasi ditetapkan. Build lokal dan SQL smoke test bukan verifikasi deployment. Jangan rilis sampai pemeriksaan keamanan, legal, dan alur multiuser selesai.
