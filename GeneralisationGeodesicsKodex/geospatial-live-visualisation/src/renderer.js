import { LAND_BLOBS, project, inverseProject, clamp } from './geo.js';
import { fieldIndexForMode } from './compute-engine.js';

function colorRamp(v) {
  v = clamp((v + 1) * 0.5, 0, 1);
  const r = Math.floor(20 + 235 * Math.pow(v, 1.7));
  const g = Math.floor(80 + 150 * Math.sin(v * Math.PI));
  const b = Math.floor(120 + 120 * (1 - v));
  return `rgba(${r},${g},${b},0.34)`;
}

function normalizeFieldValue(value, mode) {
  if (mode === 'thermal') return Math.tanh(value / 12);
  if (mode === 'kinetic') return Math.tanh(value / 2);
  if (mode === 'entropy') return Math.tanh(value / 3);
  if (mode === 'curl') return Math.tanh(value / 1.8);
  return Math.tanh(value / 2);
}

export class GeoRenderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.view = { lon: 0, lat: 18, zoom: 1 };
    this.drag = null;
    this.bindInteraction();
  }
  resize() {
    const rect = this.canvas.getBoundingClientRect();
    const dpr = Math.max(1, Math.min(2, devicePixelRatio || 1));
    const w = Math.floor(rect.width * dpr);
    const h = Math.floor(rect.height * dpr);
    if (this.canvas.width !== w || this.canvas.height !== h) {
      this.canvas.width = w;
      this.canvas.height = h;
    }
  }
  bindInteraction() {
    this.canvas.addEventListener('pointerdown', e => {
      this.canvas.setPointerCapture(e.pointerId);
      this.drag = { x: e.clientX, y: e.clientY, lon: this.view.lon, lat: this.view.lat };
    });
    this.canvas.addEventListener('pointermove', e => {
      if (!this.drag) return;
      const dx = e.clientX - this.drag.x;
      const dy = e.clientY - this.drag.y;
      this.view.lon = this.drag.lon - dx * 0.28 / this.view.zoom;
      this.view.lat = clamp(this.drag.lat + dy * 0.18 / this.view.zoom, -80, 80);
    });
    this.canvas.addEventListener('pointerup', () => this.drag = null);
    this.canvas.addEventListener('wheel', e => {
      e.preventDefault();
      this.view.zoom = clamp(this.view.zoom * Math.exp(-e.deltaY * 0.001), 0.75, 5);
    }, { passive: false });
  }
  reset() { this.view = { lon: 0, lat: 18, zoom: 1 }; }

  draw({ field, events, projection, fieldMode, invariants, time }) {
    this.resize();
    const ctx = this.ctx;
    const w = this.canvas.width;
    const h = this.canvas.height;
    ctx.clearRect(0,0,w,h);
    this.drawBackground(ctx, w, h, time);
    this.drawField(ctx, w, h, field, projection, fieldMode);
    this.drawGraticule(ctx, w, h, projection);
    this.drawLand(ctx, w, h, projection);
    this.drawTelemetry(ctx, w, h, events, projection, time);
    this.drawVectorStream(ctx, w, h, events, projection, time);
    this.drawLegend(ctx, w, h, fieldMode, invariants);
  }

  drawBackground(ctx,w,h,time) {
    const g = ctx.createRadialGradient(w*0.5,h*0.5,0,w*0.5,h*0.5,Math.max(w,h)*0.65);
    g.addColorStop(0, '#0c2832');
    g.addColorStop(0.46, '#041016');
    g.addColorStop(1, '#010407');
    ctx.fillStyle = g;
    ctx.fillRect(0,0,w,h);
    ctx.save();
    ctx.globalAlpha = 0.22;
    ctx.strokeStyle = '#87f8ff';
    ctx.lineWidth = 1;
    for (let i=0;i<48;i++) {
      const y = ((i*37 + time*0.002) % h);
      ctx.beginPath();
      ctx.moveTo(0,y);
      ctx.lineTo(w,y + Math.sin(i+time*0.001)*18);
      ctx.stroke();
    }
    ctx.restore();
  }

  drawGraticule(ctx,w,h,projection) {
    ctx.save();
    ctx.strokeStyle = 'rgba(164,245,255,.16)';
    ctx.lineWidth = 1;
    for (let lon=-180; lon<=180; lon+=30) this.drawGeoLine(ctx,w,h,projection, Array.from({length:91},(_,i)=>[-90+i*2,lon]));
    for (let lat=-60; lat<=60; lat+=30) this.drawGeoLine(ctx,w,h,projection, Array.from({length:181},(_,i)=>[lat,-180+i*2]));
    ctx.restore();
  }

  drawGeoLine(ctx,w,h,projection,coords) {
    ctx.beginPath();
    let started = false;
    for (const [lat, lon] of coords) {
      const [x,y,visible] = project(lat,lon,w,h,projection,this.view);
      if (!visible) { started = false; continue; }
      if (!started) { ctx.moveTo(x,y); started = true; }
      else ctx.lineTo(x,y);
    }
    ctx.stroke();
  }

  drawLand(ctx,w,h,projection) {
    ctx.save();
    ctx.fillStyle = 'rgba(115, 168, 145, .18)';
    ctx.strokeStyle = 'rgba(180, 255, 218, .34)';
    ctx.lineWidth = 1.4;
    for (const blob of LAND_BLOBS) {
      ctx.beginPath();
      let started = false;
      for (const [lon, lat] of blob) {
        const [x,y,visible] = project(lat,lon,w,h,projection,this.view);
        if (!visible) continue;
        if (!started) { ctx.moveTo(x,y); started = true; }
        else ctx.lineTo(x,y);
      }
      if (started) { ctx.closePath(); ctx.fill(); ctx.stroke(); }
    }
    ctx.restore();
  }

  drawField(ctx,w,h,field,projection,mode) {
    if (!field) return;
    const idx = fieldIndexForMode(mode);
    const cw = w / field.nx;
    const ch = h / field.ny;
    ctx.save();
    for (let y=0;y<field.ny;y+=2) {
      const lat = 90 - (y + 0.5) / field.ny * 180;
      for (let x=0;x<field.nx;x+=2) {
        const lon = (x + 0.5) / field.nx * 360 - 180;
        const [px,py,visible] = project(lat,lon,w,h,projection,this.view);
        if (!visible) continue;
        const raw = field.cells[(y*field.nx+x)*5+idx];
        const val = normalizeFieldValue(raw, mode);
        ctx.fillStyle = colorRamp(val);
        const r = projection === 'orthographic' ? 6 * this.view.zoom : Math.max(cw,ch) * 1.35 * this.view.zoom;
        ctx.fillRect(px-r*0.5, py-r*0.5, r, r);
      }
    }
    ctx.restore();
  }

  drawTelemetry(ctx,w,h,events,projection,time) {
    ctx.save();
    for (const e of events) {
      const [x,y,visible] = project(e.lat,e.lon,w,h,projection,this.view);
      if (!visible) continue;
      const pulse = 0.5 + 0.5*Math.sin(time*0.006 + e.phase*6.283);
      const r = (4 + 10 * e.quality + 6 * pulse) * this.view.zoom;
      ctx.beginPath();
      ctx.arc(x,y,r,0,Math.PI*2);
      ctx.fillStyle = `rgba(135,248,255,${0.12 + 0.18*pulse})`;
      ctx.fill();
      ctx.lineWidth = 1.8;
      ctx.strokeStyle = e.charge >= 0 ? 'rgba(255,208,138,.95)' : 'rgba(255,155,213,.95)';
      ctx.stroke();
      ctx.fillStyle = '#effdff';
      ctx.font = `${Math.round(11 * Math.max(1, this.view.zoom*0.55))}px ui-sans-serif`;
      ctx.fillText(e.id, x + r + 4, y - r - 2);
    }
    ctx.restore();
  }

  drawVectorStream(ctx,w,h,events,projection,time) {
    ctx.save();
    ctx.globalAlpha = 0.72;
    for (const e of events) {
      const [x,y,visible] = project(e.lat,e.lon,w,h,projection,this.view);
      if (!visible) continue;
      const len = (22 + 24*Math.hypot(e.vx,e.vy,e.vz)) * this.view.zoom;
      const a = Math.atan2(e.vy, e.vx) + time*0.0002;
      ctx.strokeStyle = e.charge >= 0 ? 'rgba(255,208,138,.74)' : 'rgba(255,155,213,.74)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(x,y);
      ctx.lineTo(x + Math.cos(a)*len, y + Math.sin(a)*len);
      ctx.stroke();
    }
    ctx.restore();
  }

  drawLegend(ctx,w,h,mode,invariants) {
    ctx.save();
    ctx.fillStyle = 'rgba(0,10,16,.62)';
    ctx.strokeStyle = 'rgba(164,245,255,.2)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect(w-270, 18, 250, 82, 18);
    ctx.fill(); ctx.stroke();
    ctx.fillStyle = '#e9fbff';
    ctx.font = '15px ui-sans-serif';
    ctx.fillText(`Layer: ${mode}`, w-250, 44);
    ctx.fillStyle = invariants?.thermodynamicGuard ? '#a8ffce' : '#ff9b9b';
    ctx.fillText(`Thermo guard: ${invariants?.thermodynamicGuard ? 'OK' : 'CHECK'}`, w-250, 68);
    ctx.fillStyle = '#8fb7c0';
    ctx.fillText('drag · wheel zoom · stream pulse', w-250, 90);
    ctx.restore();
  }
}

if (!CanvasRenderingContext2D.prototype.roundRect) {
  CanvasRenderingContext2D.prototype.roundRect = function(x,y,w,h,r) {
    this.moveTo(x+r,y); this.arcTo(x+w,y,x+w,y+h,r); this.arcTo(x+w,y+h,x,y+h,r); this.arcTo(x,y+h,x,y,r); this.arcTo(x,y,x+w,y,r); return this;
  };
}
