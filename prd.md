# PRD — Teman Mabar

**Versi:** 1.0  
**Status:** Draft  
**Platform:** Web responsif  
**Stack:** Vue 3 + TypeScript + Vite, Vue Router, Pinia; Supabase Auth, PostgreSQL, Storage, Realtime, Edge Functions  
**Pasar awal:** Indonesia  
**Game awal:** Mobile Legends: Bang Bang (MLBB), PUBG Mobile, Free Fire, Valorant

## 1. Ringkasan

Teman Mabar membantu pemain menemukan rekan bermain yang cocok berdasarkan game, rank, role, mode, jadwal, dan preferensi komunikasi. Pengguna membuat profil umum, menambahkan akun untuk satu atau lebih game, lalu menelusuri profil pemain lain dengan filter khusus per game. Kontak awal dilakukan melalui permintaan mabar dan chat di dalam aplikasi; identitas akun game hanya dibagikan sesuai pengaturan privasi pengguna.

**Asumsi MVP:** Aplikasi tidak terhubung ke API resmi game. Rank dan statistik diisi pengguna, diberi label **belum terverifikasi**, serta tidak diklaim sebagai data real-time. Aplikasi mempertemukan pemain, bukan menjalankan matchmaking atau mengundang langsung di dalam game.

## 2. Masalah & tujuan

### Masalah
- Sulit mencari rekan dengan rank, role, mode bermain, dan waktu aktif yang cocok.
- Komunitas umum tidak menyediakan filter detail yang berbeda untuk tiap game.
- Berbagi ID game atau kontak publik berisiko spam dan pelecehan.

### Tujuan
1. Pengguna menemukan kandidat relevan dalam beberapa langkah: pilih game, atur filter, lihat profil, kirim ajakan.
2. Profil per game menyediakan atribut yang benar-benar relevan untuk game tersebut.
3. Pengguna dapat mengontrol siapa yang melihat ID game dan siapa yang dapat menghubungi mereka.

### Bukan cakupan MVP
- Sinkronisasi rank/statistik dengan API game; verifikasi kepemilikan akun game.
- Voice chat, pembayaran, turnamen, rekomendasi berbasis AI.
- Klaim kompatibilitas cross-platform/cross-region otomatis tanpa data resmi game.

## 3. Pengguna & skenario

| Persona | Kebutuhan |
| --- | --- |
| Pemain solo | Mencari duo/squad dengan rank dan jam main serupa. |
| Pemain kompetitif | Mencari role pelengkap, komunikasi aktif, dan tujuan push rank. |
| Pemain kasual | Mencari teman yang santai, mode cocok, dan tidak toxic. |

**Alur utama:** Daftar/login → lengkapi profil dasar → tambah profil game → pilih game → terapkan filter → lihat kartu dan detail kandidat → kirim permintaan mabar → penerima terima/tolak → chat → pindah ke game secara manual.

## 4. Ruang lingkup & kebutuhan fungsional

### 4.1 Akun dan profil umum
- Login melalui email atau penyedia identitas yang didukung; verifikasi email sebelum mengirim pesan/permintaan.
- Nama tampilan, foto/avatar, bio singkat, bahasa, zona waktu, preferensi voice chat, gaya bermain (santai/kompetitif), dan jadwal main mingguan.
- Usia minimum **18 tahun untuk MVP**; tampilkan aturan dan lakukan deklarasi usia saat registrasi. Kebijakan serta mekanisme age assurance perlu ditinjau sebelum rilis.
- Satu pengguna dapat memiliki beberapa profil game, maksimal satu profil aktif per game pada MVP.
- Status ketersediaan manual: **Siap mabar / Tidak tersedia**. Jadwal merupakan preferensi, bukan indikator online real-time.

### 4.2 Profil per game
Semua profil game memiliki: nama game, nama dalam game, ID game bila relevan, region/server, rank saat ini, mode favorit, tujuan bermain, ketersediaan, dan waktu pembaruan data. Field yang tidak berlaku untuk game tertentu tidak ditampilkan. Pilihan rank/role/mode menggunakan daftar terstruktur yang dikelola admin agar filter konsisten; perubahan season atau nomenklatur tidak boleh merusak profil lama.

