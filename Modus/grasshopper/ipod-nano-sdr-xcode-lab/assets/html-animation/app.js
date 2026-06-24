const canvas = document.getElementById('field');
const gl = canvas.getContext('webgl2');
const statsEl = document.getElementById('stats');
const img = document.getElementById('spectrogram');
let frozen = false, pulse = 0, audio = false, audioLevel = 0;

function resize(){
  const dpr = Math.min(devicePixelRatio || 1, 2);
  canvas.width = Math.floor(canvas.clientWidth * dpr);
  canvas.height = Math.floor(canvas.clientHeight * dpr);
  gl.viewport(0,0,canvas.width,canvas.height);
}
addEventListener('resize', resize); resize();

const vs = `#version 300 es
precision highp float;
const vec2 p[3]=vec2[](vec2(-1.,-1.),vec2(3.,-1.),vec2(-1.,3.));
void main(){gl_Position=vec4(p[gl_VertexID],0.,1.);} `;
const fs = `#version 300 es
precision highp float;
out vec4 o;
uniform vec2 r; uniform float t; uniform float pulse; uniform float audio;
float hash(vec3 p){return fract(sin(dot(p,vec3(17.1,113.5,41.7)))*43758.5453);} 
float noise(vec3 p){vec3 i=floor(p), f=fract(p); f=f*f*(3.-2.*f); float n=0.; for(int x=0;x<2;x++)for(int y=0;y<2;y++)for(int z=0;z<2;z++){vec3 q=vec3(x,y,z); n+=mix(0.,hash(i+q),1.)*mix(mix(mix(1.-f.x,f.x,float(x)),mix(1.-f.x,f.x,float(x)),f.y),mix(mix(1.-f.x,f.x,float(x)),mix(1.-f.x,f.x,float(x)),f.y),f.z);} return n;}
vec3 pal(float x){return .5+.5*cos(6.28318*(vec3(.08,.33,.67)+x+vec3(0.,.15,.31)));}
void main(){
  vec2 uv=(gl_FragCoord.xy-.5*r)/min(r.x,r.y);
  float len=length(uv); vec3 rd=normalize(vec3(uv,1.4));
  float sphere=sqrt(max(0.,1.-dot(uv,uv)));
  vec4 p8=vec4(uv*1.7, sphere+sin(t*.2), cos(t*.17));
  float bands=0.;
  for(int i=0;i<7;i++){
    float fi=float(i)+1.;
    bands += sin(dot(p8, vec4(.7*fi,1.3,2.1/fi,1.7)) + t*(.25+.03*fi));
  }
  float n=noise(vec3(uv*3.0,t*.15));
  float cracks=smoothstep(.92,.98,abs(sin((uv.x*12.+uv.y*17.)+bands*.8+t*.4)))*(1.-smoothstep(.2,.85,len));
  float blob=smoothstep(.9,.1,len) + .18*bands + .3*n + pulse*.35 + audio*.28;
  vec3 col=pal(blob*.23+t*.025);
  col += vec3(.2,.7,1.)*cracks;
  col *= smoothstep(1.25,.15,len);
  col += vec3(.04,.03,.09)/(0.15+len*len);
  o=vec4(col,1.);
}`;
function compile(type, src){ const s=gl.createShader(type); gl.shaderSource(s,src); gl.compileShader(s); if(!gl.getShaderParameter(s,gl.COMPILE_STATUS)) throw gl.getShaderInfoLog(s); return s; }
const prg=gl.createProgram(); gl.attachShader(prg,compile(gl.VERTEX_SHADER,vs)); gl.attachShader(prg,compile(gl.FRAGMENT_SHADER,fs)); gl.linkProgram(prg); gl.useProgram(prg);
const loc={r:gl.getUniformLocation(prg,'r'),t:gl.getUniformLocation(prg,'t'),pulse:gl.getUniformLocation(prg,'pulse'),audio:gl.getUniformLocation(prg,'audio')};
let t0=performance.now();
function frame(now){
  if(!frozen){
    pulse*=.94; audioLevel*=.92;
    gl.uniform2f(loc.r,canvas.width,canvas.height); gl.uniform1f(loc.t,(now-t0)/1000); gl.uniform1f(loc.pulse,pulse); gl.uniform1f(loc.audio,audioLevel);
    gl.drawArrays(gl.TRIANGLES,0,3);
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

document.getElementById('pulse').onclick=()=>pulse=1;
document.getElementById('freeze').onclick=()=>frozen=!frozen;
document.getElementById('audio').onclick=async()=>{ audio=!audio; if(audio){ const ac=new AudioContext(); const osc=ac.createOscillator(); const g=ac.createGain(); g.gain.value=.0001; osc.connect(g).connect(ac.destination); osc.start(); setInterval(()=>{audioLevel=.5+.5*Math.random()},100); }};

setInterval(()=>{ img.src='http://localhost:8090/spectrogram.png?ts='+Date.now(); }, 1000);
try{
  const ws=new WebSocket('ws://localhost:8090/ws');
  ws.onmessage=e=>{ const s=JSON.parse(e.data); statsEl.textContent=JSON.stringify(s,null,2); if(s.peak_norm) pulse=Math.max(pulse, s.peak_norm*.35); };
}catch(e){ statsEl.textContent=String(e); }
