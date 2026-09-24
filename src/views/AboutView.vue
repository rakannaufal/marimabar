<template>
  <main class="about-page">
    <div class="about-wrap">
      <section class="about-intro" aria-labelledby="about-title">
        <div class="about-copy">
          <h1 id="about-title">Kenapa Mabar Finder ada</h1>
          <p class="lead">Pulang kuliah atau kerja, pengen main game buat refreshing, tapi susah ketemu teman satu tim yang sefrekuensi? Dari pengalaman itu, Mabar Finder berawal.</p>
          <p>Kami ingin bikin tempat untuk mencari rekan main lewat game, role, rank, dan waktu yang cocok. Kenalan lewat profil dulu, ajak mabar kalau sama-sama siap, lalu lanjut main di game pilihanmu.</p>
        </div>
        <div class="about-art" role="img" aria-label="Ilustrasi kontroler game memakai headset">
          <svg viewBox="0 0 200 200" fill="none" aria-hidden="true">
            <path d="M40 95C40 60 66 32 100 32S160 60 160 95" stroke="#8B7CFF" stroke-width="8" stroke-linecap="round"/>
            <rect x="30" y="85" width="16" height="34" rx="8" fill="#8B7CFF"/>
            <rect x="154" y="85" width="16" height="34" rx="8" fill="#8B7CFF"/>
            <path d="M52 82c0-12 13-20 28-18h40c15-2 28 6 28 18l6 40c2 14-10 26-24 26-10 0-16-8-22-14l-8-8-8 8c-6 6-12 14-22 14-14 0-26-12-24-26l6-40Z" fill="#30303E"/>
            <path d="M68 96c4-6 10-6 14 0m36 0c4-6 10-6 14 0" stroke="#C8FF4D" stroke-linecap="round" stroke-width="4"/>
            <path d="M94 108c0 7 12 9 12 0" stroke="#F5F3EE" stroke-linecap="round" stroke-width="3"/>
            <path d="M72 126v9m-5-4h10" stroke="#8B7CFF" stroke-width="3" stroke-linecap="round"/>
            <circle cx="126" cy="128" r="4" fill="#C8FF4D"/><circle cx="135" cy="135" r="4" fill="#8B7CFF"/>
          </svg>
          <span>Ruang buat rekan satu tim</span>
        </div>
      </section>

      <section class="about-values" aria-labelledby="values-title">
        <h2 id="values-title">Cara kami berpikir</h2>
        <div class="value-list">
          <article><span class="value-symbol" aria-hidden="true">✳</span><div><h3>Teman dulu, rank nomor dua</h3><p>Rank membantu kamu mencari pemain dengan preferensi serupa. Yang bikin sesi mabar nyaman tetap komunikasi dan saling menghargai, saat menang maupun kalah.</p></div></article>
          <article><span class="value-symbol" aria-hidden="true">◎</span><div><h3>Main aman, sama-sama nyaman</h3><p>Kamu bisa melihat profil publik sebelum mengirim ajakan. Laporkan atau blokir pengguna bila interaksi terasa tidak aman. Data rank diisi pemain sendiri dan belum terverifikasi.</p></div></article>
          <article><span class="value-symbol" aria-hidden="true">⌁</span><div><h3>Cari sesuai gaya mainmu</h3><p>Mulai dari Mobile Legends, PUBG Mobile, Free Fire, atau Valorant. Pilih game dan saring profil menurut role, mode, rank, atau region yang kamu cari.</p></div></article>
        </div>
      </section>

      <section class="about-invite" aria-labelledby="invite-title">
        <div><h2 id="invite-title">Siap cari squad sefrekuensi?</h2><p>Lengkapi profil game dan mulai kenalan dengan calon rekan mabar.</p></div>
        <div class="invite-actions"><RouterLink class="about-button" to="/register">Buat Akun Gratis</RouterLink><RouterLink class="about-secondary" to="/">Kembali ke Beranda</RouterLink></div>
      </section>
    </div>
  </main>
</template>

<style scoped>
.about-page{background:#14141c;color:#f5f3ee;padding:clamp(3rem,6vw,5.5rem) 1.25rem 6rem;font-family:Inter,system-ui,sans-serif}.about-wrap{max-width:950px;margin:auto}.about-intro{display:grid;grid-template-columns:minmax(0,1fr) 270px;align-items:center;gap:3.5rem}.about-copy{max-width:620px}.about-copy h1{font:800 clamp(2.1rem,4vw,3rem)/1.15 'Plus Jakarta Sans',sans-serif;letter-spacing:-.035em;margin:0 0 1.5rem}.about-copy p{line-height:1.8;color:#c9c8d3;margin:0 0 1rem}.about-copy .lead{font-size:1.15rem;color:#f5f3ee}.about-art{position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:280px;border-radius:24px;background:#1e1e29;border:1px solid #353541;padding:1.25rem;text-align:center;color:#c8ff4d;font-weight:700;font-size:.85rem}.about-art svg{width:min(100%,200px);height:auto}.about-values{margin:5.5rem 0}.about-values h2,.about-invite h2{font:800 clamp(1.5rem,3vw,2rem)/1.3 'Plus Jakarta Sans',sans-serif;margin:0 0 1.5rem}.value-list{display:grid;gap:1rem}.value-list article{display:flex;gap:1.5rem;align-items:flex-start;padding:1.5rem;background:#1e1e29;border:1px solid #2e2e3e;border-radius:20px}.value-symbol{display:grid;place-items:center;flex:none;width:48px;height:48px;background:#292934;border-radius:16px;color:#8b7cff;font-size:1.5rem}.value-list h3{font:700 1.08rem/1.4 'Plus Jakarta Sans',sans-serif;margin:0 0 .4rem}.value-list p{margin:0;color:#b8b6c2;line-height:1.7}.about-invite{display:flex;justify-content:space-between;align-items:center;gap:2rem;padding:2rem;background:#1e1e29;border-radius:24px}.about-invite h2{margin:0 0 .5rem}.about-invite p{margin:0;color:#b8b6c2}.invite-actions{display:flex;flex-wrap:wrap;gap:.7rem}.about-button,.about-secondary{display:inline-flex;min-height:48px;align-items:center;justify-content:center;padding:.7rem 1.3rem;border-radius:999px;font-weight:700;text-align:center;white-space:nowrap}.about-button{background:#c8ff4d;color:#14141c}.about-secondary{background:#30303e;color:#f5f3ee}.about-page a:hover{text-decoration:none}.about-page a:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:720px){.about-intro{grid-template-columns:1fr;gap:2rem}.about-art{min-height:215px}.about-art svg{width:160px}.about-invite{align-items:stretch;flex-direction:column}.invite-actions{flex-direction:column}.about-values{margin:3.5rem 0}}@media(max-width:420px){.value-list article{padding:1.1rem;gap:.9rem}.value-symbol{width:38px;height:38px}}
</style>
