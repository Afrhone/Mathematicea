async function boot() {
  const out = document.getElementById("out");
  try {
    const h = await fetch("/health").then(r => r.json());
    const a = await fetch("/archetype").then(r => r.json());
    out.textContent = JSON.stringify({ health: h, archetype: a }, null, 2);
  } catch (e) {
    out.textContent = String(e);
  }
}
boot();
