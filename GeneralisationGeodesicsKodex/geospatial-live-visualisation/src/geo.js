export const TAU = Math.PI * 2;
export const DEG = Math.PI / 180;

export function clamp(x, a, b) { return Math.max(a, Math.min(b, x)); }
export function wrapLon(lon) { return ((lon + 540) % 360) - 180; }
export function lerp(a, b, t) { return a + (b - a) * t; }
export function fract(x) { return x - Math.floor(x); }

export function project(lat, lon, width, height, mode = 'equirect', view = { lon: 10, lat: 20, zoom: 1 }) {
  lat = clamp(lat, -89.999, 89.999);
  lon = wrapLon(lon - (view.lon || 0));
  const zoom = view.zoom || 1;
  if (mode === 'mercator') {
    const x = (lon + 180) / 360 * width;
    const yMerc = Math.log(Math.tan(Math.PI / 4 + lat * DEG / 2));
    const y = height / 2 - (width * yMerc / TAU);
    return [width/2 + (x - width/2) * zoom, height/2 + (y - height/2) * zoom, true];
  }
  if (mode === 'orthographic') {
    const λ = lon * DEG;
    const φ = lat * DEG;
    const φ0 = (view.lat || 0) * DEG;
    const cosc = Math.sin(φ0) * Math.sin(φ) + Math.cos(φ0) * Math.cos(φ) * Math.cos(λ);
    const r = Math.min(width, height) * 0.43 * zoom;
    const x = width/2 + r * Math.cos(φ) * Math.sin(λ);
    const y = height/2 - r * (Math.cos(φ0) * Math.sin(φ) - Math.sin(φ0) * Math.cos(φ) * Math.cos(λ));
    return [x, y, cosc >= -0.04];
  }
  const x = ((lon + 180) / 360) * width;
  const y = ((90 - lat) / 180) * height;
  return [width/2 + (x - width/2) * zoom, height/2 + (y - height/2) * zoom, true];
}

export function inverseProject(x, y, width, height, mode = 'equirect', view = { lon: 10, lat: 20, zoom: 1 }) {
  const zoom = view.zoom || 1;
  x = width/2 + (x - width/2) / zoom;
  y = height/2 + (y - height/2) / zoom;
  if (mode === 'mercator') {
    const lon = ((x / width) * 360 - 180) + (view.lon || 0);
    const m = (height / 2 - y) * TAU / width;
    const lat = (2 * Math.atan(Math.exp(m)) - Math.PI/2) / DEG;
    return [lat, wrapLon(lon)];
  }
  const lon = ((x / width) * 360 - 180) + (view.lon || 0);
  const lat = 90 - (y / height) * 180;
  return [clamp(lat, -90, 90), wrapLon(lon)];
}

// Very compact abstract coastline seeds: enough for an offline visual shell without tile APIs.
export const LAND_BLOBS = [
  [[-168,72],[-130,70],[-105,55],[-82,48],[-65,36],[-82,18],[-100,18],[-118,32],[-140,50],[-168,72]],
  [[-82,12],[-68,8],[-52,-8],[-56,-28],[-70,-54],[-78,-18],[-82,12]],
  [[-12,72],[36,68],[72,55],[102,50],[135,60],[158,45],[126,18],[88,8],[54,24],[34,8],[16,36],[-10,36],[-12,72]],
  [[-18,34],[44,34],[52,12],[34,-35],[18,-35],[5,-12],[-12,4],[-18,34]],
  [[112,-10],[154,-12],[154,-42],[120,-44],[112,-10]],
  [[-46,76],[-20,72],[-24,60],[-48,62],[-46,76]],
  [[-180,-64],[180,-64],[180,-82],[-180,-82],[-180,-64]]
];

export function haversineKm(a, b) {
  const R = 6371;
  const dφ = (b.lat - a.lat) * DEG;
  const dλ = (b.lon - a.lon) * DEG;
  const φ1 = a.lat * DEG;
  const φ2 = b.lat * DEG;
  const h = Math.sin(dφ/2)**2 + Math.cos(φ1)*Math.cos(φ2)*Math.sin(dλ/2)**2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