| Game | Atribut tambahan MVP | Filter khusus |
| --- | --- | --- |
| **MLBB** | Rank + divisi/star bila relevan; role utama & sekunder (Tank, Fighter, Assassin, Mage, Marksman, Support); hero favorit; server/ID bila tersedia | Rank, role, hero, mode, server |
| **PUBG Mobile** | Rank + tier; perspektif TPP/FPP; mode Solo/Duo/Squad; preferensi map; role tim (IGL, rusher, support, sniper) | Rank, perspektif, ukuran tim, map, role, region |
| **Free Fire** | Rank BR dan/atau CS secara terpisah; mode Battle Royale/Clash Squad; role tim (rusher, support, sniper, IGL) | Rank sesuai mode, mode, role, region |
| **Valorant** | Rank kompetitif; role Agent (Duelist, Initiator, Controller, Sentinel); agent favorit; preferensi mode; region/shard | Rank, role, agent, mode, region |

**Catatan data:** Nilai rank dan aturan season dikonfigurasi per game. Untuk PUBG Mobile dan Free Fire, rank harus dikaitkan dengan mode yang dipilih agar hasil filter tidak mencampur jenis rank. Region/server wajib cocok saat pengguna mengaktifkan filter kompatibilitas region; jangan mengasumsikan pemain lintas region bisa bermain bersama.

### 4.3 Jelajah dan pencarian
- Beranda menampilkan empat game awal dengan jumlah profil aktif bila tersedia.
- Halaman hasil menampilkan kartu: avatar, nama tampilan, game, rank, role/mode utama, region, bahasa, status siap mabar, dan jadwal ringkas.
- Filter dasar: rank/rentang rank, region/server, bahasa, gaya bermain, preferensi voice chat, status siap mabar, rentang jadwal.
- Filter spesifik mengikuti tabel game; filter yang tidak relevan disembunyikan. Multi-pilihan role/mode memakai logika **OR** di dalam satu kategori; antar-kategori memakai **AND**.
- Urutan default: profil yang paling cocok, lalu paling baru diperbarui. Opsi urut: terbaru, rank terdekat, jadwal terdekat. Definisi skor kecocokan ditampilkan secara sederhana; tidak perlu algoritme AI.
- Pencarian hanya menampilkan profil aktif, tidak diblokir, dan memenuhi aturan privasi. Sediakan keadaan kosong dengan saran melonggarkan filter. Pagination atau infinite scroll wajib mencegah hasil duplikat.
- Pengguna yang belum login boleh melihat daftar dan detail publik; login diperlukan untuk mengirim permintaan.

### 4.4 Detail profil, ajakan, chat
- Detail profil menampilkan atribut game lengkap yang diisi, bio, jadwal, waktu pembaruan, serta label **Data diisi pengguna, belum terverifikasi**.
- Tombol **Ajak mabar** membuka pesan singkat opsional; satu permintaan tertunda per pasangan pengguna dan game.
- Penerima dapat menerima, menolak, atau mengabaikan permintaan. Pengirim dapat membatalkan; permintaan kedaluwarsa setelah 7 hari. Notifikasi dalam aplikasi untuk status ajakan dan pesan baru.
- Chat 1:1 tersedia setelah permintaan diterima. ID game disembunyikan secara default dan dapat dibagikan oleh pemilik setelah ajakan diterima melalui kontrol eksplisit; jangan tampilkan email atau kontak pribadi secara otomatis.
- Pengguna dapat memblokir atau melaporkan akun dari profil, permintaan, maupun chat. Blokir menghentikan pencarian timbal balik, ajakan, dan pesan berikutnya.

### 4.5 Moderasi dan administrasi
- Form laporan: kategori, deskripsi, bukti opsional, dan status tindak lanjut. Kategori minimum: pelecehan, spam, penipuan, impersonasi, konten tidak pantas.
- Admin dapat meninjau laporan, menyembunyikan profil, membatasi akun, dan mencatat alasan serta jejak audit. Pengguna menerima pemberitahuan saat tindakan moderasi diterapkan, dengan jalur banding dasar.
- Rate limit ajakan, chat awal, dan laporan; deteksi duplikasi serta perlindungan spam dasar.
- Admin mengelola katalog game, daftar rank, role, mode, map/agent/hero, dan season tanpa perubahan kode untuk opsi konten; perubahan aturan filter perlu pengujian.

