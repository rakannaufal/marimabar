# Schema.d — Kontrak data konseptual Teman Mabar

Format `.d` mengikuti nama berkas yang diminta. Ini **dokumen skema**, bukan SQL/DDL yang siap dieksekusi; migrasi PostgreSQL berversi adalah artefak implementasi. `prd.md` menentukan kebutuhan, `Architecture.md` menentukan batas sistem. Nama kolom/status di bawah adalah kontrak awal; perubahan memerlukan migrasi, tipe aplikasi, dan uji RLS.

## Konvensi

- Semua PK `uuid`; FK ke `auth.users(id)` ditulis `user_id`/`*_id`. Semua timestamp event `timestamptz` UTC; gunakan `created_at`, `updated_at` seperlunya. Jadwal berulang memakai `day_of_week` 0–6 (Minggu=0), `local_start`, `local_end` dan `timezone` IANA.
- Status dan category dibatasi CHECK atau referensi katalog. Semua enum migrasi harus eksplisit. `game_catalog_options.id` stabil lintas season; `active=false` mempertahankan data lama. `game_id_private` dan bukti adalah data sensitif; tidak pernah masuk proyeksi publik.
- Kolom umum `id`, `created_at`, `updated_at` tidak diulang di setiap tabel di bawah. `auth.users` dikelola Supabase; email/password bukan kolom `profiles`.

## Identitas, profil, katalog

| Tabel | Kolom utama | Constraint/akses |
| --- | --- | --- |
| `profiles` | `user_id` PK/FK auth, `display_name`, `avatar_path?`, `bio?`, `languages text[]`, `timezone`, `voice_preference`, `play_style` (casual/competitive), `availability_status` (ready/unavailable), `visibility` (public/hidden), `account_status` (active/restricted/deletion_pending), `adult_declared_at?` | Baca publik hanya proyeksi allowlist dan bila active/public; tulis hanya pemilik pada field aman. Status akun dan deklarasi usia tidak bebas diubah dari edit profil. |
| `user_roles` | `user_id` PK/FK auth, `role` (user/admin), `granted_by?`, `granted_at` | Default user via trigger; tulis hanya proses server teraudit, bukan metadata/edit user. |
| `availability_slots` | `id`, `user_id`, `day_of_week`, `local_start`, `local_end`, `timezone` | `local_start < local_end`; slot melewati tengah malam dibagi dua dengan hari masing-masing. FK profil, tulis pemilik. Konversi zona mempertimbangkan DST. |
| `games` | `id`, `slug` UNIQUE, `name`, `active`, `current_season_id?` | Seed awal empat game; hanya admin menulis. FK season harus milik game yang sama (validasi trigger/transaction). |
| `game_seasons` | `id`, `game_id`, `code`, `label`, `starts_at?`, `ends_at?`, `active` | UNIQUE `(game_id, code)`; rekam historis, jangan hapus season yang direferensikan. |
| `game_catalog_options` | `id`, `game_id`, `season_id?`, `kind` (rank/role/mode/region/server/map/hero/agent/perspective/team_size), `code`, `label`, `sort_order`, `active`, `rank_mode_option_id?` | UNIQUE `(game_id, kind, season_id, code)` dengan perlakuan NULL eksplisit; rank PUBG/Free Fire menggunakan `rank_mode_option_id` bila perlu. Pastikan referensi mode/game/jenis benar lewat trigger atau RPC tervalidasi. |
| `game_profiles` | `id`, `user_id`, `game_id`, `ign`, `game_id_private?`, `region_option_id?`, `server_option_id?`, `primary_rank_option_id?`, `primary_rank_mode_option_id?`, `primary_role_option_id?`, `play_goal?`, `availability_status`, `visibility`, `status` (active/hidden), `attributes jsonb`, `data_updated_at` | UNIQUE parsial `(user_id, game_id) WHERE status='active'`; opsi FK harus milik game/jenis yang tepat. `data_updated_at` mengukur kesegaran data game, bukan edit sistem. Jangan masukkan ID privat ke `attributes`. |
| `game_profile_options` | `game_profile_id`, `option_id`, `purpose` (secondary_role/favorite_mode/favorite_map/favorite_hero/favorite_agent/secondary_rank), `rank_mode_option_id?` | PK komposit perlu mempertimbangkan beberapa mode/rank: `(game_profile_id, purpose, option_id, rank_mode_option_id)` dengan NULLS NOT DISTINCT atau surrogate UUID + UNIQUE yang sesuai. Validasi game/jenis/season di server; untuk rank BR dan CS, satu nilai per mode. |

**Konteks game wajib:** MLBB: rank/divisi atau star bila relevan, role utama/sekunder, hero favorit. PUBG Mobile: rank ditautkan ke mode, perspektif TPP/FPP, ukuran tim, map, role. Free Fire: rank BR dan CS berbeda serta terkait mode; boleh salah satu/keduanya. Valorant: rank, role Agent, agent favorit, mode, region/shard. Opsi rank memiliki urutan per game **dan konteks mode**; jangan membandingkan `sort_order` lintas game/mode. `attributes` hanya untuk detail khusus non-indeks yang divalidasi (misalnya star/tier), bukan pengganti FK filter utama. Tetapkan skema JSON per game/versi sebelum migrasi.

## Interaksi dan keselamatan

