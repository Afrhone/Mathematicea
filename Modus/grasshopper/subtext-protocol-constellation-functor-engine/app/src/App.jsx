import React, {useEffect, useRef, useState} from 'react';
import {createRoot} from 'react-dom/client';
import {Network, Search, Upload, GitBranch, Sparkles, CheckCircle2} from 'lucide-react';
import './styles.css';

function Constellation({graph}) {
  const ref = useRef(null);
  useEffect(()=>{
    const canvas = ref.current, ctx = canvas.getContext('2d');
    let raf, t=0;
    function resize(){ canvas.width=canvas.clientWidth*devicePixelRatio; canvas.height=canvas.clientHeight*devicePixelRatio; }
    resize(); addEventListener('resize', resize);
    function frame(){
      t += 0.01;
      const w=canvas.width,h=canvas.height;
      ctx.fillStyle='#050711'; ctx.fillRect(0,0,w,h);
      const nodes = graph.nodes || [], edges = graph.edges || [], pos = {};
      nodes.forEach((n,i)=>{
        const tier = n.tier ?? 0;
        const r = Math.min(w,h)*(0.12 + tier*0.055) + Math.sin(t+i)*12;
        const a = i*2.399963 + t*(0.05 + tier*0.01);
        pos[n.id]=[w/2+Math.cos(a)*r, h/2+Math.sin(a)*r];
      });
      ctx.globalAlpha=.35; ctx.strokeStyle='#72ddff';
      edges.forEach(e=>{const a=pos[e.from], b=pos[e.to]; if(a&&b){ctx.beginPath();ctx.moveTo(...a);ctx.lineTo(...b);ctx.stroke();}});
      ctx.globalAlpha=1;
      nodes.forEach((n,i)=>{
        const p=pos[n.id]; if(!p) return;
        const tier=n.tier??0, rad=(4+tier*1.8)*devicePixelRatio;
        ctx.beginPath(); ctx.arc(p[0],p[1],rad,0,Math.PI*2);
        ctx.fillStyle=`hsl(${(tier*52+i*7)%360} 90% 65%)`; ctx.fill();
        if(i<42){ ctx.fillStyle='#dbeafe'; ctx.font=`${11*devicePixelRatio}px sans-serif`; ctx.fillText(n.root,p[0]+8,p[1]-8); }
      });
      raf=requestAnimationFrame(frame);
    }
    frame();
    return()=>{cancelAnimationFrame(raf); removeEventListener('resize', resize)}
  },[graph]);
  return <canvas className="constellation" ref={ref}/>;
}

function App(){
  const [graph,setGraph]=useState({nodes:[],edges:[]});
  const [health,setHealth]=useState({});
  const [title,setTitle]=useState('manual signal note');
  const [text,setText]=useState('Hypergraph PHI|OS cloud-compute signal flow compiler lint search tree constellation functor.');
  const [query,setQuery]=useState('hypergraph');
  const [results,setResults]=useState([]);
  async function load(){ try{setHealth(await (await fetch('/api/health')).json())}catch(e){}; try{setGraph(await (await fetch('/api/graph')).json())}catch(e){} }
  async function ingest(){ await fetch('/api/ingest/text',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({title,text,source:'ui'})}); await compile(); }
  async function compile(){ await fetch('/api/compile',{method:'POST'}); await load(); }
  async function lint(){ const r=await (await fetch('/api/lint',{method:'POST'})).json(); alert('lint issues: '+r.count); }
  async function search(){ setResults(await (await fetch('/api/search?q='+encodeURIComponent(query))).json().then(x=>x.results||[])); }
  useEffect(()=>{load(); const t=setInterval(load,5000); return()=>clearInterval(t)},[]);
  return <main>
    <section className="hero"><div><h1><Sparkles/> Subtext Protocol · Constellation Functor Engine</h1><p>Hypertext heuristics, expressive roots, synchronic search tree, auditable compiler loop.</p></div><div className="status"><CheckCircle2/> raw {health.raw||0} · nodes {health.nodes||0}</div></section>
    <section className="grid">
      <div className="card big"><h2><Network/> Constellation Graph</h2><Constellation graph={graph}/></div>
      <div className="card"><h2><Upload/> Ingest</h2><input value={title} onChange={e=>setTitle(e.target.value)}/><textarea value={text} onChange={e=>setText(e.target.value)}/><button onClick={ingest}>Ingest + Compile</button><button onClick={compile}>Compile</button><button onClick={lint}>Lint</button></div>
      <div className="card"><h2><Search/> Synchronic Search</h2><input value={query} onChange={e=>setQuery(e.target.value)} onKeyDown={e=>{if(e.key==='Enter')search()}}/><button onClick={search}>Search Tree</button><div className="results">{results.map(r=><article key={r.id}><b>{r.root}</b><span>tier {r.tier} · evidence {r.rank?.evidence}</span><small>{(r.operators||[]).join(' · ')}</small></article>)}</div></div>
      <div className="card"><h2><GitBranch/> Protocol Formula</h2><pre>{`Raw lake -> compiler -> wiki -> lint -> validation -> promotion -> agent briefing\n\nFunctorRoot r -> Stem S(r) -> Operator O(r) -> DerivedNodeSet -> HypertextEdge\n\nScore = lexical + backlinks + provenance + operator_match + novelty - risk`}</pre></div>
    </section>
  </main>
}
createRoot(document.getElementById('root')).render(<App/>);
