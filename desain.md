# Desain & Prompt Google Stitch
## Platform Pencari Teman Mabar

Dokumen ini berisi **design plan** (token system) dan **prompt siap-pakai untuk Google Stitch**, per halaman — versi **v2: Ceria & Ramah**, terinspirasi dari platform gaming seperti Medal.tv. Tipografi tebal membulat, satu warna aksen cerah dipakai berani, tombol besar berbentuk pil, sudut membulat lembut, dan foto/capture in-game sebagai elemen hidup di layar.

---

## 0. Design Plan (Token System) — "Ceria & Ramah"

### Konsep Besar
Bukan "dossier klub kompetitif yang kaku", tapi **"clubhouse energik"** — tetap terasa seperti komunitas gaming yang solid dan bisa dipercaya, tapi hangat, hidup, dan ramah disapa. Rasanya seperti membuka aplikasi teman nongkrong sesama gamer, bukan dokumen keanggotaan formal.

### Warna (dark base, hangat & hidup)
| Token | Hex | Peran |
|---|---|---|
| `base-ink` | `#14141C` | Background utama, dark tapi hangat |
| `surface` | `#1E1E29` | Permukaan kartu/panel |
| `accent-lime` | `#C8FF4D` | Warna aksen utama — dipakai **berani & luas**: tombol CTA, angka statistik besar, ikon aktif, highlight |
| `accent-violet` | `#8B7CFF` | Warna aksen kedua — avatar ring, badge rank, elemen sosial/personal |
| `paper` | `#F5F3EE` | Warna teks utama di atas dark background |
| `signal-teal` | `#4ADE80` | Status positif (online, diterima) |
| `alert-coral` | `#FF6B5E` | Status negatif (ditolak, laporan, suspend) |

**Tidak ada gradasi dalam bentuk apa pun** — termasuk radial/linear glow di background, tombol, badge, maupun overlay di atas foto hero. Jika foto perlu overlay agar teks terbaca, pakai **lapisan warna flat semi-transparan tunggal** (contoh: `base-ink` 70% opacity di atas foto), bukan gradasi gelap→transparan. "Glow" pada tombol/kartu aktif harus berupa **soft shadow satu warna** (box-shadow blur, tanpa blend dua warna), bukan radial gradient bercahaya. Maksimal 2 warna aksen sekaligus per layar (lime + violet).

### Tipografi
- **Display/Headline** — sans **tebal & membulat**: `Baloo 2`, `Plus Jakarta Sans ExtraBold`, atau `Poppins SemiBold/Bold`. Dipakai untuk judul halaman, hero, dan **angka statistik besar**.
- **Body/UI** — `DM Sans` atau `Inter` reguler/medium.
- **Angka & data** — font display yang sama (bold, besar), **bukan monospace** — angka ditulis besar dan tebal seperti judul.

### Layout & Komponen
- Sudut membulat generous: 16–24px pada kartu, **tombol CTA berbentuk pil penuh**.
- **Shadow lembut satu warna diperbolehkan** untuk elevasi (soft shadow blur warna accent-lime di sekeliling elemen yang disorot — bukan glow gradasi/radial).
- **Avatar bulat** (bukan kotak).
- Hero section boleh memakai foto/capture in-game full-bleed dengan **lapisan warna flat semi-transparan** (bukan gradasi) agar teks tetap terbaca.
- Badge rank sebagai **pill rounded** warna accent-violet + ikon garis sederhana (bukan emoji).
- Micro-interaction: tombol & kartu boleh sedikit scale-up atau menampilkan shadow lebih tegas saat hover — bukan efek glow warna-warni.
- Ikon berupa **ilustrasi/line-icon custom yang membulat**, bukan karakter emoji Unicode (⚡🎯🚀✅ dan sejenisnya tidak boleh muncul di badge, tombol, atau teks mana pun). Maskot boleh dipakai sebagai satu elemen ilustrasi konsisten di titik-titik tertentu, bukan ikon berulang di setiap baris.
- Copy/nada tulisan santai dan hangat, seperti bicara ke teman — tapi tanpa emoji tempel di akhir kalimat.

### Larangan Tegas (Anti AI-Slop — mengikuti prinsip frontend-design/taste skill)
- **Tanpa emoji** di mana pun: bukan di eyebrow badge, bukan di tombol, bukan di daftar fitur, bukan di copy. Ganti dengan ikon garis sederhana custom atau tanpa ikon sama sekali.
- **Tanpa gradasi** dalam bentuk apa pun — background, tombol, badge, overlay foto, maupun glow. Semua warna solid/flat.
- **Tanpa eyebrow ALL CAPS** di atas judul (contoh yang harus dihindari: "TEMAN MABAR TANPA DRAMA TOXIC", "3 LANGKAH MUDAH", "LOBI SELALU RAMAI") — kalau butuh label kategori, tulis sentence case dan hanya jika benar-benar perlu, jangan taruh di atas *setiap* judul.
- **Tanpa menonjolkan satu kata/frasa berbeda warna atau garis bawah bergelombang di dalam headline** (contoh yang harus dihindari: kata "bukan cuma" diberi warna lime + garis bawah bergelombang di tengah kalimat) — ini pola generik AI, biarkan headline satu warna dan satu berat font, atau ubah struktur kalimatnya bila perlu penekanan.
- **Tanpa tanda panah "→" ditempel di akhir teks tombol/link** (contoh yang harus dihindari: "Mulai Cari Teman Mabar →").
- **Tanpa metadata digabung titik tengah** ("A · B · C") — pakai spasi atau garis "|".
- **Tanpa label "WORD — fragmen"** dengan em dash.
- Nomor urut (01/02/03) **hanya** untuk konten yang memang berurutan (proses/step), tidak untuk dekorasi elemen lain.
- Motion dibatasi satu momen yang disengaja per halaman, bukan fade-slide-up di setiap section atau hover-transition di setiap kartu.
- Desain harus terasa spesifik untuk platform pencari teman mabar (istilah, alur, dan visual dari dunia gaming Indonesia) — bukan template SaaS generik yang kebetulan diberi warna gelap+lime.
- Maksimal 2 warna aksen sekaligus per layar, jangan campur font membulat dengan font tajam/serif di halaman yang sama.

