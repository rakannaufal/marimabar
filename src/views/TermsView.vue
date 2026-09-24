<script setup lang="ts">
const sections = [
  { id: 'ringkasan', label: 'Ringkasan komunitas' },
  { id: 'ketentuan-akun', label: 'Akun & pendaftaran' },
  { id: 'kode-etik', label: 'Kode etik bermain' },
  { id: 'reputasi-matchmaking', label: 'Profil & pencarian teman' },
  { id: 'moderasi-sanksi', label: 'Laporan & moderasi' },
  { id: 'hak-cipta', label: 'Kekayaan intelektual' },
  { id: 'batasan-tanggung-jawab', label: 'Batasan layanan' },
  { id: 'kontak-bantuan', label: 'Pertanyaan & bantuan' },
]
</script>

<template>
  <main class="terms-page">
    <div class="legal-wrap">
      <nav class="crumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span aria-hidden="true">/</span><span>Syarat &amp; Ketentuan</span></nav>
      <div class="legal-grid">
        <aside class="legal-sidebar" aria-label="Navigasi dokumen">
          <div class="legal-tabs"><RouterLink to="/syarat-ketentuan" aria-current="page">Ketentuan</RouterLink><RouterLink to="/kebijakan-privasi">Privasi</RouterLink></div>
          <h2>Daftar Isi</h2>
          <nav aria-label="Bagian syarat dan ketentuan"><a v-for="section in sections" :key="section.id" :href="`#${section.id}`">{{ section.label }}</a></nav>
          <p class="sidebar-note">Aturan sederhana untuk ruang mabar yang saling menghargai.</p>
        </aside>
        <div class="legal-body">
          <header class="legal-heading"><h1>Syarat &amp; Ketentuan Mabar Finder</h1><p>Selamat datang! Panduan ini menjelaskan bagaimana kita menggunakan layanan pencarian teman mabar dan menjaga interaksi tetap nyaman. Baca setiap bagian sebelum menggunakan layanan.</p></header>
          <section id="ringkasan" class="summary-panel" aria-labelledby="ringkasan-title">
            <h2 id="ringkasan-title">Main asik, saling respek</h2>
            <p>Gunakan akun milikmu sendiri, isi profil game dengan jujur, hormati rekan main, dan jangan membagikan data pribadi orang lain. Mabar Finder mempertemukan pemain; ajakan dan sesi permainan tetap bergantung pada pilihan kedua pihak.</p>
            <ul class="summary-list"><li>Jaga chat tetap sopan.</li><li>Jangan mengirim spam atau penipuan.</li><li>Laporkan perilaku yang membuatmu tidak aman.</li><li>Periksa informasi profil sebelum mengirim ajakan.</li></ul>
          </section>
          <section id="ketentuan-akun" class="legal-section"><h2>Akun &amp; pendaftaran</h2><p>Untuk membuat akun pada layanan MVP, kamu harus berusia minimal 18 tahun dan menggunakan alamat email yang dapat diakses. Verifikasi email diperlukan sebelum mengirim ajakan atau pesan.</p><p>Jaga kredensial akunmu; jangan membagikan kata sandi atau kode pemulihan. Informasi game yang kamu isi menjadi tanggung jawabmu, termasuk nama dalam game, rank, role, dan jadwal yang kamu cantumkan.</p></section>
          <section id="kode-etik" class="legal-section"><h2>Kode etik bermain</h2><p>Hormati pemain lain, baik sedang push rank maupun main santai. Ujaran kebencian, pelecehan, ancaman, doxing, penipuan, spam, dan ajakan menggunakan cheat tidak diterima di ruang komunitas ini.</p><div class="inset-panel"><h3>Ruang main yang lebih nyaman</h3><p>Berikan masukan yang membangun. Jangan menyebarkan identitas, kontak, atau isi chat orang lain tanpa izin. Gunakan fitur blokir dan laporan jika interaksi terasa mengganggu.</p></div></section>
          <section id="reputasi-matchmaking" class="legal-section"><h2>Profil &amp; pencarian teman</h2><p>Pencarian menggunakan preferensi yang diisi pemain, seperti game, rank, role, mode, dan region. Data game diisi pengguna, belum terverifikasi; kecocokan bukan jaminan hasil pertandingan atau kompatibilitas di dalam game.</p><p>Mabar Finder tidak terhubung ke API resmi game, tidak memverifikasi kepemilikan akun game, dan tidak mengirim undangan langsung ke game. ID game tidak otomatis dibagikan ketika ajakan diterima; pemilik memilih sendiri apakah akan membagikannya setelah itu.</p></section>
          <section id="moderasi-sanksi" class="legal-section"><h2>Laporan &amp; moderasi</h2><p>Kamu dapat melaporkan dugaan pelecehan, spam, penipuan, impersonasi, atau konten tidak pantas. Laporan perlu ditinjau berdasarkan konteks dan bukti yang tersedia; mengirim laporan tidak menjamin keputusan atau waktu penyelesaian tertentu.</p><p>Jika tindakan pembatasan diterapkan, alasannya perlu dicatat dan pengguna diberi kesempatan untuk mengajukan banding melalui alur yang tersedia. Jangan memakai fitur laporan untuk mengganggu pemain lain.</p></section>
          <section id="hak-cipta" class="legal-section"><h2>Kekayaan intelektual</h2><p>Nama dan merek game yang disebut hanya untuk membantu pemain menemukan komunitasnya. Merek, logo, dan aset dari Mobile Legends, PUBG Mobile, Free Fire, dan Valorant tetap milik pemegang hak masing-masing. Jangan mengunggah materi yang melanggar hak pihak lain.</p></section>
          <section id="batasan-tanggung-jawab" class="legal-section"><h2>Batasan layanan</h2><p>Layanan ini membantu pemain saling menemukan, bukan menjalankan game atau mengendalikan perilaku setiap pemain. Ketersediaan fitur bisa berubah atau terganggu. Gunakan penilaianmu sendiri sebelum membagikan informasi dan berinteraksi di luar aplikasi.</p><p>Kami tidak menjanjikan kemenangan, kenaikan rank, kecocokan antarpemain, atau penyelesaian setiap laporan. Pembayaran atau transaksi antarpribadi bukan bagian dari layanan pencarian teman mabar ini.</p></section>
          <section id="kontak-bantuan" class="contact-panel"><h2>Pertanyaan tentang ketentuan?</h2><p>Untuk pertanyaan atau laporan, gunakan alur bantuan dalam aplikasi bila tersedia. Kamu juga bisa kembali ke beranda untuk melihat cara kerja layanan.</p><RouterLink to="/">Kembali ke Beranda</RouterLink></section>
        </div>
      </div>
    </div>
  </main>
