export const Triptych = { R:0, N:1, Z:2, mixed:3 };
export const Commutation = { commutative:0, quasi:1, noncommutative:2, symmetricPermutative:3 };
export const Arrow = { forward:0, reverse:1, bidirectional:2, gated:3 };
export const Proof = { none:0, checksum:1, hash:2, trustChain:3 };
export const DomainResolution = { integer:0, real:1, bound:2, unknown:3 };

export function encodeU24({triptych=3, commutation=1, arrow=0, proof=2, directive=0, principle=0, resolution=2, cluster=0, fidelityBand=5, quasi=true}={}){
  const b0 = (triptych&3) | ((commutation&3)<<2) | ((arrow&3)<<4) | ((proof&3)<<6);
  const b1 = (directive&7) | ((principle&7)<<3) | ((resolution&3)<<6);
  const b2 = (cluster&15) | ((fidelityBand&7)<<4) | (quasi?128:0);
  return (b0<<16) | (b1<<8) | b2;
}
export function decodeU24(u){
  const b0=(u>>16)&255, b1=(u>>8)&255, b2=u&255;
  return {triptych:b0&3, commutation:(b0>>2)&3, arrow:(b0>>4)&3, proof:(b0>>6)&3, directive:b1&7, principle:(b1>>3)&7, resolution:(b1>>6)&3, cluster:b2&15, fidelityBand:(b2>>4)&7, quasi:!!(b2&128), hex:'0x'+u.toString(16).padStart(6,'0')};
}
export function u24Color(u){
  const d=decodeU24(u);
  const h=(d.triptych*0.18+d.cluster*0.047+d.arrow*0.11)%1;
  const s=0.55+d.proof*0.1;
  const v=0.45+d.fidelityBand*0.07;
  return [h,s,Math.min(1,v)];
}