> **Catatan kalibrasi warna:** kombinasi dark background + satu warna aksen cerah (lime) adalah salah satu pola paling umum dihasilkan AI. Supaya tidak terasa generik, base-ink harus terasa hangat (bukan hitam pekat `#000`/`#0B0B0B`), dan detail seperti tekstur, foto capture in-game asli, serta tipografi rounded yang konsisten harus jadi pembeda — bukan cuma warna gelap + neon yang ditempel begitu saja.

---

## 1. Master Prompt v2 (Global Style — tempel di awal project Stitch)

```
Rancang ulang design system untuk platform web "Mabar Finder" — platform pencari 
teman bermain game (matchmaking sosial). Nuansa visual yang diinginkan: CERIA, 
HANGAT, dan USER-FRIENDLY — terinspirasi dari platform gaming seperti Medal.tv: 
tipografi tebal membulat, satu warna aksen cerah dipakai berani, tombol besar 
berbentuk pil, sudut membulat lembut, foto/capture in-game sebagai elemen hidup 
di hero section. BUKAN lagi gaya dokumen/dossier formal yang kaku dan datar.

Palet warna (dark base tetap dipakai, tapi hangat & hidup):
- Base Ink #14141C untuk background utama
- Surface #1E1E29 untuk permukaan kartu
- Accent Lime #C8FF4D sebagai warna aksen utama, dipakai BERANI di tombol CTA, 
  angka statistik besar, ikon aktif, dan highlight — jangan terlalu dibatasi
- Accent Violet #8B7CFF sebagai warna aksen kedua, untuk avatar ring, badge 
  rank, dan elemen sosial/personal
- Paper #F5F3EE untuk teks utama di atas dark background
- Signal Teal #4ADE80 untuk status positif, Alert Coral #FF6B5E untuk status 
  negatif

Tipografi: judul dan angka besar memakai sans-serif TEBAL dan MEMBULAT (seperti 
Baloo 2, Plus Jakarta Sans ExtraBold, atau Poppins Bold) — bukan serif editorial. 
Body dan UI memakai sans-serif humanis bersih (seperti DM Sans/Inter).

Layout: sudut membulat generous (16-24px) pada kartu, tombol CTA berbentuk pil 
penuh, shadow lembut SATU WARNA diperbolehkan untuk elevasi (soft shadow blur 
accent-lime di sekitar tombol/kartu aktif, BUKAN glow radial/gradasi), avatar 
berbentuk BULAT. Hero section boleh menampilkan foto/capture in-game full-bleed 
dengan lapisan warna flat semi-transparan tunggal di atasnya agar teks tetap 
terbaca (BUKAN overlay gradasi gelap-ke-transparan). Badge rank berbentuk pill 
rounded warna accent-violet dengan ikon garis sederhana, bukan kotak tegas dan 
bukan emoji.

Nada tulisan (copy) santai dan hangat, seperti bicara ke teman, bukan bahasa 
formal/korporat — tapi TANPA emoji ditempel di badge, tombol, list, atau akhir 
kalimat mana pun. Ikon berupa line-icon/ilustrasi custom yang membulat, boleh 
ada satu elemen maskot sederhana yang konsisten di seluruh situs, tapi jangan 
diulang sebagai ikon di setiap baris/kartu.

LARANGAN TEGAS (ikuti prinsip desain yang distinctive, bukan default generatif):
- TIDAK ADA gradasi warna dalam bentuk apa pun — background, tombol, badge, 
  overlay foto, atau glow. Semua warna harus solid/flat.
- TIDAK ADA emoji Unicode di mana pun (⚡🎯🚀✅ dan sejenisnya dilarang total).
- TIDAK ADA eyebrow label ALL CAPS di atas judul (seperti "3 LANGKAH MUDAH" 
  atau "TEMAN MABAR TANPA DRAMA TOXIC") — jangan taruh label kategori di atas 
  setiap heading.
- TIDAK ADA satu kata/frasa dalam headline yang diberi warna berbeda atau garis 
  bawah bergelombang sebagai penekanan — biarkan headline konsisten satu warna 
  dan satu berat font.
- TIDAK ADA tanda panah "→" ditempel di akhir teks tombol atau link.
- TIDAK ADA metadata yang digabung dengan titik tengah "·" atau label bergaya 
  "WORD — fragmen" dengan em dash.
- Nomor urut 01/02/03 hanya dipakai untuk konten yang benar-benar berurutan 
  (proses/step), tidak untuk dekorasi bagian lain.
- Motion dibatasi satu momen yang disengaja per halaman, jangan animasi 
  fade-slide-up di setiap section atau hover-transition seragam di semua kartu.
- Kombinasi dark background + aksen lime adalah pola umum hasil AI — supaya 
  tidak terasa generik/templated, base-ink harus terasa hangat (bukan hitam 
  pekat #000/#0B0B0B), dan detail harus spesifik untuk dunia gaming Indonesia 
  (istilah rank, role, dan alur mabar yang nyata), bukan sekadar template SaaS 
  gelap yang ditempeli warna neon.

Tetap hindari juga: foto stok generik "gamer headset RGB", lebih dari 2 warna 
aksen sekaligus dalam satu layar, dan campuran font membulat dengan font tajam/
serif dalam halaman yang sama.
```

---

## 2. Halaman: Landing Page

**Tujuan halaman:** memperkenalkan platform ke pengunjung baru (guest), mendorong daftar/login.