</template>

<style scoped>
.terms-page{background:#14141c;color:#f5f3ee;font-family:Inter,system-ui,sans-serif;padding:2.25rem 1.25rem 6rem}.legal-wrap{max-width:1200px;margin:auto}.crumb{display:flex;gap:.7rem;align-items:center;color:#b8b6c2;font-size:.86rem;margin-bottom:2rem}.crumb a:hover{color:#c8ff4d}.legal-grid{display:grid;grid-template-columns:minmax(225px,290px) minmax(0,1fr);gap:2rem;align-items:start}.legal-sidebar{position:sticky;top:1.5rem;background:#1b1b23;border:1px solid #2e2e3e;border-radius:24px;padding:1.1rem}.legal-tabs{display:flex;gap:.2rem;background:#292934;padding:.25rem;border-radius:999px}.legal-tabs a{flex:1;text-align:center;padding:.65rem .4rem;border-radius:999px;font-size:.85rem;font-weight:700}.legal-tabs [aria-current]{background:#c8ff4d;color:#14141c}.legal-sidebar h2{font:700 1.1rem 'Plus Jakarta Sans',sans-serif;margin:1.6rem .5rem .8rem}.legal-sidebar nav{display:grid;gap:.15rem}.legal-sidebar nav a{display:block;color:#c9c8d3;border-radius:12px;padding:.68rem .75rem;font-size:.86rem}.legal-sidebar nav a:hover,.legal-sidebar nav a:focus-visible{background:#32323e;color:#c8ff4d;text-decoration:none}.sidebar-note{margin:1.5rem .4rem .2rem;border-top:1px solid #363643;padding-top:1rem;color:#b8b6c2;font-size:.8rem;line-height:1.6}.legal-body{max-width:820px;min-width:0}.legal-heading{margin:0 0 2.5rem}.legal-heading h1{font:800 clamp(2rem,3.5vw,2.5rem)/1.2 'Plus Jakarta Sans',sans-serif;letter-spacing:-.03em;margin:0 0 1rem}.legal-heading p{font-size:1.05rem;color:#c9c8d3;line-height:1.75;max-width:700px}.legal-section,.summary-panel,.contact-panel{scroll-margin-top:1.5rem;margin-bottom:2rem}.legal-section{padding:1.6rem .2rem;border-top:1px solid #353541}.legal-body h2{font:700 clamp(1.35rem,2.5vw,1.7rem)/1.3 'Plus Jakarta Sans',sans-serif;margin:0 0 1rem}.legal-body h3{font:700 1.05rem 'Plus Jakarta Sans',sans-serif;margin:0 0 .5rem}.legal-body p{line-height:1.78;color:#c9c8d3;margin:0 0 1rem}.legal-section p:last-child{margin-bottom:0}.summary-panel,.contact-panel{background:#1e1e29;border:1px solid #34343e;border-radius:24px;padding:clamp(1.4rem,3vw,2rem)}.summary-panel{border-left:4px solid #c8ff4d}.summary-list{display:grid;grid-template-columns:1fr 1fr;gap:.8rem;list-style:none;padding:0;margin:1.2rem 0 0}.summary-list li,.inset-panel{background:#292934;border-radius:16px;padding:1rem;color:#f5f3ee}.summary-list li::before{content:'';display:inline-block;width:7px;height:7px;background:#c8ff4d;border-radius:50%;vertical-align:middle;margin-right:.7rem}.inset-panel p{margin:0}.contact-panel a{display:inline-flex;align-items:center;justify-content:center;background:#c8ff4d;color:#14141c;min-height:46px;padding:.6rem 1.4rem;border-radius:999px;font-weight:700}.terms-page a:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:770px){.legal-grid{grid-template-columns:1fr}.legal-sidebar{position:static}.legal-sidebar nav{grid-template-columns:1fr 1fr}.legal-heading{margin-top:.5rem}}@media(max-width:460px){.legal-sidebar nav,.summary-list{grid-template-columns:1fr}.terms-page{padding-inline:1rem}}
</style>
