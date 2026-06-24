(() => {
  "use strict";

  const canvas = document.getElementById("c");
  const gl = canvas.getContext("webgl2", { antialias: false, preserveDrawingBuffer: true });
  if (!gl) { alert("WebGL2 not available."); return; }

  const ui = document.getElementById("ui");
  const toast = document.getElementById("toast");
  const toggleBtn = document.getElementById("toggle");
  const resetBtn = document.getElementById("reset");
  const shotBtn = document.getElementById("shot");

  function $(sel){ return document.querySelector(sel); }
  function clamp(x,a,b){ return Math.max(a, Math.min(b, x)); }
  function showToast(msg){
    toast.textContent = msg;
    toast.classList.add("show");
    clearTimeout(showToast._t);
    showToast._t = setTimeout(()=> toast.classList.remove("show"), 1300);
  }

  const controls = {
    decay: $("#decay"),
    ifreq: $("#ifreq"),
    ispeed: $("#ispeed"),
    nscale: $("#nscale"),
    nstr: $("#nstr"),
    gauss: $("#gauss"),
    hturn: $("#hturn"),
    hstr: $("#hstr"),
    hspeed: $("#hspeed"),
    edyn: $("#edyn"),
    dt: $("#dt"),
    inj: $("#inj"),
    slit: $("#slit"),
    bio: $("#bio"),
  };

  const valSpans = {
    decay: $("#v_decay"),
    ifreq: $("#v_ifreq"),
    ispeed: $("#v_ispeed"),
    nscale: $("#v_nscale"),
    nstr: $("#v_nstr"),
    gauss: $("#v_gauss"),
    hturn: $("#v_hturn"),
    hstr: $("#v_hstr"),
    hspeed: $("#v_hspeed"),
    edyn: $("#v_edyn"),
    dt: $("#v_dt"),
    inj: $("#v_inj"),
    slit: $("#v_slit"),
    bio: $("#v_bio"),
  };

  function readParams(){
    const p = {};
    for (const k in controls) p[k] = parseFloat(controls[k].value);
    return p;
  }
  function refreshLabels(p){
    valSpans.decay.textContent = p.decay.toFixed(4);
    valSpans.ifreq.textContent = p.ifreq.toFixed(0);
    valSpans.ispeed.textContent = p.ispeed.toFixed(2);
    valSpans.nscale.textContent = p.nscale.toFixed(2);
    valSpans.nstr.textContent = p.nstr.toFixed(2);
    valSpans.gauss.textContent = p.gauss.toFixed(3);
    valSpans.hturn.textContent = p.hturn.toFixed(0);
    valSpans.hstr.textContent = p.hstr.toFixed(2);
    valSpans.hspeed.textContent = p.hspeed.toFixed(2);
    valSpans.edyn.textContent = p.edyn.toFixed(3);
    valSpans.dt.textContent = p.dt.toFixed(4);
    valSpans.inj.textContent = p.inj.toFixed(3);
    valSpans.slit.textContent = p.slit.toFixed(3);
    valSpans.bio.textContent = p.bio.toFixed(3);
  }
  for (const k in controls) controls[k].addEventListener("input", ()=> refreshLabels(readParams()));

  toggleBtn.addEventListener("click", ()=>{
    ui.classList.toggle("collapsed");
    toggleBtn.textContent = ui.classList.contains("collapsed") ? "Expand" : "Collapse";
  });

  function screenshot(){
    const a = document.createElement("a");
    a.download = "manifold-sim-v2.png";
    a.href = canvas.toDataURL("image/png");
    a.click();
    showToast("Screenshot saved.");
  }
  shotBtn.addEventListener("click", screenshot);

  let paused = false;
  window.addEventListener("keydown", (e)=>{
    if (e.code === "Space"){ paused = !paused; showToast(paused ? "Paused." : "Running."); }
    if (e.key === "r" || e.key === "R"){ hardReset(); }
    if (e.key === "s" || e.key === "S"){ screenshot(); }
  });

  // ---- GL helpers
  function compile(type, src){
    const s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      const info = gl.getShaderInfoLog(s);
      console.error(info);
      throw new Error(info);
    }
    return s;
  }
  function program(vsSrc, fsSrc){
    const p = gl.createProgram();
    gl.attachShader(p, compile(gl.VERTEX_SHADER, vsSrc));
    gl.attachShader(p, compile(gl.FRAGMENT_SHADER, fsSrc));
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) {
      const info = gl.getProgramInfoLog(p);
      console.error(info);
      throw new Error(info);
    }
    return p;
  }

  const quadVS = `#version 300 es
  precision highp float;
  layout(location=0) in vec2 aPos;
  out vec2 vUv;
  void main(){
    vUv = aPos*0.5 + 0.5;
    gl_Position = vec4(aPos, 0.0, 1.0);
  }`;

  // State texture channels:
  // R,G : flow hint (vector)
  // B   : intensity/energy proxy ρ (can be negative for signed contrast)
  // A   : phase proxy φ in [0,1)
  const updateFS = `#version 300 es
  precision highp float;
  in vec2 vUv;
  out vec4 o;

  uniform sampler2D uState;
  uniform vec2 uRes;
  uniform float uTime;
  uniform float uSeed;

  uniform float uDecay;
  uniform float uInterFreq;
  uniform float uInterSpeed;
  uniform float uNoiseScale;
  uniform float uNoiseStrength;
  uniform float uGaussian;       // blend to Gaussian-like forcing
  uniform float uHelixTurns;
  uniform float uHelixStrength;
  uniform float uHelixSpeed;
  uniform float uEDyn;           // electrodynamic coupling (phase↔flow)
  uniform float uBio;
  uniform float uDt;
  uniform float uInject;
  uniform float uSlitSep;

  uniform vec2 uPointer;
  uniform vec2 uPointerVel;
  uniform float uPointerDown;

  float hash12(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
  }

  float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash12(i + vec2(0,0));
    float b = hash12(i + vec2(1,0));
    float c = hash12(i + vec2(0,1));
    float d = hash12(i + vec2(1,1));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
  }

  vec2 gradNoise(vec2 p){
    float e = 1.0/uRes.x;
    float n1 = noise(p + vec2(e,0));
    float n2 = noise(p - vec2(e,0));
    float n3 = noise(p + vec2(0,e));
    float n4 = noise(p - vec2(0,e));
    return vec2(n1-n2, n3-n4) / (2.0*e);
  }

  vec2 curl(vec2 p){
    vec2 g = gradNoise(p);
    return normalize(vec2(g.y, -g.x) + 1e-6);
  }

  // Approx Gaussian(0,1) via CLT: sum of uniforms
  float gauss01(vec2 p){
    float s = 0.0;
    s += hash12(p + vec2( 0.0,  0.0));
    s += hash12(p + vec2( 7.1,  3.3));
    s += hash12(p + vec2(-2.8,  9.7));
    s += hash12(p + vec2(12.4, -6.9));
    s += hash12(p + vec2(-9.2, -1.7));
    s += hash12(p + vec2( 4.6, 11.8));
    // n=6 uniforms: mean=3, var=n/12=0.5
    float z = (s - 3.0) / sqrt(0.5);
    return z; // mean 0, var ~1
  }

  float doubleSlit(vec2 p, float sep){
    float gate = exp(-p.x*p.x*18.0);
    float w = 0.015 + 0.02*uBio;
    float s1 = exp(-pow(p.y - sep, 2.0)/(w*w));
    float s2 = exp(-pow(p.y + sep, 2.0)/(w*w));
    return gate * (s1 + s2);
  }

  void main(){
    vec4 prev = texture(uState, vUv);
    vec2 p = vUv*2.0 - 1.0;

    float r = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    // Helical symmetry field (cyclic + drift): phase-like generator
    float helix = sin(ang*uHelixTurns + log(r+1.0)*uHelixTurns*0.7 - uTime*uHelixSpeed);
    vec2 helixDir = normalize(vec2(-p.y, p.x));
    vec2 flow = helixDir * helix * uHelixStrength;

    // Chaotic environment via curl noise (approx divergence-free)
    vec2 nP = (p*0.5 + 0.5) * uNoiseScale + vec2(uSeed*10.0, uTime*0.08);
    vec2 c = curl(nP);
    flow += c * uNoiseStrength;

    // Pointer stirring (impulse)
    if (uPointerDown > 0.5){
      vec2 dp = (vUv - uPointer);
      float d = dot(dp,dp);
      float k = exp(-d * 120.0);
      flow += (uPointerVel / uRes) * (k * 35.0);
    }

    // Electrodynamic coupling proxy:
    // treat phase gradients as an effective "field" that nudges flow (toy J×B-like swirl).
    float ph = prev.a * 6.2831853;
    vec2 phGrad = gradNoise(nP + vec2(cos(ph), sin(ph))*0.7);
    flow += vec2(phGrad.y, -phGrad.x) * (0.20*uEDyn);

    // Advect previous state
    vec2 advUv = fract(vUv - flow * uDt);
    vec4 adv = texture(uState, advUv);

    // Interference lattice (toy superposition cross-term)
    float slit = doubleSlit(p, uSlitSep);
    float w1 = sin((p.x + 0.12*sin(uTime*0.17))*uInterFreq + uTime*uInterSpeed);
    float w2 = sin((p.y + 0.12*cos(uTime*0.11))*uInterFreq - uTime*uInterSpeed*0.9);
    float inter = w1*w2;

    float phase = adv.a + 0.015*inter + 0.010*uEDyn*(adv.b);
    phase = fract(phase);

    // Stochastic forcing: blend uniform-ish and Gaussian-ish noise
    float uni = noise(nP*1.3 + uTime*0.2) - 0.5;
    float gau = gauss01(nP*2.1 + uTime*0.07);
    float stochastic = mix(uni, gau, uGaussian);

    // Thermo bookkeeping: density/energy decays (entropy), injected by slit+interference, driven by noise
    float dens = adv.b;
    dens = dens * (1.0 - uDecay) + (inter*slit) * uInject * 0.35;
    dens += stochastic * 0.018 * (0.2 + uNoiseStrength);

    // Mild nonlinear saturation (prevents blowups and gives texture)
    dens = tanh(dens * 1.15);

    vec2 storedFlow = mix(prev.rg, flow, 0.08);
    o = vec4(storedFlow, dens, phase);
  }`;

  const renderFS = `#version 300 es
  precision highp float;
  in vec2 vUv;
  out vec4 o;

  uniform sampler2D uState;
  uniform float uTime;
  uniform float uBio;
  uniform float uInterFreq;
  uniform float uInterSpeed;

  vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1., 2./3., 1./3., 3.);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
  }

  float vignette(vec2 uv){
    vec2 p = uv*2.0 - 1.0;
    float r = dot(p,p);
    return smoothstep(1.25, 0.12, r);
  }

  void main(){
    vec4 s = texture(uState, vUv);
    vec2 p = vUv*2.0 - 1.0;

    float energy = s.b;
    float phase = s.a;

    float w1 = sin((p.x + 0.12*sin(uTime*0.17))*uInterFreq + uTime*uInterSpeed);
    float w2 = sin((p.y + 0.12*cos(uTime*0.11))*uInterFreq - uTime*uInterSpeed*0.9);
    float inter = w1*w2;

    float cosmicHue = 0.62 + 0.18*sin(phase*6.283 + energy*1.7);
    float bioHue    = 0.08 + 0.10*sin(phase*6.283 + energy*2.3);
    float hue = mix(cosmicHue, bioHue, uBio);

    float sat = mix(0.62, 0.93, uBio) * (0.65 + 0.35*abs(energy));
    float val = 0.14 + 0.86*pow(clamp(abs(energy), 0.0, 1.0), 0.78);

    float glow = 0.35 + 0.65*pow(abs(inter), 1.35);
    val *= mix(0.85, 1.28, glow*0.55);

    vec3 col = hsv2rgb(vec3(fract(hue), clamp(sat,0.,1.), clamp(val,0.,1.)));
    vec3 col2 = hsv2rgb(vec3(fract(hue + 0.06), clamp(sat,0.,1.), clamp(val*0.92,0.,1.)));
    col = mix(col, col2, 0.35 + 0.35*abs(s.r));

    col *= vignette(vUv);
    o = vec4(col, 1.0);
  }`;

  // ---- buffers
  const quad = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, quad);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, -1,1, 1,-1, 1,1]), gl.STATIC_DRAW);

  const updateProg = program(quadVS, updateFS);
  const renderProg = program(quadVS, renderFS);

  function uLoc(p, n){ return gl.getUniformLocation(p, n); }
  const U = {
    // update uniforms
    uState: uLoc(updateProg, "uState"),
    uRes: uLoc(updateProg, "uRes"),
    uTime: uLoc(updateProg, "uTime"),
    uSeed: uLoc(updateProg, "uSeed"),
    uDecay: uLoc(updateProg, "uDecay"),
    uInterFreq: uLoc(updateProg, "uInterFreq"),
    uInterSpeed: uLoc(updateProg, "uInterSpeed"),
    uNoiseScale: uLoc(updateProg, "uNoiseScale"),
    uNoiseStrength: uLoc(updateProg, "uNoiseStrength"),
    uGaussian: uLoc(updateProg, "uGaussian"),
    uHelixTurns: uLoc(updateProg, "uHelixTurns"),
    uHelixStrength: uLoc(updateProg, "uHelixStrength"),
    uHelixSpeed: uLoc(updateProg, "uHelixSpeed"),
    uEDyn: uLoc(updateProg, "uEDyn"),
    uBio: uLoc(updateProg, "uBio"),
    uDt: uLoc(updateProg, "uDt"),
    uInject: uLoc(updateProg, "uInject"),
    uSlitSep: uLoc(updateProg, "uSlitSep"),
    uPointer: uLoc(updateProg, "uPointer"),
    uPointerVel: uLoc(updateProg, "uPointerVel"),
    uPointerDown: uLoc(updateProg, "uPointerDown"),
    // render uniforms
    rState: uLoc(renderProg, "uState"),
    rTime: uLoc(renderProg, "uTime"),
    rBio: uLoc(renderProg, "uBio"),
    rInterFreq: uLoc(renderProg, "uInterFreq"),
    rInterSpeed: uLoc(renderProg, "uInterSpeed"),
  };

  // ---- sizing
  let simW = 512, simH = 512;
  function pickSimRes(){
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const w = Math.floor(window.innerWidth * dpr);
    const h = Math.floor(window.innerHeight * dpr);
    const target = Math.max(w,h) > 1800 ? 768 : 512;
    simW = target;
    simH = target;
  }
  pickSimRes();

  function tex(w,h){
    const t = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, t);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, w, h, 0, gl.RGBA, gl.HALF_FLOAT, null);
    return t;
  }
  function fbo(t){
    const fb = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t, 0);
    return fb;
  }

  let tA = tex(simW, simH), tB = tex(simW, simH);
  let fA = fbo(tA), fB = fbo(tB);

  // Check float renderability
  const extColor = gl.getExtension("EXT_color_buffer_float");
  if (!extColor){
    console.warn("EXT_color_buffer_float missing. If you see a black screen, try another browser/device.");
    showToast("Warning: float framebuffer extension missing on this device.");
  }

  // init texture with small random field
  function seedTexture(seed){
    const data = new Float32Array(simW*simH*4);
    let s = seed|0;
    function rnd(){ s ^= s<<13; s ^= s>>>17; s ^= s<<5; return ((s>>>0) / 4294967296); }
    for (let i=0;i<data.length;i+=4){
      const a = rnd()*2-1;
      const b = rnd()*2-1;
      const d = (rnd()*2-1)*0.1;
      const ph = rnd();
      data[i+0] = a*0.05;
      data[i+1] = b*0.05;
      data[i+2] = d;
      data[i+3] = ph;
    }
    gl.bindTexture(gl.TEXTURE_2D, tA);
    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0,0, simW, simH, gl.RGBA, gl.FLOAT, data);
    gl.bindTexture(gl.TEXTURE_2D, tB);
    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0,0, simW, simH, gl.RGBA, gl.FLOAT, data);
  }

  // ---- interaction
  let pointerDown = false;
  let pointerUv = [0.5, 0.5];
  let pointerVel = [0, 0];
  let lastPointer = null;

  function setPointer(e){
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const y = 1.0 - (e.clientY - rect.top) / rect.height;
    pointerVel[0] = 0; pointerVel[1] = 0;
    if (lastPointer){
      pointerVel[0] = (x - lastPointer[0]) * simW;
      pointerVel[1] = (y - lastPointer[1]) * simH;
    }
    lastPointer = [x,y];
    pointerUv[0] = clamp(x, 0, 1);
    pointerUv[1] = clamp(y, 0, 1);
  }

  canvas.addEventListener("pointerdown", (e)=>{
    pointerDown = true;
    lastPointer = null;
    canvas.setPointerCapture(e.pointerId);
    setPointer(e);
  });
  canvas.addEventListener("pointermove", (e)=>{
    if (!pointerDown) return;
    setPointer(e);
  });
  canvas.addEventListener("pointerup", ()=>{ pointerDown = false; lastPointer = null; });
  canvas.addEventListener("pointercancel", ()=>{ pointerDown = false; lastPointer = null; });

  // ---- resize
  function resize(){
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.floor(window.innerWidth * dpr);
    canvas.height = Math.floor(window.innerHeight * dpr);
    canvas.style.width = "100vw";
    canvas.style.height = "100vh";
    gl.viewport(0,0, canvas.width, canvas.height);
  }
  window.addEventListener("resize", resize);

  // ---- setup draw
  gl.disable(gl.DEPTH_TEST);
  gl.disable(gl.BLEND);
  gl.bindBuffer(gl.ARRAY_BUFFER, quad);

  function bindQuad(prog){
    gl.useProgram(prog);
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
  }

  let seed = (Math.random()*1e9) | 0;
  seedTexture(seed);

  function hardReset(){
    seed = (Math.random()*1e9) | 0;
    seedTexture(seed);
    showToast("Reset field.");
  }
  resetBtn.addEventListener("click", hardReset);

  resize();
  refreshLabels(readParams());

  let t = 0;
  let lastT = performance.now();

  function step(now){
    const dtMs = now - lastT;
    lastT = now;
    if (!paused) t += dtMs * 0.001;

    const p = readParams();

    // update pass (A -> B)
    gl.bindFramebuffer(gl.FRAMEBUFFER, fB);
    gl.viewport(0,0, simW, simH);
    bindQuad(updateProg);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, tA);
    gl.uniform1i(U.uState, 0);

    gl.uniform2f(U.uRes, simW, simH);
    gl.uniform1f(U.uTime, t);
    gl.uniform1f(U.uSeed, seed / 1e9);

    gl.uniform1f(U.uDecay, p.decay);
    gl.uniform1f(U.uInterFreq, p.ifreq);
    gl.uniform1f(U.uInterSpeed, p.ispeed);
    gl.uniform1f(U.uNoiseScale, p.nscale);
    gl.uniform1f(U.uNoiseStrength, p.nstr);
    gl.uniform1f(U.uGaussian, p.gauss);
    gl.uniform1f(U.uHelixTurns, p.hturn);
    gl.uniform1f(U.uHelixStrength, p.hstr);
    gl.uniform1f(U.uHelixSpeed, p.hspeed);
    gl.uniform1f(U.uEDyn, p.edyn);
    gl.uniform1f(U.uBio, p.bio);
    gl.uniform1f(U.uDt, p.dt);
    gl.uniform1f(U.uInject, p.inj);
    gl.uniform1f(U.uSlitSep, p.slit);

    gl.uniform2f(U.uPointer, pointerUv[0], pointerUv[1]);
    gl.uniform2f(U.uPointerVel, pointerVel[0], pointerVel[1]);
    gl.uniform1f(U.uPointerDown, pointerDown ? 1.0 : 0.0);

    gl.drawArrays(gl.TRIANGLES, 0, 6);

    // swap buffers
    [tA, tB] = [tB, tA];
    [fA, fB] = [fB, fA];

    // render to canvas
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.viewport(0,0, canvas.width, canvas.height);
    bindQuad(renderProg);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, tA);
    gl.uniform1i(U.rState, 0);
    gl.uniform1f(U.rTime, t);
    gl.uniform1f(U.rBio, p.bio);
    gl.uniform1f(U.rInterFreq, p.ifreq);
    gl.uniform1f(U.rInterSpeed, p.ispeed);

    gl.drawArrays(gl.TRIANGLES, 0, 6);

    pointerVel[0] *= 0.6; pointerVel[1] *= 0.6;
    requestAnimationFrame(step);
  }

  requestAnimationFrame(step);
})();