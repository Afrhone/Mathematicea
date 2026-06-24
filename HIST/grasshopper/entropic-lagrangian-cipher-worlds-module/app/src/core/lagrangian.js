import {entropy} from './cipher.js';
import {encodeU24, Arrow, Proof, Commutation, Triptych, DomainResolution} from './u24.js';
const TAU=Math.PI*2;
function rnd(x){return (Math.sin(x*127.1+311.7)*43758.5453123)%1;}
function clamp(x,a,b){return Math.max(a,Math.min(b,x));}

export class LagrangianWorlds{
  constructor({worldCount=7, particleCount=12000, stateDimension=8}={}){
    this.worldCount=worldCount; this.particleCount=particleCount; this.dim=stateDimension; this.t=0; this.seed=Math.random()*9999;
    this.q=new Float32Array(particleCount*stateDimension);
    this.v=new Float32Array(particleCount*stateDimension);
    this.world=new Uint8Array(particleCount);
    this.u24=new Uint32Array(particleCount);
    this.mode=new Uint8Array(worldCount);
    this.prevHash='0'.repeat(64); this.hash='0'.repeat(64); this.metrics={}; this.reset();
  }
  reset(){
    for(let i=0;i<this.particleCount;i++){
      this.world[i]=i%this.worldCount;
      for(let d=0;d<this.dim;d++){
        const a=this.seed+i*13.13+d*5.71;
        this.q[i*this.dim+d]=(rnd(a)*2-1)*(0.5+0.2*(i%this.worldCount));
        this.v[i*this.dim+d]=0;
      }
      this.u24[i]=encodeU24({triptych:i%4, commutation:(i>>2)%4, arrow:(i>>4)%4, proof:2, directive:i%8, principle:(i>>3)%8, resolution:2, cluster:i%16, fidelityBand:5, quasi:true});
    }
  }
  markov(ent, p){
    for(let w=0;w<this.worldCount;w++){
      const r=Math.abs(rnd(this.seed+this.t*0.1+w*31));
      const diverge=clamp((ent-p.entropyThreshold)*0.35+p.monteCarloTemperature*0.2,0,0.75);
      if(r<diverge) this.mode[w]=(this.mode[w]+1+(r>.5?1:0))%4;
      else if(r<p.markovBias) this.mode[w]=Math.max(0,this.mode[w]-1);
    }
  }
  step(p, dt=0.016){
    const dim=this.dim, n=this.particleCount;
    let eAcc=0, fidAcc=0, divAcc=0, curlAcc=0;
    const values=[];
    for(let i=0;i<n;i++){
      const off=i*dim, w=this.world[i], mode=this.mode[w];
      const x=this.q[off], y=this.q[off+1]||0, z=this.q[off+2]||0;
      const r2=x*x+y*y+z*z+1e-4;
      const curvature=p.curvature/(1+r2);
      const potentialGrad=[p.stiffness*x+curvature*y, p.stiffness*y-curvature*x, p.stiffness*z];
      const sdf=(Math.sin(this.t*1.7+i*0.017)+Math.cos(x*3+y*2+this.t))*p.sdfNoise;
      const cipherPhase=((this.u24[i]&255)/255)*TAU;
      const feedback=Math.sin(cipherPhase+this.t+w)*p.cipherFeedback;
      const reverse=mode===1 || eAcc/n>p.entropyThreshold;
      for(let d=0;d<dim;d++){
        const q=this.q[off+d], vel=this.v[off+d];
        const neighbor=this.q[off+((d+1)%dim)]-this.q[off+((d+dim-1)%dim)];
        const gamma=p.curvature*neighbor*vel*0.02;
        let force=-(potentialGrad[d%3]||0)*0.25 - p.damping*vel - gamma + sdf*0.06 + feedback*0.03;
        if(mode===2) force += Math.sin(q*4+this.t)*0.05; // fold
        if(mode===3) force -= q*0.08; // collapse
        if(reverse) force -= q*0.05; // reverse arrow backprojection
        this.v[off+d]=vel + force*dt/p.mass;
        this.q[off+d]=clamp(q + this.v[off+d]*dt, -4, 4);
      }
      const local=[this.q[off], this.q[off+1]||0, this.q[off+2]||0, this.v[off], this.v[off+1]||0];
      const ent=entropy(local);
      values.push(ent);
      eAcc+=ent; fidAcc+=1/(1+Math.abs(ent-p.entropyThreshold)); divAcc+=Math.abs(potentialGrad[0]+potentialGrad[1]); curlAcc+=Math.abs(potentialGrad[1]-potentialGrad[0]);
      const arrow=reverse?Arrow.reverse:(mode===3?Arrow.gated:Arrow.forward);
      const comm=mode===2?Commutation.noncommutative:Commutation.quasi;
      const fidelityBand=clamp(Math.floor((1/(1+Math.abs(ent-p.entropyThreshold)))*7),0,7);
      this.u24[i]=encodeU24({triptych:w%4,commutation:comm,arrow,proof:Proof.hash,directive:mode,principle:w%8,resolution:DomainResolution.bound,cluster:w%16,fidelityBand,quasi:ent>p.entropyThreshold});
    }
    const avgEntropy=eAcc/n;
    this.markov(avgEntropy,p);
    this.metrics={entropy:avgEntropy,fidelity:fidAcc/n,divergence:divAcc/n,curl:curlAcc/n,modes:[...this.mode],time:this.t};
    this.t+=dt*p.timeScale;
  }
}
