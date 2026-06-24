import * as d3 from 'd3';

export function createForceGraph(canvas){
  const ctx = canvas.getContext('2d');
  const api = {
    width: 0, height: 0,
    nodes: [],
    links: [],
    simulation: null,
    hovered: null,
    selected: null,
    onSelect: () => {},
    settings: {
      linkDistance: 44,
      chargeStrength: -160,
      nodeRadius: 7,
      labelEvery: 3,
      showLabels: true,
      weightScale: 1.0,
    }
  };

  function resize(){
    const dpr = window.devicePixelRatio || 1;
    api.width = canvas.clientWidth;
    api.height = canvas.clientHeight;
    canvas.width = Math.floor(api.width * dpr);
    canvas.height = Math.floor(api.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    if (api.simulation) api.simulation.alpha(0.4).restart();
    draw();
  }

  function init(){
    resize();
    window.addEventListener('resize', resize);
    canvas.addEventListener('mousemove', onMove);
    canvas.addEventListener('click', onClick);
    canvas.addEventListener('mouseleave', () => { api.hovered = null; draw(); });
  }

  function setData(nodes, links){
    api.nodes = nodes.map(n => ({...n}));
    api.links = links.map(l => ({...l}));

    if (api.simulation) api.simulation.stop();

    api.simulation = d3.forceSimulation(api.nodes)
      .force('link', d3.forceLink(api.links).id(d=>d.id)
        .distance(l => api.settings.linkDistance + 120*(1.0 - clamp(l.weight,0,1)))
        .strength(l => 0.15 + 0.85*clamp(l.weight,0,1) * api.settings.weightScale)
      )
      .force('charge', d3.forceManyBody().strength(api.settings.chargeStrength))
      .force('center', d3.forceCenter(api.width/2, api.height/2))
      .force('collision', d3.forceCollide().radius(api.settings.nodeRadius + 2))
      .alpha(0.9)
      .on('tick', draw);

    draw();
  }

  function draw(){
    ctx.clearRect(0,0,api.width,api.height);

    const grd = ctx.createRadialGradient(api.width*0.5, api.height*0.4, 20, api.width*0.5, api.height*0.4, Math.max(api.width, api.height)*0.8);
    grd.addColorStop(0,'rgba(121,242,255,0.06)');
    grd.addColorStop(1,'rgba(0,0,0,0)');
    ctx.fillStyle = grd;
    ctx.fillRect(0,0,api.width, api.height);

    // links
    ctx.save();
    for (const l of api.links){
      const s = l.source, t = l.target;
      const w = clamp(l.weight, 0, 1);
      ctx.globalAlpha = 0.12 + 0.38*w;
      ctx.lineWidth = 1 + 2.2*w;
      ctx.strokeStyle = 'rgba(121,242,255,1.0)';
      ctx.beginPath();
      ctx.moveTo(s.x, s.y);
      ctx.lineTo(t.x, t.y);
      ctx.stroke();
    }
    ctx.restore();

    // nodes
    for (const n of api.nodes){
      const r = api.settings.nodeRadius + (n.isSelected ? 3 : 0) + (n.isHovered ? 2 : 0);
      ctx.beginPath();
      ctx.arc(n.x, n.y, r, 0, Math.PI*2);

      const base = n.isSelected ? 'rgba(125,255,178,0.92)' :
                   n.isHovered ? 'rgba(255,207,106,0.92)' :
                   'rgba(255,255,255,0.82)';
      ctx.fillStyle = base;
      ctx.globalAlpha = 0.9;
      ctx.fill();

      ctx.lineWidth = 1;
      ctx.globalAlpha = 0.5;
      ctx.strokeStyle = 'rgba(0,0,0,0.6)';
      ctx.stroke();
      ctx.globalAlpha = 1;

      if (api.settings.showLabels && (n.pos % api.settings.labelEvery === 0 || n.isSelected || n.isHovered)){
        ctx.font = '12px ui-sans-serif, system-ui, -apple-system, Segoe UI';
        ctx.fillStyle = 'rgba(255,255,255,0.88)';
        ctx.fillText(`${n.pos}:${n.text}`, n.x + r + 6, n.y + 4);
      }
    }
  }

  function findNode(x,y){
    let best = null, bestD = 1e18;
    for (const n of api.nodes){
      const dx = n.x - x, dy = n.y - y;
      const d = dx*dx + dy*dy;
      if (d < bestD){ bestD = d; best = n; }
    }
    const maxR = Math.pow(api.settings.nodeRadius + 7, 2);
    if (best && bestD <= maxR) return best;
    return null;
  }

  function updateFlags(){
    for (const n of api.nodes){
      n.isSelected = api.selected && n.id === api.selected.id;
      n.isHovered = api.hovered && n.id === api.hovered.id;
    }
  }

  function onMove(ev){
    const rect = canvas.getBoundingClientRect();
    const x = ev.clientX - rect.left;
    const y = ev.clientY - rect.top;
    api.hovered = findNode(x,y);
    updateFlags();
    draw();
  }

  function onClick(ev){
    const rect = canvas.getBoundingClientRect();
    const x = ev.clientX - rect.left;
    const y = ev.clientY - rect.top;
    const n = findNode(x,y);
    if (!n) return;
    api.selected = n;
    updateFlags();
    api.onSelect(n);
    draw();
  }

  init();
  return { resize, setData, api };
}

function clamp(x,a,b){ return Math.max(a, Math.min(b,x)); }