## 5. Navigasi & halaman

1. **Beranda:** pilihan game, cara kerja singkat, masuk/daftar.
2. **Jelajah game:** hasil, filter desktop sebagai sidebar dan mobile sebagai panel, urutan, keadaan kosong.
3. **Detail pemain:** profil umum, data game, jadwal, ajakan, lapor/blokir.
4. **Profil saya:** profil umum, daftar profil game, tambah/edit profil, privasi, ketersediaan.
5. **Ajakan & pesan:** masuk/terkirim, status, chat yang diterima.
6. **Pengaturan:** akun, notifikasi, privasi, blokir, hapus akun.
7. **Admin:** laporan, tindakan moderasi, katalog atribut game.

## 6. Aturan produk dan data

### Entitas inti
- `User`: identitas login, nama tampilan, avatar, bio, bahasa, zona waktu, jadwal, preferensi, status akun.
- `Game`: slug, nama, status aktif, konfigurasi atribut, versi/season.
- `GameProfile`: user, game, IGN, ID game privat, region/server, rank dan konteks mode, role, atribut spesifik, visibilitas, updated_at.
- `Invite`: pengirim, penerima, game, pesan awal, status, created_at, expires_at.
- `Conversation` dan `Message`: hanya setelah ajakan diterima.
- `Block`, `Report`, `ModerationAction`, `Notification`.

### Aturan
- Satu profil aktif per pasangan user–game; satu ajakan tertunda per pasangan pengguna–game.
- Preferensi rank **tidak** otomatis membatasi kelayakan bermain bersama; kecocokan rank diberi label preferensi, kecuali aturan game yang valid dan terkini tersedia.
- Profil yang lama tidak diperbarui (>30 hari) diberi label **Perlu diperbarui** dan diprioritaskan lebih rendah; pengguna tetap bisa mengeditnya.
- Pengguna hanya boleh mengubah profil miliknya; akses chat harus diverifikasi di server untuk setiap permintaan.
- Simpan waktu dalam UTC, tampilkan sesuai zona waktu pengguna. Jadwal berulang menyimpan hari/jam lokal dan zona waktu asal agar perbandingan lintas zona benar.
- Hapus akun mencabut profil dari pencarian dan memproses penghapusan data sesuai kebijakan retensi yang dipublikasikan.

### Peran & hak akses (RBAC)
MVP memiliki **dua peran aplikasi: `user` dan `admin`**. Pengunjung (`anon`) bukan peran tersimpan. Admin tetap dapat memakai fitur pengguna, tetapi tindakan moderasi hanya melalui panel admin. Peran disimpan di tabel terlindungi `user_roles`, bukan metadata yang dapat diubah pengguna; akun baru mendapat `user` secara otomatis. Admin pertama ditetapkan secara manual melalui proses bootstrap server-side, bukan dari form registrasi.

| Aksi | Pengunjung | User | Admin |
| --- | --- | --- | --- |
| Lihat katalog dan profil publik yang aktif | Ya | Ya | Ya |
| Buat/edit profil game milik sendiri | Tidak | Ya | Ya |
| Kirim/kelola ajakan milik sendiri; chat setelah diterima | Tidak | Ya | Ya |
| Blokir dan laporkan akun | Tidak | Ya | Ya |
| Lihat laporan dan isi chat yang bukan miliknya | Tidak | Tidak | Laporan dan bukti terkait saja, sesuai kebijakan moderasi |
| Sembunyikan profil, batasi akun, kelola katalog | Tidak | Tidak | Ya |
| Ubah peran pengguna | Tidak | Tidak | Melalui proses server-side teraudit; bukan edit profil biasa |

Admin tidak memperoleh akses bebas ke percakapan privat melalui UI atau kebijakan baca umum. Akses bukti laporan dibatasi kebutuhan investigasi dan diaudit.