**Prompt Stitch:**
```
Buat Landing Page untuk "Mabar Finder" dengan gaya ceria & hangat (ikuti global 
style v2: base ink #14141C, accent lime #C8FF4D dipakai berani, accent violet 
#8B7CFF untuk elemen sosial, sudut membulat 16-24px, glow lembut diperbolehkan, 
font rounded bold seperti Baloo 2/Plus Jakarta Sans untuk judul, Inter/DM Sans 
untuk body).

Struktur halaman dari atas ke bawah:

1. Navigation bar: logo teks "Mabar Finder" (rounded bold, boleh ada ikon 
   maskot kecil di sebelahnya), menu (Cari Teman, Game, Tentang), tombol 
   "Masuk" (outline pill) dan "Daftar" (solid lime pill, sedikit glow) di 
   kanan. Border bawah tipis hangat, boleh sedikit shadow lembut.

2. Hero section — layout dua kolom asimetris. Kolom kiri (55%) berisi 
   headline besar rounded bold ("Temukan rekan satu tim, bukan cuma satu 
   server"), satu paragraf pendek hangat, dan tombol CTA pill solid lime 
   dengan glow "Mulai Cari Teman Mabar". Kolom kanan (45%) menampilkan foto 
   in-game/capture gameplay full-bleed dengan overlay gradasi gelap agar 
   teks tetap kontras, dan di atasnya melayang satu kartu "profil pemain" 
   rounded dengan avatar bulat, badge rank pill violet, dan glow tipis di 
   tepi kartu.

3. Seksi "Game Populer" — grid 4 kolom (Mobile Legends, PUBG Mobile, Free 
   Fire, Valorant). Setiap item berupa kartu rounded (radius besar) dengan 
   ikon game berwarna (bukan monokrom), nama game (rounded bold sedang), dan 
   jumlah pemain aktif dalam angka besar tebal. Saat hover: kartu sedikit 
   membesar (scale) dan memancarkan glow lime tipis di tepinya.

4. Seksi "Cara Kerja" — penomoran 01/02/03 besar rounded bold di kiri tiap 
   baris (karena memang berurutan): (01) Buat profil game, (02) Pilih game & 
   atur filter rank/role, (03) Kirim request mabar. Angka boleh diwarnai 
   accent-lime. Baris dipisah garis tipis hangat, bukan kartu kotak kaku.

5. Seksi testimoni singkat — satu kutipan besar rounded bold, avatar bulat 
   dengan ring accent-violet di sampingnya, nama & rank penulis dalam teks 
   kecil di bawahnya.

6. Footer hangat gelap: kolom link (Produk, Game, Bantuan, Kebijakan), logo 
   & maskot kecil, dipisah garis tipis dari konten di atasnya.

Jangan gunakan foto stok generik "gamer headset RGB" — gunakan capture 
gameplay asli atau ilustrasi custom. Boleh tambahkan elemen ilustrasi maskot 
sederhana yang konsisten dengan brand di beberapa titik halaman.
```

**Prompt Revisi Cepat** (tempel di kotak chat Stitch "Apa yang ingin Anda ubah atau buat?" untuk memperbaiki Landing Page yang sudah digenerate sebelumnya):
```
Perbaiki Landing Page ini, hapus semua pola berikut tanpa mengubah struktur 
layout yang sudah ada:
1. Hapus semua ikon emoji (⚡🎯🚀✅ dan sejenisnya) dari badge eyebrow, tombol, 
   dan tag seperti "Cepat 30 Detik", "Filter Akurat", "Langsung Gas" — ganti 
   jadi teks polos tanpa ikon, atau line-icon custom tipis bila perlu.
2. Hapus semua gradasi/glow warna-warni di background hero dan di sekitar 
   tombol/kartu — ganti jadi warna solid flat, shadow boleh tetap ada tapi 
   harus satu warna saja (soft shadow blur, bukan radial glow).
3. Hapus badge eyebrow ALL CAPS di atas judul ("TEMAN MABAR TANPA DRAMA 
   TOXIC", "3 LANGKAH MUDAH", "LOBI SELALU RAMAI") — hilangkan badge-badge 
   ini, biarkan judul section berdiri sendiri tanpa label di atasnya.
4. Pada headline hero, hapus warna berbeda dan garis bawah bergelombang pada 
   frasa "bukan cuma" — buat seluruh headline satu warna dan satu berat font.
5. Hapus tanda panah "→" pada tombol "Mulai Cari Teman Mabar".
6. Pertahankan warna dasar dark (base-ink hangat) dan aksen lime/violet, 
   tipografi rounded bold, sudut membulat, dan avatar bulat — itu semua tetap 
   dipakai, yang dihilangkan hanya emoji, gradasi/glow, eyebrow caps, dan 
   arrow di tombol.
```

---

## 3. Halaman: Login & Register

**Prompt Stitch:**
```
Buat halaman Login dan Register (tab switch di satu layout) untuk "Mabar 
Finder", gaya ceria & hangat (global style v2).

Layout: split-screen asimetris.
- Panel kiri (55%): foto/capture in-game full-bleed dengan overlay gradasi 
  gelap, di atasnya kutipan singkat komunitas dalam font rounded bold besar 
  dan satu kartu profil pemain contoh (rounded, avatar bulat, badge pill 
  violet, glow tipis) melayang di atas foto.
- Panel kanan (45%): background base-ink, berisi form.

Form berisi:
- Judul rounded bold "Masuk ke akunmu, yuk!" / "Buat akun baru, gampang kok" 
  (toggle via dua tab pill kecil di atas form, tab aktif solid lime).
- Input email & password dengan border rounded (radius 12-16px), fokus 
  berubah jadi border/glow accent-lime tipis.
- Toggle show/hide password teks sederhana "Tampilkan".
- Untuk Register tambahan: input Nickname dan dropdown "Kota" rounded.
- Tombol utama pill solid lime penuh lebar dengan glow lembut: "Masuk" / 
  "Buat Akun Sekarang".
- Divider dengan teks "atau" di tengah, lalu tombol outline pill "Lanjutkan 
  dengan Google" dengan logo Google.
- Link teks hangat di bawah: "Belum punya akun? Yuk daftar di sini" (warna 
  accent-lime saat hover).

Kartu form boleh punya sedikit shadow/glow untuk kesan mengambang lembut, 
tidak perlu flat menyatu seperti versi sebelumnya.
```

