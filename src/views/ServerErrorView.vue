<script setup lang="ts">
function reloadPage() { window.location.reload() }
</script>

<template>
  <main class="error-page">
    <div class="error-card">
      <div class="art-panel" role="img" aria-label="Maskot game memeriksa server dengan kabel terlepas">
        <svg viewBox="0 0 240 200" fill="none" aria-hidden="true">
          <rect x="146" y="88" width="62" height="78" rx="8" fill="#30303E"/>
          <rect x="154" y="98" width="46" height="8" rx="3" fill="#14141C"/><circle cx="192" cy="102" r="2" fill="#C8FF4D"/>
          <rect x="154" y="112" width="46" height="8" rx="3" fill="#14141C"/><circle cx="192" cy="116" r="2" fill="#8B7CFF"/>
          <rect x="154" y="126" width="46" height="8" rx="3" fill="#14141C"/><circle cx="192" cy="130" r="2" fill="#C8FF4D"/>
          <path d="M154 148c-22 4-36 20-28 30m0 0 6-4m-6 4 2-10" stroke="#8B7CFF" stroke-width="4" stroke-linecap="round"/>
          <rect x="52" y="78" width="76" height="72" rx="22" fill="#30303E"/>
          <path d="M44 86c0-34 92-34 92 0" stroke="#8B7CFF" stroke-width="7" stroke-linecap="round"/>
          <rect x="40" y="80" width="10" height="24" rx="5" fill="#C8FF4D"/><rect x="130" y="80" width="10" height="24" rx="5" fill="#C8FF4D"/>
          <rect x="62" y="92" width="56" height="34" rx="10" fill="#14141C"/>
          <path d="m72 105 8 4m0-4-8 4" stroke="#C8FF4D" stroke-width="2.5" stroke-linecap="round"/><circle cx="104" cy="107" r="3.5" fill="#C8FF4D"/>
          <path d="M106 132h20" stroke="#C8FF4D" stroke-width="4" stroke-linecap="round"/>
        </svg>
      </div>
      <div class="error-badge">500</div>
      <h1>Ada yang nggak beres di server kami</h1>
      <p>Halaman ini belum bisa dimuat. Coba muat ulang; kalau masih gagal, kamu bisa kembali ke beranda dan mencoba lagi nanti.</p>
      <div class="error-actions"><RouterLink class="primary-action" to="/">Kembali ke Beranda</RouterLink><button class="secondary-action" type="button" @click="reloadPage">Coba Muat Ulang</button></div>
      <div class="error-foot"><span>Masih bermasalah? Coba lagi nanti.</span><RouterLink to="/tentang">Tentang Mabar Finder</RouterLink></div>
    </div>
  </main>
</template>

<style scoped>
.error-page{min-height:75vh;display:grid;place-items:center;background:#14141c;color:#f5f3ee;padding:3.5rem 1rem 5rem;font-family:Inter,system-ui,sans-serif}.error-card{width:min(100%,480px);padding:clamp(1.4rem,4vw,2rem);background:#1e1e29;border:1px solid #353541;border-radius:28px;box-shadow:0 18px 45px #09091066}.art-panel{display:grid;place-items:center;height:180px;background:#1b1b23;border-radius:18px;margin-bottom:1.5rem}.art-panel svg{height:165px;width:auto;max-width:100%}.error-badge{display:inline-flex;align-items:center;justify-content:center;padding:.3rem 1rem;border-radius:999px;background:#c8ff4d;color:#14141c;font:800 1.1rem 'Plus Jakarta Sans',sans-serif;margin-bottom:1rem}.error-card h1{font:800 clamp(1.5rem,3vw,1.9rem)/1.3 'Plus Jakarta Sans',sans-serif;letter-spacing:-.03em;margin:0 0 .8rem}.error-card p{line-height:1.7;color:#c9c8d3;margin:0 0 1.5rem}.error-actions{display:flex;gap:.65rem;flex-wrap:wrap}.error-actions a,.error-actions button{display:inline-flex;align-items:center;justify-content:center;min-height:48px;border-radius:999px;padding:.6rem 1.1rem;font:700 .9rem Inter,system-ui,sans-serif;text-align:center;border:0}.error-actions .primary-action{background:#c8ff4d;color:#14141c}.error-actions .secondary-action{background:#30303e;color:#f5f3ee;cursor:pointer}.error-foot{display:flex;align-items:center;justify-content:space-between;gap:.8rem;flex-wrap:wrap;border-top:1px solid #3b3b47;margin-top:1.5rem;padding-top:1.1rem;color:#b8b6c2;font-size:.78rem}.error-foot a{color:#c8ff4d}.error-page a:focus-visible,.error-page button:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:460px){.error-actions{flex-direction:column}.error-actions a,.error-actions button{width:100%}}
</style>
