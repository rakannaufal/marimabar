# Rules — Teman Mabar

**Berlaku untuk:** implementasi, migrasi, UI, pengujian, dan review MVP. Urutan acuan: `prd.md` untuk kebutuhan/privasi → `Architecture.md` untuk pembagian sistem → `Schema.d` untuk kontrak data → `desain.md` dan `design/` untuk referensi visual. Konflik harus dicatat dan diputuskan; jangan diam-diam menyalin perilaku mockup yang bertentangan dengan PRD.

## Aturan produk wajib

1. Empat game awal: MLBB, PUBG Mobile, Free Fire, Valorant. Rank/statistik diisi pengguna: selalu beri label **Data diisi pengguna, belum terverifikasi**; jangan tampilkan sebagai live/terverifikasi.
2. Usia minimal 18 tahun untuk MVP; deklarasi usia saat registrasi. Mekanisme age assurance dan dasar hukum ditinjau sebelum rilis. Hanya email terverifikasi boleh mengirim ajakan/pesan.
3. Satu profil game aktif per user–game. Status `Siap mabar` manual; jadwal bukan indikator online. Profil >30 hari ditandai **Perlu diperbarui** dan diturunkan prioritasnya, bukan otomatis dihapus.
4. Filter pilihan dalam satu kategori memakai OR; antarkategori AND. Rank PUBG Mobile terikat mode; Free Fire BR dan CS terpisah. Kecocokan rank adalah preferensi, bukan klaim kelayakan bermain. Kompatibilitas region hanya saat filter diaktifkan dan harus cocok pada data eksplisit.
5. Pengunjung boleh melihat data publik; login diperlukan untuk ajakan. Tidak boleh menampilkan profil tersembunyi, akun dibatasi, atau pihak yang saling blokir. Pagination deterministik, tanpa item duplikat.
6. Satu ajakan `pending` per pasangan user tak berurutan dan game, termasuk arah sebaliknya; kedaluwarsa 7 hari. Chat hanya setelah ajakan diterima. ID game privat secara default dan dibagikan **oleh pemilik secara eksplisit** setelah diterima; tidak otomatis terbuka saat menerima ajakan. Email tidak ditampilkan dalam profil publik.
7. Blokir berlaku dua arah untuk jelajah, ajakan, dan pesan berikutnya. Laporan minimal kategori pelecehan, spam, penipuan, impersonasi, konten tidak pantas. Tindakan admin butuh alasan, audit, pemberitahuan pengguna, jalur banding.

## Aturan keamanan/data

- Semua input dan katalog divalidasi di server; validasi frontend hanya untuk UX. Gunakan query terparameterisasi; tidak menyusun SQL dari input user. Cek izin per objek dan transisi state pada tiap mutasi. Route guard dan tombol tersembunyi bukan kontrol keamanan.
- Semua tabel yang terpapar client memakai RLS default-deny; uji dengan anon, pemilik, pengguna lain, admin, akun dibatasi. Baca publik melalui projection/RPC allowlist; larang `select('*')` pada permukaan publik. `user_roles` tidak boleh diubah dari klien; bootstrap/perubahan admin server-side dan teraudit.
- Privasi, blokir, dan status akun difilter di database termasuk pencarian, detail, dan count. Jangan mengekspos ID game privat lewat response, Realtime, log, error, analytics, atau metadata Storage. Admin tidak bebas membaca chat privat; bukti hanya untuk kasus relevan.
- `service_role` dan secret hanya di server/Edge Function, tidak di `VITE_` atau bundle. Gunakan konfigurasi lingkungan terpisah; jangan commit `.env` nyata. Session/Auth mengikuti SDK Supabase; lindungi aplikasi dari XSS, CSRF pada jalur berbasis cookie, penyalahgunaan redirect, dan brute-force. Jangan membuat token auth kustom tanpa kebutuhan teruji.
- Semua waktu event UTC; jadwal berulang mempertahankan hari/jam lokal dan zona IANA. Pilihan katalog menggunakan ID stabil; perubahan season menonaktifkan opsi lama, bukan menghapus referensi historis. Atribut khusus JSONB memakai allowlist/validasi skema dan tidak menjadi tempat menyimpan secret.
- Unggahan memeriksa tipe sebenarnya, ukuran, ekstensi, hak akses, dan metadata; bukti laporan privat. Rate limit terdistribusi untuk auth, ajakan, pesan awal, laporan; batas angka dikonfigurasi dan diuji, bukan dikarang sebagai janji produk. Hapus akun dan retensi data sesuai kebijakan final yang dipublikasikan.

## Aturan implementasi

- Vue 3 Composition API + TypeScript + Vite, Vue Router, Pinia, Supabase. Fitur dipisah dari shared UI; state server diambil ulang setelah mutasi/Realtime, jangan anggap payload Realtime sumber kebenaran. Hindari `any`, logika bisnis di komponen besar, mutasi state tak terkendali, kode duplikat per game.
- Perubahan database lewat migrasi berversi; constraint/indeks/RLS diuji sebelum UI bergantung padanya. Operasi multi-row yang menuntut konsistensi memakai satu transaksi RPC/Edge Function, bukan beberapa panggilan browser. Perubahan skema harus menyertakan pembaruan `Schema.d`, tipe TS, uji akses, dan seed bila perlu.
- API/RPC paginasi dan response eksplisit; validasi input, status error aman, idempotensi untuk retry. Urutan pencarian harus stabil dengan tie-breaker ID. Jangan mengasumsikan integrasi resmi game, realtime presence, win rate tepercaya, atau fitur di luar PRD dari mockup.
- Setiap perubahan fitur wajib diuji unit untuk aturan bisnis, integrasi RLS/RPC untuk izin/transaksi, dan alur browser pada mobile/desktop (loading/error/empty, keyboard). Minimal regresi: ajakan dua arah serentak, blokir, email belum terverifikasi, rank per mode, ID game privat, akun dibatasi, pagination.
- Aksesibilitas target WCAG 2.2 AA: label, fokus terlihat, kontras, navigasi keyboard, error terbaca. Pantau LCP dan latensi pencarian menurut target PRD setelah uji beban yang relevan.

## Aturan UI

- Gunakan `desain.md`/`design/` sebagai referensi visual dengan hierarki bersih dan navigasi jelas; hindari tampilan generik/berlebihan. Token dark hangat `#14141C`, surface `#1E1E29`, teks `#F5F3EE`, aksen lime `#C8FF4D` dan violet `#8B7CFF`; maksimal dua aksen per layar.
- Tidak ada emoji dekoratif, gradasi/glow radial, eyebrow ALL CAPS berulang, headline dua warna, panah di akhir CTA, atau animasi massal. Ikon konsisten; status wajib teks, bukan warna saja. Hormati `prefers-reduced-motion`.
- Mockup berisi data contoh serta beberapa perilaku yang tidak sah: angka pengguna/testimoni/win rate jangan ditampilkan sebagai fakta tanpa data; titik online bukan status real-time; ID game tidak otomatis muncul setelah ajakan diterima; tombol lapor tidak menjanjikan SLA 1×24 jam sebelum ditetapkan. Halaman pencarian dan detail publik tetap dapat diakses guest meski peta route di `desain.md` menandai User.

## Definisi selesai

Fitur selesai bila cocok dengan PRD, lint/typecheck/test/build lulus, migrasi dan RLS teruji di proyek pengujian, tidak ada kebocoran data privat, UI responsif/aksesibel, serta perubahan kontrak terdokumentasi. Dokumen ini menetapkan aturan; keberhasilan pengujian belum boleh diklaim sebelum kode dan lingkungan benar-benar ada.