---

## 4. Halaman: Beranda / Dashboard User

**Prompt Stitch:**
```
Buat halaman Dashboard untuk user yang sudah login, gaya clubhouse ceria 
(global style v2 tetap berlaku).

Layout: sidebar kiri tetap (fixed) + konten utama kanan.

Sidebar kiri (dark panel, lebar tetap ~240px, radius pada elemen dalamnya):
- Logo + maskot kecil di atas.
- Avatar bulat user dengan ring accent-violet + nickname + toggle pill kecil 
  "Sedang mencari mabar" (switch rounded lime saat aktif).
- Menu navigasi vertikal, item aktif ditandai pill background accent-lime 
  redup + teks lebih terang, bukan hanya border-left tipis.
- Di bagian bawah sidebar: link "Keluar" dengan ikon rounded kecil.

Konten utama:
1. Header baris atas: judul halaman "Beranda, [Nickname]!" (rounded bold, 
   sapaan hangat) di kiri, dan badge bulat kecil accent-lime berisi angka 
   jumlah request masuk di kanan (bukan lonceng notifikasi generik).

2. Seksi "Profil Game Kamu" — daftar horizontal scroll berisi kartu rounded 
   per game yang sudah diisi user, tiap kartu menampilkan ikon game berwarna, 
   badge rank pill violet, dan role singkat. Ada satu kartu tambahan 
   bertuliskan "+ Tambah Profil Game" dengan border putus-putus rounded dan 
   ikon plus besar accent-lime.

3. Seksi "Rekomendasi Teman Mabar" — list vertikal kartu rounded berisi 4-5 
   profil pemain lain yang cocok. Setiap kartu: avatar bulat kiri dengan ring 
   violet, nickname + badge rank pill + role di tengah, tombol pill kecil 
   solid lime "Kirim Request" di kanan. Kartu sedikit glow saat hover.

4. Seksi "Request Mabar Terbaru" — list ringkas dengan status ditulis sebagai 
   pill kecil berwarna solid (teal untuk diterima, coral untuk ditolak, 
   lime redup untuk pending).

Jika tidak ada rekomendasi/aktivitas, tampilkan empty state hangat dengan 
ilustrasi maskot kecil + teks ajakan: "Lengkapi profil game kamu dulu, biar 
kita carikan teman mabar yang pas!"
```

---

## 5. Halaman: Pilih Game

**Prompt Stitch:**
```
Buat halaman "Pilih Game" bergaya ceria & hangat.

Judul halaman rounded bold besar "Mau main apa hari ini?" rata kiri, dengan 
sub-teks hangat di bawahnya.

Grid kartu game (Mobile Legends, PUBG Mobile, Free Fire, Valorant, dan slot 
"Game lainnya segera hadir" dengan opacity lebih rendah + border putus-putus 
rounded). Setiap kartu game: rounded besar (radius 20px+), ikon game berwarna 
besar, nama game rounded bold, dan angka jumlah pemain aktif ditulis besar 
tebal dengan warna accent-lime. Saat kartu dipilih/hover: scale sedikit 
membesar + glow lime di tepi kartu.

Breadcrumb tipis hangat di atas judul: "Beranda / Pilih Game" dipisah slash 
sederhana.
```

---

## 6. Halaman: Hasil Pencarian & Filter (per Game)

### 6.1 Prompt Umum (Struktur Layout — sama untuk semua game)
```
Buat halaman "Hasil Pencarian Teman Mabar" untuk game [NAMA GAME], gaya ceria 
& hangat, layout dua kolom: panel filter di kiri (280px) dan hasil pencarian 
(list) di kanan.

Panel Filter Kiri:
- Judul rounded bold "Filter" di atas, dengan ikon funnel kecil playful.
- Setiap grup filter dipisah garis tipis hangat.
- Pilihan filter: checkbox/radio rounded (bukan kotak tegas), atau range 
  slider dengan handle bulat accent-lime untuk atribut numerik/rank.
- Tombol "Terapkan Filter" pill solid lime dengan glow di bagian bawah 
  panel, link "Reset filter" di sebelahnya.

Hasil Pencarian Kanan:
- Header baris atas: jumlah hasil ("214 pemain ditemukan" dalam angka besar 
  tebal) di kiri, dropdown rounded "Urutkan: Paling relevan" di kanan.
- List vertikal kartu rounded: avatar bulat kiri dengan ring violet, nickname 
  (rounded bold) + titik status online solid teal kecil, lalu satu baris 
  atribut spesifik game sebagai pill kecil berjejer (contoh nanti disesuaikan 
  per game). Di kanan kartu: tombol pill outline "Kirim Request" yang berubah 
  jadi solid lime saat hover.
- Kartu sedikit shadow/glow lembut, radius besar. Saat hover: scale sedikit 
  membesar.
- Transisi saat filter diterapkan: fade + sedikit slide-up halus pada list.

Jika hasil kosong: tampilkan ilustrasi maskot kecil + pesan hangat "Belum ada 
pemain dengan kriteria ini nih. Coba longgarkan filter rank atau server ya!" 
disertai tombol pill "Reset Filter".
```

### 6.2 Skema Atribut Filter per Game (lampirkan ke prompt 6.1)

**Mobile Legends**
```
Atribut filter untuk Mobile Legends:
- Rank: slider bertingkat (Warrior, Elite, Master, Grandmaster, Epic, Legend, 
  Mythic, Mythical Glory) — tampilkan sebagai slider dengan handle bulat lime.
- Role: multi-select pill (Tank, Fighter, Assassin, Mage, Marksman, Support).
- Server: dropdown rounded (Asia, SEA, Indonesia).
- Win Rate: range slider persentase (0–100%).
Kartu hasil menampilkan pill kecil berjejer: "Mythic" (violet) "Mage" "SEA" 
— dipisah spasi/gap antar pill, jangan pakai titik tengah "·".
```

