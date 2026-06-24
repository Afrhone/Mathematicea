export const TAU=Math.PI*2;
export const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
export const fract=x=>x-Math.floor(x);
export function cexp(theta,r=1){return [Math.cos(theta)*r,Math.sin(theta)*r]}
export function polynomialRoots(degree,t,phi=1.61803398875,phase=0){const roots=[];for(let k=0;k<degree;k++){const base=TAU*k/degree;const wob=.18*Math.sin(t*.37+k*phi+phase)+.07*Math.sin(t*.91+k*2.31);const r=.55+.28*Math.sin(t*.21+k*.73)+.18*Math.cos(t*.13+k*phi);roots.push(cexp(base+wob,Math.max(.08,r)));}return roots;}
export function projectND(v,dim,yaw,pitch,roll,zoom){let x=0,y=0,z=0;for(let i=0;i<dim;i++){const a=i*1.61803398875,w=v[i]||0;x+=w*Math.cos(a+yaw)*(i%3===0?1:.65);y+=w*Math.sin(a+pitch)*(i%3===1?1:.65);z+=w*Math.sin(a*.7+roll)*(i%3===2?1:.65);}return [x*zoom/dim,y*zoom/dim,z*zoom/dim];}
export const signCycle=(n,binary=true)=>binary?(n%2===0?1:-1):1;
export function entropyOf(values){let sum=values.reduce((a,b)=>a+Math.abs(b),0)+1e-9,h=0;for(const v of values){const p=Math.abs(v)/sum;if(p>1e-9)h-=p*Math.log2(p);}return h;}
