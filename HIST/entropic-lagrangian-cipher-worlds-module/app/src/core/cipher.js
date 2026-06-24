export function canonicalStringify(obj){
  if(obj===null || typeof obj!=='object') return JSON.stringify(obj);
  if(Array.isArray(obj)) return '['+obj.map(canonicalStringify).join(',')+']';
  return '{'+Object.keys(obj).sort().map(k=>JSON.stringify(k)+':'+canonicalStringify(obj[k])).join(',')+'}';
}
export async function sha256Hex(text){
  const data=new TextEncoder().encode(text);
  const hash=await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(hash)].map(b=>b.toString(16).padStart(2,'0')).join('');
}
export function entropy(values){
  const abs=values.map(v=>Math.abs(v));
  const sum=abs.reduce((a,b)=>a+b,0)+1e-12;
  return abs.reduce((h,v)=>{const p=v/sum; return p>1e-12?h-p*Math.log2(p):h},0);
}
export function checksum32(text){
  let h=2166136261>>>0;
  for(let i=0;i<text.length;i++){h^=text.charCodeAt(i);h=Math.imul(h,16777619)>>>0;}
  return h>>>0;
}
export async function encodeState({prevHash, state, directiveTrace, propertyU24, entropyValue, fidelity}){
  const payload={prevHash,state,directiveTrace,propertyU24,entropyValue:Number(entropyValue.toFixed(6)),fidelity:Number(fidelity.toFixed(6))};
  const canon=canonicalStringify(payload);
  const hash=await sha256Hex(canon);
  return {hash, checksum:checksum32(canon), canonical:canon, payload};
}