**PUBG Mobile**
```
Atribut filter untuk PUBG Mobile:
- Rank: slider bertingkat (Bronze, Silver, Gold, Platinum, Diamond, Crown, 
  Ace, Conqueror).
- Mode: radio pill (Solo, Duo, Squad).
- Server: dropdown rounded (Asia, SEA).
- Tipe Main: checkbox pill (Push Rank, Santai, Sniper Only).
Kartu hasil menampilkan pill: "Ace" "Squad" "Push Rank".
```

**Free Fire**
```
Atribut filter untuk Free Fire:
- Rank: slider bertingkat (Bronze, Silver, Gold, Platinum, Diamond, Heroic, 
  Grandmaster).
- Role: multi-select pill (Rusher, Support, Sniper, IGL).
- Mode: radio pill (Battle Royale, Clash Squad).
- Server: dropdown rounded (Indonesia, SEA).
Kartu hasil menampilkan pill: "Heroic" "Rusher" "Clash Squad".
```

**Valorant**
```
Atribut filter untuk Valorant:
- Rank: slider bertingkat (Iron, Bronze, Silver, Gold, Platinum, Diamond, 
  Ascendant, Immortal, Radiant).
- Role/Agent Pool: multi-select pill (Duelist, Controller, Initiator, 
  Sentinel).
- Peran dalam Tim: radio pill (IGL, Entry Fragger, Support, Lurker).
- Server: dropdown rounded (Asia Pacific, SEA).
Kartu hasil menampilkan pill: "Immortal" "Duelist" "Entry Fragger".
```

---

## 7. Halaman: Detail Profil User

**Prompt Stitch:**
```
Buat halaman Detail Profil Pemain (dilihat oleh user lain), gaya clubhouse 
ceria & hangat.

Layout: header profil di atas (full width, boleh pakai foto latar gameplay 
favorit user dengan overlay gradasi gelap), lalu konten di bawah dua kolom.

Header profil:
- Avatar besar bulat dengan ring tebal accent-violet di kiri.
- Di sebelahnya: nickname besar rounded bold, kota, dan status "Sedang 
  mencari mabar" (titik solid teal + teks hangat).
- Tombol "Kirim Request Mabar" pill solid lime dengan glow di kanan header.

Kolom kiri (konten utama, 65%):
- Bio singkat user (Inter/DM Sans, line-height nyaman).
- Seksi "Profil Game" — kartu rounded per game yang dimiliki user, tiap kartu 
  berisi ikon game, badge rank pill violet, dan atribut lain sebagai pill 
  kecil berjejer, dipisah gap antar kartu (bukan hairline tegas).

Kolom kanan (sidebar info, 35%):
- Kartu rounded "Info Singkat": jam aktif bermain, jumlah mabar berhasil 
  (angka besar rounded bold + label kecil di bawahnya, boleh ikon trofi 
  playful kecil berwarna lime).
- Tombol teks kecil "Laporkan profil ini" di bagian paling bawah sidebar, 
  warna alert-coral.

Boleh tambahkan sedikit shadow/glow pada kartu-kartu untuk kesan hidup, 
representasikan reputasi dengan angka besar dan ikon playful sederhana 
(bukan star-rating kuning generik).
```

---

## 8. Halaman: Profil Saya (Edit)

**Prompt Stitch:**
```
Buat halaman "Profil Saya" untuk user mengedit data sendiri, gaya ceria & 
hangat.

Layout: tab pill horizontal di atas (Info Umum, Profil Game, Pengaturan 
Akun) — tab aktif solid lime, tab tidak aktif outline redup.

Tab "Info Umum":
- Form vertikal: upload avatar bulat (border putus-putus rounded saat 
  kosong, ikon kamera playful di tengah), input Nickname, Bio (textarea 
  rounded), dropdown Kota, toggle pill "Sedang mencari mabar".
- Tombol "Simpan Perubahan" pill solid lime dengan glow di akhir form.

Tab "Profil Game":
- List game yang sudah ditambahkan, tiap game berupa kartu rounded 
  expandable — saat diklik, kartu meluas menampilkan form atribut dinamis 
  sesuai game tersebut (rank, role, server, dll sesuai skema masing-masing, 
  lihat bagian 6.2).
- Tombol outline pill "+ Tambah Game Baru" membuka dropdown pilihan game 
  yang belum ditambahkan.
- Tombol kecil "Hapus profil game ini" (teks alert-coral) di tiap kartu.

Tab "Pengaturan Akun":
- Form ganti password (input rounded), dan tombol outline "Hapus Akun" 
  warna alert-coral di bagian paling bawah, terpisah jelas dengan spacing 
  ekstra dari aksi lain.
```

---

## 9. Halaman: Request Mabar

**Prompt Stitch:**
```
Buat halaman "Request Mabar" bergaya ceria & hangat, berisi dua tab pill: 
"Diterima Masuk" dan "Terkirim".

List vertikal kartu rounded per request: avatar bulat kiri dengan ring 
violet, nickname + game + badge rank pill singkat di tengah, dan di kanan:
- Untuk tab "Diterima Masuk": dua tombol pill kecil bersebelahan — "Terima" 
  (solid teal) dan "Tolak" (outline coral).
- Untuk tab "Terkirim": status sebagai pill kecil berwarna solid ("Menunggu" 
  lime redup / "Diterima" teal / "Ditolak" coral).

Jika request diterima, kartu tersebut menampilkan tambahan baris kecil berisi 
ID game lawan main yang baru terbuka, dengan tombol pill kecil "Salin ID".

Empty state hangat dengan ilustrasi maskot kecil: "Belum ada request masuk 
nih. Yuk mulai cari teman mabar!" dengan tombol pill ke halaman pencarian.
```

---

## 10. Admin: Kelola Game