### Arsitektur Vue + Supabase
- **Frontend:** Vue 3 Composition API + TypeScript + Vite; Vue Router untuk halaman/guard navigasi, Pinia untuk sesi dan filter. Komponen formulir per game mengikuti skema katalog terstruktur; validasi juga dilakukan di server. Jangan menyimpan keputusan otorisasi hanya di route guard.
- **Auth:** Supabase Auth untuk registrasi, verifikasi email, login, pemulihan kata sandi, dan logout. `auth.users` terpisah dari `profiles` dan `user_roles`; hapus/nonaktifkan akun ditangani server-side sesuai kebijakan retensi.
- **Database:** Supabase PostgreSQL dengan migrasi SQL berversi. Entitas inti dipetakan ke `profiles`, `games`, `game_catalog_options` (tipe opsi, game, season, urutan, aktif), `game_profiles`, `invites`, `conversations`, `messages`, `blocks`, `reports`, `moderation_actions`, `notifications`, `user_roles`. `game_profiles` memiliki kolom terindeks untuk game, status, region, rank dan mode rank, role utama, waktu pembaruan; atribut khusus tambahan dapat memakai JSONB tervalidasi. Gunakan ID katalog stabil agar pergantian season tidak merusak data lama.
- **Pencarian:** Query/RPC PostgreSQL terpaginasikan, filter kategori AND serta multi-pilihan OR; terapkan pengecualian blokir dua arah, visibilitas, dan status akun di database. Indeks disesuaikan query nyata. Skor kecocokan deterministik; urutkan dengan kunci sekunder stabil agar halaman tidak duplikat.
- **Transaksi terproteksi:** Pembuatan/penerimaan ajakan, pembukaan percakapan, pembagian ID game, pembatasan akun, dan perubahan peran dilakukan melalui RPC/Edge Function dengan pemeriksaan identitas serta state secara atomik. Aturan unik untuk satu ajakan `pending` per pasangan dan game harus ditegakkan di database, termasuk ajakan dari arah berlawanan.
- **Realtime:** Supabase Realtime untuk pesan/notifikasi pada percakapan yang diizinkan; query/refetch menjadi sumber kebenaran setelah mutasi. Jangan membuat channel yang menyiarkan pesan ke nonpeserta.
- **Storage:** Bucket avatar dan bukti laporan dipisah; unggahan dibatasi jenis/ukuran, hak baca, dan metadata sensitif. Bukti laporan tidak berada di bucket publik.
- **Secrets & lingkungan:** Frontend hanya memakai Supabase URL dan publishable/anon key dari variabel `VITE_`; `service_role` hanya di server/Edge Function. Pisahkan proyek development dan production; sediakan `.env.example`, migrasi, instruksi bootstrap admin, serta redirect URL Auth saat implementasi.

### Kebijakan akses data (RLS)
Aktifkan RLS pada seluruh tabel yang diakses klien, default-deny. `profiles` dan `game_profiles` hanya dapat ditulis pemilik; bacaan publik memakai view/RPC khusus yang mengecualikan email, ID game privat, akun tersembunyi, serta relasi blokir. `invites` hanya dapat dibaca kedua pihak dan dimutasi sesuai status oleh pihak berwenang. `conversations`/`messages` hanya dapat dibaca peserta setelah ajakan diterima; pengirim pesan harus peserta aktif dan tidak diblokir. `reports` hanya dapat dibuat pelapor dan dilihat pelapor untuk statusnya atau admin untuk penanganan; `moderation_actions` dan perubahan katalog hanya admin. `user_roles` tidak dapat ditulis klien. Fungsi hak istimewa memakai `SECURITY DEFINER` secara terbatas, `search_path` eksplisit, izin eksekusi sempit, dan audit perubahan admin. Uji akses sebagai pengunjung, pemilik, pengguna lain, admin, serta akun dibatasi.

## 7. Kebutuhan nonfungsional

