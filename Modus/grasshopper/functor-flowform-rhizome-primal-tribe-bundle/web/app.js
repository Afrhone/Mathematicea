async function boot() {
  const out = document.getElementById("out");
  out.textContent = JSON.stringify({
    badge: "YETI-715",
    handshake: "axiom-stem-raven",
    law: "No retry without a gate."
  }, null, 2);
}
boot();