| Tabel | Kolom utama | Constraint/akses |
| --- | --- | --- |
| `invites` | `id`, `sender_id`, `recipient_id`, `game_id`, `message?`, `status` (pending/accepted/rejected/cancelled/expired), `expires_at`, `responded_at?`, `pair_low`, `pair_high` | `sender_id <> recipient_id`; `pair_low/high` = pasangan UUID terurut yang dihitung DB. UNIQUE parsial `(pair_low, pair_high, game_id) WHERE status='pending'`; RPC harus mengubah pending yang telah kedaluwarsa dalam transaksi sebelum membuat lagi. Baca kedua pihak; transisi menurut peran. |
| `conversations` | `id`, `invite_id` UNIQUE, `participant_low`, `participant_high`, `status` (active/blocked/closed) | Dibuat satu kali saat invite diterima secara atomik; peserta sesuai invite. Baca hanya peserta; blokir menghentikan pesan baru meski row lama ada. |
| `messages` | `id`, `conversation_id`, `sender_id`, `body`, `created_at`, `deleted_at?` | Baca peserta sesuai kebijakan retensi; tulis peserta aktif jika tidak diblokir dan email verified. Batas panjang isi, paginasi `(created_at,id)`. |
| `game_id_shares` | `id`, `conversation_id`, `owner_id`, `game_profile_id`, `shared_at`, `revoked_at?` | Tindakan eksplisit pemilik, hanya setelah invite accepted; akses penerima hanya saat tidak dicabut, tidak diblokir, dan masih berizin. ID aktual dibaca lewat RPC terbatas, tidak diduplikasi di sini. |
| `blocks` | `blocker_id`, `blocked_id`, `created_at` | PK `(blocker_id, blocked_id)`; bukan diri sendiri. Efek pengecualian dua arah; tulis blocker saja. |
| `reports` | `id`, `reporter_id`, `reported_id`, `category` (harassment/spam/fraud/impersonation/inappropriate), `description`, `target_type` (profile/invite/message), `target_id`, `evidence_path?`, `status` (new/reviewing/resolved/dismissed), `reviewed_by?`, `resolved_at?` | Pelapor lihat laporan milik sendiri secara terbatas; admin melihat kasus; target harus terverifikasi terkait objek; bukti privat. Validasi duplikasi/rate limit di server. |
| `moderation_actions` | `id`, `admin_id`, `subject_user_id`, `report_id?`, `action` (hide_profile/restrict_account/restore_profile/restore_account), `reason`, `created_at` | Append-only audit; admin melalui RPC/Edge Function; tindakan dan perubahan status atomik, tidak dapat diedit pengguna. |
| `appeals` | `id`, `user_id`, `moderation_action_id`, `reason`, `status` (submitted/reviewing/resolved/rejected), `reviewed_by?`, `created_at`, `resolved_at?` | Hanya subjek tindakan dapat mengajukan; admin menangani sesuai alur banding final. |
| `notifications` | `id`, `user_id`, `kind` (invite_status/new_message/moderation), `reference_type`, `reference_id`, `read_at?`, `created_at` | Pemilik saja; payload minim, jangan masukkan isi chat/ID game. |

## View/RPC/Storage minimum

- `public_game_profiles` bukan `SELECT *`: allowlist avatar, nama, bio publik, game, rank/mode/role/region, bahasa, jadwal ringkas, kesegaran data. **Tidak termasuk** `game_id_private`, email, status moderasi internal, bukti laporan. Bila view memakai owner yang bypass RLS, jangan berikan akses langsung tanpa filter aman; utamakan RPC `SECURITY INVOKER` atau view `security_invoker` yang didukung versi PostgreSQL proyek.
- `search_game_profiles(filters, cursor, limit)` dan `public_profile_detail(profile_id)` menerapkan status aktif, visibility, dan blokir dua arah dari JWT. Batas `limit`; cursor mengikat filter/sort. Public count juga memakai batas akses sama.
- RPC transaksional: `create_invite`, `respond_invite`, `cancel_invite`, `send_message`, `share_game_id`, `revoke_game_id_share`, `apply_moderation_action`. Pastikan kepemilikan, email verified, role/status, expiry, rate limit, dan idempotensi; revoke EXECUTE dari `PUBLIC` lalu grant hanya role yang diperlukan. Edge Function untuk kebutuhan privilege Auth/Storage dan pekerjaan terjadwal expiry, bukan pembacaan bebas data.
- Bucket `avatars`: visibilitas sesuai aturan profil dan path milik pengguna, validasi file dan hapus metadata. Bucket `report_evidence`: privat; signed URL singkat setelah pemeriksaan akses kasus. Jangan menyimpan bukti di public bucket.

## Indeks dan pengujian

Indeks awal: `game_profiles(game_id,status,visibility,region_option_id,primary_rank_mode_option_id,primary_rank_option_id,data_updated_at DESC,id)` lalu sesuaikan dengan `EXPLAIN ANALYZE`; `game_profile_options(option_id,game_profile_id)`; `invites(recipient_id,status,created_at DESC)` dan pasangan unik pending; `messages(conversation_id,created_at DESC,id DESC)`; `blocks(blocked_id,blocker_id)` selain PK. Partial index harus cocok dengan predikat query nyata.

Uji migrasi dan constraint dengan dua ajakan berlawanan serentak, duplicate profile aktif, referensi katalog lintas game, rank BR/CS dan PUBG per mode, expired pending, chat sebelum diterima, blokir setelah diterima, akses ID game tanpa share, anon/detail publik, admin bukti terkait, serta akun restricted. Dokumen ini belum membuktikan migrasi berjalan: implementasi SQL dan pengujian Supabase tetap wajib.
