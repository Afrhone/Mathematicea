"use client";
import React, {useEffect, useRef, useState} from "react";
import "./app-globals.css";

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8078";

function compile(gl: WebGL2RenderingContext, type: number, src: string) {
  const s = gl.createShader(type)!; gl.shaderSource(s, src); gl.compileShader(s);
  if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s)||"shader");
  return s;
}

const vert = `#version 300 es
precision highp float;
in vec2 p;
out vec2 uv;
void main(){ uv=(p+1.0)*0.5; gl_Position=vec4(p,0,1); }`;

const frag = `#version 300 es
precision highp float;
out vec4 outColor;
in vec2 uv;
uniform float t;
uniform float eeg;
uniform float spectral;
uniform vec2 res;

vec3 palette(float x){
  return .55 + .45*cos(6.28318*(vec3(.05,.25,.45)+x+vec3(0.0,.33,.67)));
}

float field(vec3 q){
  float f=0.0;
  for(int i=0;i<8;i++){
    float a=float(i)*0.785398 + t*.07;
    vec3 c=vec3(cos(a), sin(a*1.3), cos(a*.7))*0.62;
    f += .08/length(q-c);
  }
  return f;
}

void main(){
  vec2 xy=(uv*2.0-1.0);
  xy.x*=res.x/res.y;
  float r2=dot(xy,xy);
  vec3 sph=normalize(vec3(xy, sqrt(max(0.001,1.0-r2))));
  float fold=sin(8.0*atan(xy.y,xy.x)+t*0.8) * .09;
  vec3 q=sph + fold*vec3(sin(t),cos(t*.7),sin(t*.3));
  float f=field(q);
  float rings=sin(42.0*length(xy)+t*3.0+spectral*5.0)*.5+.5;
  float grid=smoothstep(.02,.0,abs(fract((xy.x+xy.y+t*.02)*8.0)-.5)-.48);
  vec3 col=palette(f*.35 + rings*.08 + eeg*.12);
  col += vec3(.0,.8,1.0)*pow(max(0.0,f-.55),2.0)*1.8;
  col += vec3(1.0,.65,.18)*grid*.22;
  col *= smoothstep(1.35,.2,length(xy));
  outColor=vec4(col,1.0);
}`;

export default function Page(){
  const canvas = useRef<HTMLCanvasElement|null>(null);
  const [events,setEvents]=useState<any>({spectral_energy:0,eeg_alpha:0,realm_phase:0});
  const [p,setP]=useState(7);
  const [cp,setCp]=useState<number|null>(null);

  useEffect(()=>{
    const ws = new WebSocket(API.replace("http","ws")+"/ws/events");
    ws.onmessage = ev => setEvents(JSON.parse(ev.data));
    return ()=>ws.close();
  },[]);

  useEffect(()=>{
    fetch(API+"/api/functor/mendeleev",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({p,dimensions:12,particles:128})})
      .then(r=>r.json()).then(j=>setCp(j.c_p)).catch(()=>{});
  },[p]);

  useEffect(()=>{
    const c=canvas.current!, gl=c.getContext("webgl2")!;
    const prog=gl.createProgram()!;
    gl.attachShader(prog, compile(gl, gl.VERTEX_SHADER, vert));
    gl.attachShader(prog, compile(gl, gl.FRAGMENT_SHADER, frag));
    gl.linkProgram(prog);
    if(!gl.getProgramParameter(prog, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(prog)||"program");
    const buf=gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER,buf);
    gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,3,-1,-1,3]),gl.STATIC_DRAW);
    const loc=gl.getAttribLocation(prog,"p");
    gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc,2,gl.FLOAT,false,0,0);
    const ut=gl.getUniformLocation(prog,"t"), ue=gl.getUniformLocation(prog,"eeg"), us=gl.getUniformLocation(prog,"spectral"), ur=gl.getUniformLocation(prog,"res");
    let raf=0, start=performance.now();
    const draw=()=>{
      const dpr=Math.min(2,devicePixelRatio||1);
      c.width=Math.floor(innerWidth*dpr); c.height=Math.floor(innerHeight*dpr);
      gl.viewport(0,0,c.width,c.height); gl.useProgram(prog);
      gl.uniform1f(ut,(performance.now()-start)/1000);
      gl.uniform1f(ue,events.eeg_alpha||0);
      gl.uniform1f(us,events.spectral_energy||0);
      gl.uniform2f(ur,c.width,c.height);
      gl.drawArrays(gl.TRIANGLES,0,3);
      raf=requestAnimationFrame(draw);
    };
    draw(); return ()=>cancelAnimationFrame(raf);
  },[events]);

  return <main style={{minHeight:"100vh",overflow:"hidden"}}>
    <canvas ref={canvas} style={{position:"fixed",inset:0,width:"100%",height:"100%"}}/>
    <section style={{position:"relative",padding:"28px",display:"grid",gridTemplateColumns:"minmax(320px,480px) 1fr",gap:24}}>
      <div className="panel" style={{padding:24}}>
        <h1 style={{fontSize:34,margin:"0 0 8px"}}>AFRHO Realm Connexe</h1>
        <p style={{opacity:.82,lineHeight:1.5}}>VR/AR functor lab: hypersphere projection, SDR spectrogram, EEG modulation, chemistry blueprint and graph field orchestration.</p>
        <label>Period p: <input type="range" min="1" max="9" value={p} onChange={e=>setP(parseInt(e.target.value))}/></label>
        <h2>c(p) = {cp ?? "…"}</h2>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          <Metric label="Spectral energy" value={(events.spectral_energy||0).toFixed(3)}/>
          <Metric label="EEG alpha" value={(events.eeg_alpha||0).toFixed(3)}/>
          <Metric label="Realm phase" value={(events.realm_phase||0).toFixed(3)}/>
          <Metric label="Dims" value="12→3"/>
        </div>
      </div>
      <div className="panel" style={{padding:24,alignSelf:"start"}}>
        <h2>Live Spectrogram</h2>
        <img src={API+"/api/spectrogram.png?"+Date.now()} style={{width:"100%",borderRadius:14,border:"1px solid rgba(100,220,255,.25)"}}/>
        <p style={{opacity:.7}}>Synthetic fallback mode; switch SDR_MODE to LimeSDR once SoapySDR is ready on factau-rhiz.</p>
      </div>
    </section>
  </main>
}

function Metric({label,value}:{label:string,value:string}) {
  return <div style={{border:"1px solid rgba(100,220,255,.2)",borderRadius:14,padding:12}}>
    <div style={{fontSize:12,opacity:.7}}>{label}</div><div style={{fontSize:24}}>{value}</div>
  </div>
}
