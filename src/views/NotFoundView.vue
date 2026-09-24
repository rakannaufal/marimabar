<template>
  <main class="missing-page">
    <div class="missing-card">
      <div class="missing-head">
        <svg class="mascot" viewBox="0 0 120 120" fill="none" role="img" aria-label="Maskot game mencari lobi">
          <path d="M22 62c0-21 17-38 38-38s38 17 38 38" stroke="#8B7CFF" stroke-width="6" stroke-linecap="round"/>
          <circle cx="60" cy="66" r="36" fill="#30303E"/>
          <rect x="14" y="52" width="12" height="26" rx="6" fill="#8B7CFF"/><rect x="94" y="52" width="12" height="26" rx="6" fill="#8B7CFF"/>
          <circle cx="45" cy="64" r="5" fill="#F5F3EE"/><circle cx="47" cy="62" r="2" fill="#14141C"/>
          <path d="M72 64c0-6 9-6 9 0s-9 6-7 2" stroke="#C8FF4D" stroke-width="2.5" stroke-linecap="round"/>
          <path d="M54 78q3-3 6-1t6-1" stroke="#F5F3EE" stroke-width="2.5" stroke-linecap="round"/>
          <path d="M26 74c0 12 10 20 26 20" stroke="#C8FF4D" stroke-width="4" stroke-linecap="round"/><circle cx="54" cy="94" r="4" fill="#8B7CFF"/>
        </svg>
        <span class="missing-status">Lobi tidak ditemukan</span>
      </div>
      <div class="error-number" aria-label="Kesalahan 404">404</div>
      <h1>Waduh, halaman ini nggak ketemu</h1>
      <p>Mungkin alamatnya keliru atau halaman yang kamu tuju sudah pindah. Yuk, balik ke tempat nongkrong utama dan cari teman mabar lagi.</p>
      <div class="missing-actions"><RouterLink class="home-action" to="/">Kembali ke Beranda</RouterLink><RouterLink class="discover-action" to="/cari/mlbb">Cari teman Mobile Legends</RouterLink></div>
      <div class="missing-footer"><RouterLink to="/tentang">Kenalan dengan Mabar Finder</RouterLink></div>
    </div>
  </main>
</template>

<style scoped>
.missing-page{min-height:75vh;display:grid;place-items:center;background:#14141c;color:#f5f3ee;padding:3.5rem 1rem 5rem;font-family:Inter,system-ui,sans-serif}.missing-card{width:min(100%,480px);padding:clamp(1.5rem,4vw,2.2rem);background:#1e1e29;border:1px solid #353541;border-radius:28px;box-shadow:0 18px 45px #09091066}.missing-head{display:flex;align-items:flex-start;justify-content:space-between;gap:1rem}.mascot{height:115px;width:115px;flex:none}.missing-status{border:1px solid #454454;background:#292934;border-radius:999px;color:#c9c8d3;padding:.45rem .85rem;font-size:.75rem;white-space:nowrap}.error-number{font:800 clamp(3.4rem,7vw,4.8rem)/1.1 'Plus Jakarta Sans',sans-serif;color:#c8ff4d;letter-spacing:-.05em;margin:1rem 0 .25rem}.missing-card h1{font:800 clamp(1.4rem,3vw,1.7rem)/1.3 'Plus Jakarta Sans',sans-serif;letter-spacing:-.03em;margin:0 0 .8rem}.missing-card p{color:#c9c8d3;line-height:1.7;margin:0 0 1.6rem}.missing-actions{display:grid;gap:.65rem}.missing-actions a{display:grid;place-items:center;text-align:center;border-radius:999px;min-height:48px;padding:.6rem 1rem;font-weight:700}.home-action{background:#c8ff4d;color:#14141c}.discover-action{background:#30303e;color:#f5f3ee}.missing-footer{border-top:1px solid #3b3b47;margin-top:1.5rem;padding-top:1.1rem;font-size:.82rem}.missing-footer a{color:#c9c8d3}.missing-page a:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:390px){.mascot{width:90px;height:90px}.missing-status{font-size:.67rem;padding:.35rem .6rem}}
</style>