**Prompt Stitch:**
```
Buat halaman Admin "Kelola Game", layout sidebar admin (fixed, sama seperti 
sidebar user tapi label "Admin Panel" di atas) + konten kanan, gaya ceria & 
hangat tetap konsisten meski untuk panel admin (sedikit lebih tenang, tapi 
tidak kaku).

Konten:
- Header: judul "Kelola Game" + tombol pill solid lime kecil "+ Tambah Game" 
  di kanan.
- Tabel rounded (bukan flat tegas): kolom Ikon (rounded thumbnail), Nama 
  Game, Jumlah Profil Aktif (angka tebal), Status (pill Aktif=teal / 
  Nonaktif=coral), Aksi (tombol teks kecil edit/hapus).
- Baris tabel dipisah garis tipis hangat, header tabel dengan background 
  surface sedikit lebih terang.

Modal "Tambah/Edit Game" (overlay gelap lembut, panel form rounded di tengah 
dengan shadow lembut): input Nama Game, upload Ikon (preview bulat/rounded), 
toggle Status Aktif, tombol pill "Simpan".
```

---

## 11. Admin: Kelola Atribut Game

**Prompt Stitch:**
```
Buat halaman Admin "Kelola Atribut Game" — di sinilah admin mendefinisikan 
skema atribut dinamis per game (rank, role, server, dll) tanpa perlu coding, 
gaya ceria & hangat.

Layout: dropdown rounded pilih game di atas, lalu di bawahnya list atribut 
milik game tersebut (kartu rounded, bisa drag untuk urutan tampil).

Tiap baris atribut: nama atribut, tipe data (dropdown rounded: Pilihan 
Tunggal / Pilihan Ganda / Angka / Teks), daftar opsi (jika tipe pilihan — 
ditampilkan sebagai pill kecil berjejer, bisa dihapus satu-satu dengan ikon 
silang kecil), dan tombol hapus atribut.

Tombol "+ Tambah Atribut Baru" pill outline lime di bawah list.

Catatan kecil hangat di atas tabel: "Perubahan di sini otomatis muncul di 
form Profil Game dan Filter Pencarian untuk game ini, lho!"
```

---

## 12. Admin: Kelola User

**Prompt Stitch:**
```
Buat halaman Admin "Kelola User", gaya ceria & hangat.

Header: judul "Kelola User", search bar rounded di kanan (ikon kaca pembesar 
kecil), dropdown filter Status rounded (Semua/Aktif/Disuspend).

Tabel rounded: Avatar bulat kecil, Nickname, Email, Jumlah Profil Game (angka 
tebal), Tanggal Daftar, Status (pill teal=aktif, coral=disuspend), Aksi (teks 
kecil "Detail" / "Suspend" / "Hapus").

Klik "Detail" membuka panel slide-in dari kanan (rounded corner di sisi 
panel, shadow lembut) berisi info lengkap user + riwayat aktivitas singkat + 
tombol aksi admin pill.
```

---

## 13. Admin: Laporan (Reports)

**Prompt Stitch:**
```
Buat halaman Admin "Laporan" untuk menindaklanjuti report dari user, gaya 
ceria & hangat (tetap tenang untuk konteks moderasi).

List vertikal kartu rounded per laporan: nama pelapor → nama yang dilaporkan 
(panah kecil monokrom di antaranya, khusus di sini karena menggambarkan alur 
laporan), alasan laporan (dipotong 1 baris dengan "lihat selengkapnya"), 
tanggal, dan status sebagai pill (Baru=lime redup / Ditinjau=violet / 
Selesai=teal).

Klik satu kartu membuka detail laporan di panel kanan (split view rounded): 
detail lengkap laporan, link ke profil yang dilaporkan, dan tombol aksi admin 
("Tandai Ditinjau", "Suspend User Ini", "Tutup Laporan") sebagai tombol pill 
outline berjejer.
```

---

## 14. Admin: Dashboard Statistik

**Prompt Stitch:**
```
Buat halaman Admin "Dashboard Statistik", gaya ceria & hangat.

Baris atas: 4 kartu rounded angka besar berjejer — tiap kartu berisi angka 
besar rounded bold warna accent-lime + label kecil di bawahnya + perubahan 
persentase kecil (warna teal jika naik, coral jika turun). Contoh: "12.480" 
/ "Total User Terdaftar" / "+4,2% bulan ini".

Di bawahnya: dua chart berdampingan dalam kartu rounded dengan sedikit 
shadow, digambar dengan warna accent-lime untuk garis/batang utama di atas 
background surface:
1. Grafik "Pertumbuhan User" (garis, per bulan).
2. Grafik "Request Mabar per Game" (batang horizontal, 4 game, warna 
   berselang lime/violet).

Di bawah chart: tabel rounded ringkas "Game Paling Aktif" — kolom Nama Game, 
Jumlah Profil, Jumlah Request Bulan Ini.

Filter rentang waktu rounded di pojok kanan atas (dropdown teks: 7 Hari / 30 
Hari / 90 Hari).
```

---

## 15. Halaman: Lupa Password & Reset Password

**Prompt Stitch:**
```
Buat dua state dalam satu alur halaman: "Lupa Password" dan "Reset Password", 
gaya ceria & hangat, mengikuti layout split-screen seperti halaman Login 
(panel kiri foto in-game + overlay gradasi, panel kanan form).

State 1 — Lupa Password:
- Judul rounded bold "Lupa kata sandi? Santai aja" + sub-teks hangat 
  menjelaskan proses.
- Input Email rounded, tombol pill solid lime penuh lebar dengan glow "Kirim 
  Tautan Reset".
- Link teks kecil "Kembali ke halaman masuk" di bawah form.
- Setelah dikirim, form berganti jadi kartu konfirmasi rounded dengan ikon 
  amplop playful: "Tautan reset sudah dikirim ke [email]. Cek kotak masuk 
  atau folder spam ya." dengan tombol outline kecil "Kirim ulang" yang 
  nonaktif selama 60 detik (hitungan mundur angka besar tebal).

State 2 — Reset Password (dibuka dari link email):
- Judul rounded bold "Atur kata sandi baru".
- Input Password Baru dan Konfirmasi Password (rounded), dengan indikator 
  kekuatan password berupa bar rounded solid tiga level warna (coral=lemah, 
  paper redup=cukup, teal=kuat).
- Tombol pill solid lime "Simpan Password Baru".
- Jika tautan kedaluwarsa, tampilkan kartu rounded hangat: "Tautan ini sudah 
  tidak berlaku. Minta tautan baru, yuk." dengan tombol kembali ke Lupa 
  Password.
```

