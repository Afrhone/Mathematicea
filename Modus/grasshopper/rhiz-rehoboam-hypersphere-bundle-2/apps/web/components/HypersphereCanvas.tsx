'use client';
import { useEffect, useRef, useState } from 'react';
import { createHypersphereRenderer, type NetworkGraph } from '../lib/hypersphereRenderer';

const fallback: NetworkGraph = {
  nodes: [
    { id:'ark-rhiz', label:'ark-rhiz', class:'hypervisor', status:'stable', load:0.34, q:[1,.2,.3,.4,.5,.2,.1,.8] },
    { id:'sigmo-rhiz', label:'sigmo-rhiz', class:'db-leader', status:'stable', load:0.52, q:[.3,1,.2,.9,.1,.5,.2,.7] },
    { id:'rhiz-fach', label:'rhiz-fach', class:'gpu-compute', status:'degraded', load:0.72, q:[.4,.2,1,.2,.8,.4,.6,.1] },
    { id:'llama-gpu', label:'llama-gpu', class:'model', status:'unknown', load:0.42, q:[.2,.8,.1,1,.3,.9,.2,.4] },
    { id:'mongo', label:'mongo memory', class:'database', status:'stable', load:0.21, q:[.7,.1,.4,.3,1,.2,.6,.5] }
  ],
  edges: [
    { source:'ark-rhiz', target:'sigmo-rhiz', relation:'lxd-cluster', weight:.9 },
    { source:'rhiz-fach', target:'llama-gpu', relation:'gpu-route', weight:.8 },
    { source:'llama-gpu', target:'mongo', relation:'analysis-memory', weight:.5 },
    { source:'sigmo-rhiz', target:'mongo', relation:'telemetry', weight:.7 }
  ]
};

export default function HypersphereCanvas(){
  const canvasRef = useRef<HTMLCanvasElement|null>(null);
  const rendererRef = useRef<ReturnType<typeof createHypersphereRenderer>|null>(null);
  const [graph,setGraph] = useState<NetworkGraph>(fallback);
  const [analysis,setAnalysis] = useState('Awaiting signal. Touch the surface or ask the local agent.');
  const [prompt,setPrompt] = useState('Analyze the current RHIZ network graph. Find unstable edges, GPU routing risks, and next safe probes.');

  useEffect(()=>{
    const canvas = canvasRef.current!;
    const renderer = createHypersphereRenderer(canvas, graph);
    rendererRef.current = renderer;
    renderer.start();
    const load = async()=>{
      try { const res = await fetch('/api/network', { cache:'no-store' }); const data = await res.json(); if(data.nodes?.length){ setGraph(data); renderer.setGraph(data); } }
      catch {}
    };
    load(); const id = setInterval(load, 4500);
    return ()=>{ clearInterval(id); renderer.destroy(); };
  },[]);

  useEffect(()=>{ rendererRef.current?.setGraph(graph); },[graph]);

  async function ask(){
    setAnalysis('Model thinking over graph telemetry...');
    const res = await fetch('/api/agent/chat', { method:'POST', headers:{'content-type':'application/json'}, body: JSON.stringify({ model:'local-llama-gpu', temperature:0.25, messages:[{role:'system',content:'You are a precise RHIZ cluster/network analyst. Use STABLE/DEGRADED/CRITICAL/UNKNOWN.'},{role:'user',content:`${prompt}\n\nGraph JSON:\n${JSON.stringify(graph).slice(0,12000)}`}] }) });
    const data = await res.json();
    setAnalysis(data.choices?.[0]?.message?.content || JSON.stringify(data,null,2));
  }

  const unstable = graph.nodes.filter(n=>n.status !== 'stable').length;
  return <div className="stage">
    <canvas ref={canvasRef} className="gl" />
    <div className="scanline"/><div className="vignette"/>
    <section className="hud">
      <div className="panel"><div className="title">RHIZ / REHOBOAM SURFACE</div><div className="big">8D hypersphere<br/>network oracle</div><p className="sub">Native WebGL2 projection shell. Audio/touch perturbations feed fog, caustics, cracks, and blob blending.</p><div className="metric"><span>nodes</span><b>{graph.nodes.length}</b></div><div className="metric"><span>edges</span><b>{graph.edges.length}</b></div><div className="metric"><span>unstable</span><b>{unstable}</b></div><span className="pill">S7→S2 projection</span><span className="pill">agent gateway</span><span className="pill">mongo memory</span></div>
      <div />
      <div className="panel right"><div className="title">Agent surface analysis</div><div className="analysis">{analysis}</div></div>
    </section>
    <div className="bottom"><input className="ask" value={prompt} onChange={e=>setPrompt(e.target.value)} onKeyDown={e=>{ if(e.key==='Enter') ask(); }} /><button className="btn" onClick={ask}>ANALYZE</button></div>
  </div>;
}
