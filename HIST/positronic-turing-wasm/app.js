const $ = id => document.getElementById(id);
const canvas = $('scope');
const ctx = canvas.getContext('2d');
const controls = ['bloom','rings','magneto','beads','learning'].reduce((o,k)=>(o[k]=$(k),o),{});
const errEl = $('err');
const stateEl = $('state');
let wasm, audioCtx, analyser, data, oscA, oscB, gain, delay, feedback, filter;
let last = performance.now();
let audioLevel = 0;

function resize(){
  const dpr = Math.min(devicePixelRatio || 1, 2);
  const r = canvas.getBoundingClientRect();
  canvas.width = Math.floor(r.width*dpr);
  canvas.height = Math.floor(r.height*dpr);
}
addEventListener('resize', resize);
resize();

async function loadWasm(){
  const bytes = await fetch('ptm.wasm').then(r => r.arrayBuffer());
  const mod = await WebAssembly.instantiate(bytes, {});
  wasm = mod.instance.exports;
  wasm.init(Number($('seed').value) >>> 0);
}

function ui(name){ return Number(controls[name].value); }

function draw(){
  const W = canvas.width, H = canvas.height;
  ctx.clearRect(0,0,W,H);
  const n = wasm.size();
  const mid = H * 0.52;
  const amp = H * 0.25;

  const grd = ctx.createRadialGradient(W*.5,H*.45,10,W*.5,H*.45,Math.max(W,H)*.6);
  grd.addColorStop(0, 'rgba(160,120,255,.18)');
  grd.addColorStop(0.45, 'rgba(80,180,255,.08)');
  grd.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.fillStyle = grd;
  ctx.fillRect(0,0,W,H);

  // tape ribbon
  ctx.lineWidth = Math.max(1, W/700);
  for(let layer=0; layer<4; layer++){
    ctx.beginPath();
    for(let i=0;i<n;i++){
      const x = i/(n-1)*W;
      const v = wasm.cell(i);
      const a = wasm.attention(i);
      const q = wasm.charge(i);
      const y = mid + v*amp + Math.sin(i*.18 + performance.now()*.0004 + layer)*q*amp*.12;
      if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
    }
    ctx.strokeStyle = `rgba(${160+layer*20}, ${190-layer*16}, 255, ${0.16+layer*.08})`;
    ctx.stroke();
  }

  // cells / positronic sparks
  for(let i=0;i<n;i++){
    const x = i/(n-1)*W;
    const v = wasm.cell(i);
    const a = wasm.attention(i);
    const q = wasm.charge(i);
    const e = wasm.energy(i);
    const y = mid + v*amp;
    const r = 1 + 34*a + 2.5*q + Math.min(16,e*2);
    ctx.beginPath();
    ctx.arc(x,y,r,0,Math.PI*2);
    ctx.fillStyle = `hsla(${260 + v*90 + q*80}, 95%, ${50+q*28}%, ${0.09 + Math.min(.7,a*18)})`;
    ctx.fill();
  }

  // state petals
  const sx = W*.5, sy = H*.17, R = Math.min(W,H)*.1;
  for(let s=0;s<wasm.states();s++){
    const p = wasm.state(s);
    const ang = s/wasm.states()*Math.PI*2 - Math.PI/2;
    ctx.beginPath();
    ctx.arc(sx+Math.cos(ang)*R, sy+Math.sin(ang)*R, 8+p*70, 0, Math.PI*2);
    ctx.fillStyle = `hsla(${40+s*38}, 95%, 70%, ${0.12+p*.9})`;
    ctx.fill();
  }
}

function tick(now){
  const dt = Math.min(0.04, (now-last)/1000); last = now;
  if(analyser && data){
    analyser.getByteFrequencyData(data);
    audioLevel = data.reduce((a,b)=>a+b,0)/(data.length*255);
  } else {
    audioLevel = 0.35 + Math.sin(now*.0007)*0.2;
  }
  const error = wasm.step(dt, audioLevel, ui('bloom'), ui('rings'), ui('magneto'), ui('beads'), ui('learning'));
  errEl.textContent = error.toFixed(4);
  const states = Array.from({length: wasm.states()}, (_,i)=>wasm.state(i).toFixed(2)).join(' · ');
  stateEl.textContent = states;
  if(gain){
    gain.gain.setTargetAtTime(0.05 + Math.abs(error)*0.05, audioCtx.currentTime, .1);
    filter.frequency.setTargetAtTime(240 + ui('bloom')*1200 + audioLevel*900, audioCtx.currentTime, .2);
    delay.delayTime.setTargetAtTime(0.15 + ui('rings')*.55, audioCtx.currentTime, .2);
    oscA.frequency.setTargetAtTime(48 + ui('magneto')*32 + Math.abs(error)*18, audioCtx.currentTime, .1);
    oscB.frequency.setTargetAtTime(96 + ui('beads')*144 + audioLevel*70, audioCtx.currentTime, .1);
  }
  draw();
  requestAnimationFrame(tick);
}

async function startAudio(){
  if(audioCtx) return;
  audioCtx = new AudioContext();
  analyser = audioCtx.createAnalyser(); analyser.fftSize = 512; data = new Uint8Array(analyser.frequencyBinCount);
  oscA = audioCtx.createOscillator(); oscA.type = 'triangle';
  oscB = audioCtx.createOscillator(); oscB.type = 'sine';
  gain = audioCtx.createGain(); gain.gain.value = 0.03;
  filter = audioCtx.createBiquadFilter(); filter.type = 'lowpass'; filter.frequency.value = 700;
  delay = audioCtx.createDelay(1.2); delay.delayTime.value = .35;
  feedback = audioCtx.createGain(); feedback.gain.value = .34;
  oscA.connect(filter); oscB.connect(filter); filter.connect(gain); gain.connect(delay); delay.connect(feedback); feedback.connect(delay);
  gain.connect(analyser); delay.connect(analyser); analyser.connect(audioCtx.destination);
  oscA.start(); oscB.start();
  $('audio').textContent = 'Audio running';
}

$('audio').onclick = startAudio;
$('reset').onclick = () => wasm.init(Number($('seed').value) >>> 0);
loadWasm().then(()=>requestAnimationFrame(tick));