---

## 16. Halaman: Verifikasi Email

**Prompt Stitch:**
```
Buat halaman "Verifikasi Email" yang muncul setelah user mendaftar, gaya 
ceria & hangat.

Layout: kartu rounded terpusat (max-width 480px) dengan sedikit shadow/glow, 
di tengah halaman base-ink polos.

Isi kartu:
- Ilustrasi/ikon amplop playful berwarna (bukan monokrom kaku).
- Judul rounded bold "Cek email kamu dulu, yuk!".
- Teks hangat: "Kami sudah kirim tautan verifikasi ke [email]. Klik tautan 
  itu buat aktifin akun kamu."
- Tombol outline pill "Kirim Ulang Email" dengan status cooldown, pola sama 
  seperti halaman Lupa Password.
- Link teks kecil "Salah alamat email? Ganti di sini".

State "Verifikasi Berhasil" (halaman terpisah, dibuka dari link email):
- Ikon centang besar playful berwarna lime dengan sedikit glow.
- Judul rounded bold "Yes! Email kamu berhasil diverifikasi".
- Tombol pill solid lime "Lanjut ke Onboarding".
```

---

## 17. Halaman: Onboarding (Setelah Daftar)

**Prompt Stitch:**
```
Buat alur Onboarding 3 langkah untuk user baru, gaya ceria & hangat. 
Penomoran 01/02/03 dipakai di sini karena memang berurutan.

Progress indicator di atas berupa 3 titik/pill kecil rounded, langkah aktif 
solid lime dengan glow, langkah selesai solid teal, langkah belum dimulai 
outline redup.

Langkah 01 — Lengkapi Profil Umum:
- Judul rounded bold "Kenalan dulu, yuk!". 
- Form: upload avatar bulat (border putus-putus playful saat kosong), 
  Nickname, Kota, Bio singkat (opsional).
- Tombol "Lanjut" pill solid lime di kanan bawah.

Langkah 02 — Pilih Game Pertama:
- Judul rounded bold "Mau temenan buat main apa?".
- Grid game yang sama seperti halaman Pilih Game (bagian 5), user memilih 
  minimal satu, kartu terpilih memancarkan glow lime.
- Setelah dipilih, form atribut dinamis game tersebut muncul di bawah grid 
  (rank, role, server, dll sesuai skema game — bagian 6.2).
- Tombol "Lanjut" pill solid lime, dan link "Lewati langkah ini".

Langkah 03 — Atur Preferensi Mabar:
- Judul rounded bold "Terakhir nih, atur preferensi kamu".
- Toggle pill "Aktifkan status sedang mencari mabar sekarang".
- Pilihan jam aktif bermain (pill checkbox: Pagi, Siang, Sore, Malam, Dini 
  Hari).
- Tombol akhir pill solid lime penuh lebar dengan glow "Selesai, Masuk ke 
  Beranda!" — boleh disertai sedikit animasi confetti ringan warna lime & 
  violet sebagai perayaan kecil (bukan animasi berlebihan).
```

---

## 18. Halaman: Tentang

**Prompt Stitch:**
```
Buat halaman "Tentang" bergaya ceria & hangat, ditautkan dari menu navbar 
Landing Page.

Layout: konten satu kolom rata kiri, max-width terbatas untuk keterbacaan, 
dipisah section dengan spacing generous — bukan layout majalah kaku.

Struktur:
1. Judul rounded bold besar "Kenapa Mabar Finder ada" + satu paragraf 
   pembuka personal dan hangat.
2. Seksi "Cara kami berpikir" — dua atau tiga paragraf pendek menjelaskan 
   filosofi produk, boleh disertai ilustrasi kecil playful di sisi paragraf.
3. Seksi angka singkat — 3 kartu rounded angka besar berjejer (accent-lime): 
   jumlah user, jumlah game, jumlah mabar berhasil terbentuk, masing-masing 
   dengan label kecil di bawahnya.
4. Penutup: ajakan bergabung dengan tombol pill solid lime "Buat Akun 
   Gratis" dan link kembali ke Landing Page.

Boleh tambahkan ilustrasi maskot sederhana di beberapa titik untuk memberi 
kesan hangat, tanpa foto tim/kantor generik.
```

---

## 19. Halaman: Syarat & Ketentuan / Kebijakan Privasi

**Prompt Stitch:**
```
Buat dua halaman dengan layout identik: "Syarat & Ketentuan" dan "Kebijakan 
Privasi", ditautkan dari footer. Meski isinya legal, tetap gunakan sentuhan 
gaya v2 yang hangat (bukan dingin sepenuhnya).

Layout: sidebar kiri kecil berisi daftar isi (anchor link ke tiap bagian, 
item aktif saat scroll ditandai pill kecil solid lime redup). Konten utama 
kanan berupa teks legal, dibagi per bagian dengan judul rounded bold sedang, 
dipisah spacing generous antar bagian.

Di bagian atas konten: tanggal terakhir diperbarui dalam teks kecil hangat 
("Terakhir diperbarui: 23 September 2026"). Teks isi dalam Inter/DM Sans, 
line-height nyaman, max-width dibatasi.

Halaman ini tetap sederhana secara visual (tidak perlu ilustrasi berlebihan), 
tapi sudut kartu/sidebar tetap rounded konsisten dengan halaman lain.
```

---

## 20. Halaman: 404 / Error Umum

