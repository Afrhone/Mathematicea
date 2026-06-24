export function flowVector(x,y,t,p,f){
  const e=f?.metrics?.spectrum_entropy??.5, vg=f?.metrics?.velocity_field_gain??1, em=f?.metrics?.em_field_gain??1;
  const dx=Math.sin(y*p.fold+t*.4)+Math.cos((x+y)*p.mobius+t*.23);
  const dy=Math.cos(x*p.fold-t*.31)-Math.sin((x-y)*p.mobius+t*.19);
  const r=Math.hypot(x,y)+1e-4, swirl=p.swirl/(.25+r);
  return [(dx*vg-y*swirl+Math.sin(t+x*8)*e*em)*p.gain,(dy*vg+x*swirl+Math.cos(t+y*8)*e*em)*p.gain];
}
export function projectHypersphere(i,t,p,f){
  const a=i*2.399963+t*.05,b=i*1.618033+t*.031,c=i*.754877+t*.017,e=f?.metrics?.spectrum_entropy??.5;
  const r=.42+.18*Math.sin(b+e*4)+p.fold*.015, tor=p.torus;
  let x=Math.cos(a)*(r+tor*Math.cos(b)*.1), y=Math.sin(a)*(r+tor*Math.cos(b)*.1), z=Math.sin(b)*.22+Math.cos(c)*.08, w=Math.sin(c+a)*.2;
  const pr=1/(1.2+z+w*p.hyper); return [x*pr,y*pr,z,w];
}
