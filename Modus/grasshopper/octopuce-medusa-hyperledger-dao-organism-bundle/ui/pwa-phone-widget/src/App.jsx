import React, {useEffect, useState} from 'react';
import { createRoot } from 'react-dom/client';

function App(){
  const [health,setHealth]=useState(null);
  const base = import.meta.env.VITE_GATEWAY || 'http://127.0.0.1:7188';
  useEffect(()=>{ fetch(base+'/health').then(r=>r.json()).then(setHealth).catch(e=>setHealth({error:String(e)})); },[]);
  return <main style={{fontFamily:'system-ui',padding:20,background:'#050510',color:'#eafcff',minHeight:'100vh'}}>
    <h1>🐙 Medusa DAO</h1>
    <p>Phone widget: whitelist, wallet, organism status.</p>
    <button>Summon YETI Gate</button>
    <button>Request DAO Access</button>
    <button>Open Wallet Sandbox</button>
    <pre>{JSON.stringify(health,null,2)}</pre>
  </main>
}

createRoot(document.getElementById('root')).render(<App/>);