**Prompt Stitch:**
```
Buat halaman error untuk dua kasus: "404 Halaman Tidak Ditemukan" dan "Error 
Umum/Server Bermasalah", gaya ceria & hangat. Gunakan template yang sama, 
beda teks saja.

Layout: konten terpusat vertikal di tengah layar base-ink, teks tetap rata 
kiri di dalam blok kontennya.

Isi:
- Angka besar rounded bold "404" berwarna accent-lime dengan sedikit glow 
  (atau ilustrasi maskot kecil yang terlihat "bingung" dengan gaya playful 
  untuk error umum).
- Judul rounded bold sedang: "Waduh, halaman ini nggak ketemu" / "Ada yang 
  nggak beres di server kami".
- Satu kalimat penjelas singkat dengan nada santai dan tenang.
- Tombol pill solid lime "Kembali ke Beranda" dan link teks kecil "Laporkan 
  masalah ini" di bawahnya.

Ilustrasi maskot playful yang simpel diperbolehkan di sini (bukan ilustrasi 
3D pecah/awan galau generik) — konsisten dengan karakter maskot brand.
```

---

## 21. Konfirmasi Laporan Terkirim (dari sisi User)

**Prompt Stitch:**
```
Buat state/bottom sheet konfirmasi yang muncul setelah user menekan 
"Laporkan profil ini" di halaman Detail Profil (bagian 7), gaya ceria & 
hangat.

Panel slide-in dari bawah (bottom sheet rounded di bagian atas, radius 
20-24px), dengan sedikit shadow ke atas untuk kesan mengambang.

Isi panel:
1. Langkah 1 — Pilih Alasan: judul rounded bold kecil "Kenapa kamu 
   melaporkan profil ini?", daftar radio pill (Profil palsu/fake rank, 
   Perilaku tidak pantas, Penipuan, Lainnya). Jika "Lainnya" dipilih, 
   textarea rounded kecil muncul untuk detail.
2. Tombol "Kirim Laporan" pill solid lime, dan "Batal" teks kecil di 
   sampingnya.
3. Setelah dikirim, isi panel berganti jadi konfirmasi hangat: ikon centang 
   playful berwarna teal dengan sedikit glow, teks "Laporan kamu sudah kami 
   terima. Tim kami akan meninjau dalam 1x24 jam ya." dan tombol pill 
   "Tutup".

Setelah ditutup, status "Laporkan profil ini" pada halaman Detail Profil 
berubah jadi teks nonaktif "Laporan terkirim" (warna paper redup) agar user 
tahu sudah melapor, mencegah laporan ganda.
```

---

## 22. Peta Route Lengkap

Ringkasan seluruh route agar sinkron antara `desain.md`, PRD, dan implementasi Vue Router nantinya:

| Route | Halaman | Akses |
|---|---|---|
| `/` | Landing Page | Guest |
| `/tentang` | Tentang | Guest |
| `/syarat-ketentuan` | Syarat & Ketentuan | Guest |
| `/kebijakan-privasi` | Kebijakan Privasi | Guest |
| `/login` | Login | Guest |
| `/register` | Register | Guest |
| `/lupa-password` | Lupa Password | Guest |
| `/reset-password/:token` | Reset Password | Guest (via link email) |
| `/verifikasi-email` | Verifikasi Email (menunggu) | User (belum terverifikasi) |
| `/verifikasi-email/berhasil` | Verifikasi Berhasil | User (via link email) |
| `/onboarding` | Onboarding 3 langkah | User (baru pertama login) |
| `/beranda` | Dashboard/Beranda | User |
| `/pilih-game` | Pilih Game | User |
| `/cari/:gameSlug` | Hasil Pencarian & Filter | User |
| `/profil/:userId` | Detail Profil User | User |
| `/profil-saya` | Profil Saya (edit) | User |
| `/request-mabar` | Request Mabar | User |
| `/admin/game` | Admin: Kelola Game | Admin |
| `/admin/atribut-game` | Admin: Kelola Atribut Game | Admin |
| `/admin/user` | Admin: Kelola User | Admin |
| `/admin/laporan` | Admin: Laporan | Admin |
| `/admin/statistik` | Admin: Dashboard Statistik | Admin |
| `*` (catch-all) | 404 / Error | Semua |

---

## 23. Checklist Sebelum Generate di Stitch (v2)

Gunakan checklist ini setiap kali menempelkan prompt ke Google Stitch, agar hasil konsisten ceria & hangat:

- [ ] Sudah menyertakan Master Prompt v2 (bagian 1, dengan blok LARANGAN TEGAS) di awal, sebelum prompt halaman spesifik.
- [ ] **Tidak ada emoji** di badge, tombol, tag, list, atau copy mana pun.
- [ ] **Tidak ada gradasi** dalam bentuk apa pun — background, tombol, badge, overlay foto, maupun glow. Semua warna solid/flat.
- [ ] Shadow/elevasi (jika ada) berupa soft shadow **satu warna**, bukan glow radial multi-warna.
- [ ] **Tidak ada eyebrow ALL CAPS** di atas judul section mana pun.
- [ ] **Tidak ada satu kata/frasa dalam headline** yang diwarnai berbeda atau digarisbawahi bergelombang sebagai penekanan.
- [ ] **Tidak ada tanda panah "→"** ditempel di akhir teks tombol/link.
- [ ] Tidak ada metadata digabung titik tengah "·" atau label "WORD — fragmen" dengan em dash.
- [ ] Warna aksen maksimal 2 sekaligus per layar (lime + violet), tidak lebih.
- [ ] Font judul & angka besar memakai rounded sans bold (Baloo 2/Plus Jakarta Sans/Poppins), bukan serif tajam.
- [ ] Sudut kartu/tombol membulat generous (16-24px), tombol CTA berbentuk pil.
- [ ] Avatar berbentuk bulat, bukan kotak.
- [ ] Badge rank berbentuk pill rounded (violet) dengan line-icon sederhana, bukan emoji.
- [ ] Penomoran 01/02/03 hanya dipakai di seksi yang benar-benar berurutan (onboarding, cara kerja).
- [ ] Motion dibatasi satu momen disengaja per halaman, bukan fade-slide-up di setiap section.
- [ ] Copy/nada tulisan santai dan hangat, bukan formal/korporat, dan tanpa emoji.
- [ ] Tidak ada foto stok generik "gamer headset RGB".
