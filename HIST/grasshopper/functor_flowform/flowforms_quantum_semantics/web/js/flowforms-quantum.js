(()=>{
  const labels = ['Root anchor','Bridge relation','Form vessel','Rhythm pulse','Nature branch','Momentum vector','Axiom center','Latent intuition'];
  const bits = ['000','001','010','011','100','101','110','111'];
  function clamp(v,a=0,b=1){return Math.max(a,Math.min(b,v));}
  function features(g, params={}){
    const f = window.FlowMath?.features?.(g) || {length:300};
    const n = (g.strokes||[]).length || 1;
    const loopness = clamp((n + (g.dots||[]).length*.5)/5);
    const rhythm = clamp((params.rhythm||50)/100*.7 + n*.04);
    const momentum = clamp((params.momentum||50)/100*.72 + f.length/2400);
    const axiom = clamp((g.family==='axiom'?0.78:0.24) + ((g.dots||[]).length*.18));
    const bridge = clamp((g.family==='bridge'?0.78:0.18) + loopness*.22);
    const branch = clamp((g.family==='nature'?0.78:0.18) + n*.06);
    const curvature = clamp((params.curvature||50)/100);
    const tension = clamp((params.tension||50)/100);
    return {loopness,rhythm,momentum,axiom,bridge,branch,curvature,tension,length:f.length||0,family:g.family};
  }
  function amplitudes(g, params={}){
    const x=features(g,params);
    const raw=[
      .33+x.tension*.32+(x.family==='root'?.45:0),
      .25+x.bridge*.72,
      .25+x.curvature*.55+(x.family==='form'?.32:0),
      .20+x.rhythm*.78,
      .20+x.branch*.78,
      .20+x.momentum*.82,
      .20+x.axiom*.84,
      .18+(x.loopness+x.rhythm+x.momentum)/3*.72
    ];
    const ex=raw.map(v=>Math.exp(v)); const sum=ex.reduce((a,b)=>a+b,0);
    return ex.map((v,i)=>({bit:bits[i],label:labels[i],amplitude:Math.sqrt(v/sum),probability:v/sum}));
  }
  function entropy(states){return -states.reduce((s,a)=>s+(a.probability>0?a.probability*Math.log2(a.probability):0),0);}
  function infer(g, params={}, corpus='sketch-corpus', modus='expressive'){
    const states=amplitudes(g,params); states.sort((a,b)=>b.probability-a.probability);
    const e=entropy(states); const top=states[0];
    const coherence=1 - Math.min(1,e/3);
    let action='keep';
    if(e>2.65) action='ask-agent';
    else if(top.label.includes('Rhythm')) action='animate';
    else if(top.label.includes('Momentum')) action='push-morph';
    else if(top.label.includes('Axiom')) action='center-and-export';
    else if(top.label.includes('Bridge')) action='compose-ligature';
    else if(top.label.includes('Nature')) action='branch-variant';
    else if(top.label.includes('Latent')) action='sample-latent';
    const tree=[
      `glyph ${g.char} / ${g.family}`,
      `encode features → θ=[curvature,rhythm,momentum,axiom,bridge]`,
      `prepare |ψ⟩ over 8 semantic basis states`,
      `entropy=${e.toFixed(3)} coherence=${coherence.toFixed(3)}`,
      `dominant=${top.bit} ${top.label} p=${top.probability.toFixed(3)}`,
      `decision=${action} corpus=${corpus} modus=${modus}`
    ];
    return {glyph:g.char,family:g.family,corpus,modus,states,entropy:e,coherence,action,tree,ibm:{mode:'local simulator unless API env is configured',shots:1024,primitive:'SamplerV2'}};
  }
  function modalText(g, params){
    const r=infer(g,params);
    return `PHI Quantum Functorial Alphabet\n\nQΦ: graphème × corpus × modus → |ψ_g⟩ → decision trace → morph action\n\nActive glyph: ${r.glyph} / ${r.family}\nAction: ${r.action}\nCoherence: ${r.coherence.toFixed(3)}\nEntropy: ${r.entropy.toFixed(3)}\n\nSuperposed semantic states:\n${r.states.map(s=>`|${s.bit}⟩ ${s.label.padEnd(18)} p=${s.probability.toFixed(4)} amp=${s.amplitude.toFixed(4)}`).join('\n')}\n\nDecision tree / flow-thought trace:\n${r.tree.map((x,i)=>`${i+1}. ${x}`).join('\n')}\n\nIBM Runtime bridge:\n- local browser uses deterministic Born-rule heuristic\n- services/quantum-lab can call qiskit-ibm-runtime when IBM_QUANTUM_TOKEN and IBM_QUANTUM_INSTANCE are provided\n- tokens stay server-side only`;
  }
  function exportBI(g, params){
    const r=infer(g,params);
    const csv=['metric,value',`glyph,${r.glyph}`,`family,${r.family}`,`action,${r.action}`,`coherence,${r.coherence}`,`entropy,${r.entropy}`].join('\n');
    return {json:r,csv};
  }
  window.FlowformsQuantum={features,amplitudes,infer,modalText,exportBI};
})();
