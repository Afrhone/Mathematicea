#!/usr/bin/env node
// MCP-lite JSON-RPC stdio bridge. It exposes Flowforms tools without external dependencies.
import fs from 'fs';
const glyphs = JSON.parse(fs.readFileSync(new URL('../../web/assets/glyphs.json', import.meta.url),'utf8'));
const functorialPreset = JSON.parse(fs.readFileSync(new URL('../../web/assets/presets/functorial-alphabet.json', import.meta.url),'utf8'));
const quantumPreset = JSON.parse(fs.readFileSync(new URL('../../web/assets/presets/phi-quantum-functorial-alphabet.json', import.meta.url),'utf8'));
const tools=[
 {name:'flowforms.listGlyphs',description:'List glyphs and families',inputSchema:{type:'object',properties:{family:{type:'string'}}}},
 {name:'flowforms.generateVariant',description:'Generate a deterministic glyph variant plan',inputSchema:{type:'object',properties:{char:{type:'string'},morph:{type:'number'}}}},
 {name:'flowforms.formalize',description:'Return the real function, Lagrangian, and generic ODE for the expression engine',inputSchema:{type:'object',properties:{}}},
 {name:'flowforms.functorialPreset',description:'Return the functorial alphabet preset and selected graphème→phonème mapping',inputSchema:{type:'object',properties:{char:{type:'string'}}}},
 {name:'flowforms.quantumInfer',description:'Return QΦ semantic superposition and decision-tree action for a glyph',inputSchema:{type:'object',properties:{char:{type:'string'},family:{type:'string'}}}},
 {name:'cluster.plan',description:'Return safe deployment plan for Docker Swarm/LXD/libvirt integration',inputSchema:{type:'object',properties:{target:{type:'string'}}}}
];
function reply(id,result){process.stdout.write(JSON.stringify({jsonrpc:'2.0',id,result})+'\n')}
function call(name,args={}){ if(name==='flowforms.listGlyphs') return {families:glyphs.families,glyphs:glyphs.glyphs.filter(g=>!args.family||g.family===args.family).map(g=>({char:g.char,name:g.name,family:g.family}))};
 if(name==='flowforms.generateVariant'){const g=glyphs.glyphs.find(x=>x.char===args.char)||glyphs.glyphs[0]; return {base:g.char,family:g.family,morph:args.morph||0.38,steps:['preserve endpoints','rotate inner handles by morph phase','apply rhythm sinusoid','assert C0 continuity','export SVG path']};}
 if(name==='flowforms.formalize') return {F:'Fθ(s;r,p,a)=Aθ(Σ Bᵢ(s)Pᵢ + Φroot + Φrhythm + Φaxiom)',L:'L(q,qdot,t)=1/2 qdotᵀM qdot - Vroot - Vsmooth - Vphoneme + A(q,t)·qdot',ODE:'M qddot + C qdot + ∇V(q,t) - B(q,t)qdot = u(t)'};
 if(name==='flowforms.functorialPreset'){ const entry=functorialPreset.alphabetMap.find(x=>x.char===args.char); return {preset:functorialPreset.name, functor:functorialPreset.category.functor, realFunction:functorialPreset.realFunction, lagrangian:functorialPreset.lagrangian, ode:functorialPreset.ode, entry:entry||null}; }
 if(name==='flowforms.quantumInfer'){ const ch=args.char||'φ'; const entry=quantumPreset.alphabetQuantumMap.find(x=>x.char===ch)||quantumPreset.alphabetQuantumMap[0]; return {preset:quantumPreset.name, glyph:ch, semantics:quantumPreset.semantics, ibmQuantum:quantumPreset.ibmQuantum, inference:entry}; }
 if(name==='cluster.plan') return {target:args.target||'swarm',safety:'dry-run first; APPLY=1 only after healthcheck',steps:['validate Docker/LXD/libvirt/ports','configure SSO issuer','deploy API/CMS/web/MCP','run agent assertions','publish behind reverse proxy']};
 return {error:'unknown tool'}; }
let buf=''; process.stdin.on('data',chunk=>{buf+=chunk; const lines=buf.split('\n'); buf=lines.pop(); for(const line of lines){if(!line.trim())continue; const msg=JSON.parse(line); if(msg.method==='tools/list') reply(msg.id,{tools}); else if(msg.method==='tools/call') reply(msg.id,{content:[{type:'text',text:JSON.stringify(call(msg.params?.name,msg.params?.arguments),null,2)}]}); else reply(msg.id,{ok:true,name:'flowforms-mcp-lite'});}});
