'use strict';
(() => {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => entries.forEach(entry => {
      if (entry.isIntersecting) { entry.target.classList.add('visible'); observer.unobserve(entry.target); }
    }), { threshold: 0.10 });
    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
    document.documentElement.classList.add('js-ready');
  }
  const panel = document.querySelector('.appearance');
  const image = document.getElementById('theme-screen');
  const label = document.getElementById('selection-label');
  const names = {viola:'Viola',blu:'Blu',turchese:'Turchese',verde:'Verde',rosa:'Rosa',corallo:'Corallo',ambra:'Ambra',grafite:'Grafite'};
  const accents = {viola:'#9750e8',blu:'#2876dd',turchese:'#008b8b',verde:'#29834b',rosa:'#c63e85',corallo:'#c64c40',ambra:'#a86b09',grafite:'#646474'};
  let mode = 'dark', color = 'viola', revision = 0;
  const cache = new Map();
  const path = (m,c) => `showcase/themes/${m}-${c}.jpg`;
  function load(src) {
    if (cache.has(src)) return cache.get(src);
    const promise = new Promise((resolve,reject) => { const next = new Image(); next.onload = () => resolve(next); next.onerror = reject; next.src = src; });
    cache.set(src,promise); return promise;
  }
  async function update() {
    const request = ++revision, selectedMode = mode, selectedColor = color;
    document.querySelectorAll('.mode-picker button').forEach(button => button.setAttribute('aria-pressed',String(button.dataset.mode === mode)));
    document.querySelectorAll('.swatches button').forEach(button => button.setAttribute('aria-pressed',String(button.dataset.color === color)));
    label.textContent = `${names[color]} · ${mode === 'dark' ? 'Scuro' : 'Chiaro'} — caricamento`;
    image.setAttribute('aria-busy','true');
    try {
      const next = await load(path(selectedMode,selectedColor));
      if (request !== revision) return;
      image.src = next.src; image.alt = `Home AURA — ${names[color]}, tema ${mode === 'dark' ? 'scuro' : 'chiaro'}`;
      panel.dataset.mode = mode; panel.style.setProperty('--selected',accents[color]);
      label.textContent = `${names[color]} · ${mode === 'dark' ? 'Scuro' : 'Chiaro'}`;
    } catch (_) {
      if (request === revision) label.textContent = 'Immagine non disponibile. Riprova scegliendo un colore.';
    } finally { if (request === revision) image.removeAttribute('aria-busy'); }
  }
  document.querySelectorAll('.mode-picker button').forEach(button => button.addEventListener('click',() => { mode = button.dataset.mode; update(); }));
  document.querySelectorAll('.swatches button').forEach(button => button.addEventListener('click',() => { color = button.dataset.color; update(); }));
  // Only prefetch after the appearance section approaches the viewport.
  if ('IntersectionObserver' in window) {
    const prefetch = new IntersectionObserver(entries => { if (entries.some(e => e.isIntersecting)) { Object.keys(names).forEach(c => ['dark','light'].forEach(m => load(path(m,c)).catch(() => {}))); prefetch.disconnect(); } }, {rootMargin:'400px'});
    prefetch.observe(panel);
  }
  const stage = document.querySelector('.device-stage');
  let ticking = false;
  function draw() { ticking = false; if (reduced.matches) { stage.style.removeProperty('--scroll'); return; } const rect = stage.getBoundingClientRect(); stage.style.setProperty('--scroll',String(Math.max(-1,Math.min(1,(innerHeight * .5 - rect.top) / innerHeight)))); }
  addEventListener('scroll',() => { if (!ticking) { ticking = true; requestAnimationFrame(draw); } },{passive:true});
  reduced.addEventListener('change',draw); draw();
})();