- **Responsif:** desktop dan ponsel; filter serta ajakan dapat digunakan dengan sentuhan dan keyboard.
- **Aksesibilitas:** target WCAG 2.2 AA untuk alur utama; label form, kontras, fokus terlihat, pesan kesalahan jelas.
- **Performa:** target p75 LCP ≤2,5 detik dan respons pencarian p95 ≤1 detik pada beban target yang ditetapkan saat uji; hasil dipaginasi.
- **Keamanan:** HTTPS, validasi server, otorisasi per objek, sanitasi konten pengguna, rate limit, proteksi sesi, audit admin, dan penghapusan metadata sensitif dari unggahan.
- **Privasi:** minimisasi data; ID game privat secara default; tidak menampilkan email; kontrol visibilitas profil; kebijakan privasi dan retensi sesuai regulasi yang berlaku di Indonesia, termasuk UU PDP, ditinjau sebelum rilis.
- **Observabilitas:** log kesalahan tanpa isi chat/ID game, metrik pencarian, ajakan, laporan, dan latensi.

## 8. Metrik keberhasilan

| Metrik | Definisi | Target awal untuk divalidasi |
| --- | --- | --- |
| Aktivasi | Pendaftar yang melengkapi ≥1 profil game dalam 7 hari | ≥50% |
| Pencarian berhasil | Sesi pencarian yang membuka ≥1 detail profil | ≥40% |
| Konversi ajakan | Sesi pencarian yang mengirim ≥1 ajakan | ≥15% |
| Ajakan diterima | Ajakan yang diterima / ajakan terkirim yang sudah selesai | ≥25% |
| Keselamatan | Laporan valid per 1.000 percakapan | Dipantau; tanpa target yang mendorong under-reporting |

Target merupakan hipotesis, bukan hasil riset. Ukur per game dan perangkat. Jangan mengirim isi chat, ID game, atau data pribadi ke analitik.

## 9. Kriteria penerimaan MVP

1. Pengguna dapat membuat akun, melengkapi profil umum, dan menambah profil untuk keempat game.
2. Setiap game menampilkan atribut serta filter khusus sebagaimana tabel; rank Free Fire BR/CS dan PUBG Mobile dipisahkan sesuai mode.
3. Kombinasi filter menghasilkan hanya profil yang memenuhi seluruh kategori pilihan, tanpa profil diblokir atau nonaktif.
4. Pengguna dapat melihat profil lengkap, mengirim satu ajakan tertunda per pasangan dan game, menerima/menolak, lalu chat setelah diterima.
5. ID game dan email tidak terlihat oleh pengunjung/pengguna lain tanpa tindakan berbagi eksplisit.
6. Blokir menghentikan pencarian, ajakan, dan pesan dua arah; laporan masuk ke antrean admin.
7. Alur utama lulus pengujian pada lebar layar ponsel dan desktop, termasuk keyboard serta keadaan loading/error/kosong.
8. Hak akses diuji melalui RLS/RPC: pengunjung, pemilik, pengguna lain, admin, dan akun dibatasi; pengguna tidak dapat mengedit profil orang lain, membaca chat yang bukan miliknya, atau mengakses panel admin.
9. Vue SPA berjalan dengan Supabase Auth dan skema migrasi; alur register, pemulihan kata sandi, sesi, logout, dan akses admin diuji pada proyek Supabase pengujian.
10. Admin dapat memperbarui katalog atribut per game dan menindak laporan dengan alasan serta audit; perubahan season tidak menghapus nilai historis profil.
11. Pencarian terpaginasikan memakai filter spesifik game dan pengecualian blokir dua arah; hasil tidak memuat ID game privat, email, atau profil tersembunyi.

## 10. Tahapan peluncuran

- **MVP:** profil empat game, katalog atribut terstruktur, pencarian/filter, ajakan, chat, blokir/lapor, moderasi dasar.
- **Setelah MVP:** verifikasi akun game jika integrasi resmi tersedia, indikator online dengan persetujuan, rekomendasi kecocokan, party/grup, notifikasi push, game tambahan berdasarkan permintaan.

## 11. Keputusan terbuka

- Nama merek dan domain final.
- Metode login yang dipilih (email saja atau ditambah OAuth).
- Apakah katalog awal mencakup PUBG Mobile saja, bukan PUBG PC; PRD ini mengasumsikan **PUBG Mobile**.
- Taksonomi rank, server, map, hero, dan agent sesuai season saat implementasi; perlu validasi terhadap sumber resmi masing-masing game.
- Kebijakan retensi chat/laporan dan proses banding moderasi final; tinjauan hukum sebelum rilis.
- Kapasitas target pengguna serentak untuk menetapkan uji beban dan SLA.
