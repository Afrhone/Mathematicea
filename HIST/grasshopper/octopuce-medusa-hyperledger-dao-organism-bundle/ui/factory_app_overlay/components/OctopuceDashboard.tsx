"use client";

import { useEffect, useState } from "react";

export default function OctopuceDashboard() {
  const [health, setHealth] = useState<any>(null);
  const [graph, setGraph] = useState<any>(null);

  async function load() {
    const base = process.env.NEXT_PUBLIC_OCTOPUCE_GATEWAY || "http://127.0.0.1:7188";
    setHealth(await fetch(`${base}/health`).then(r => r.json()).catch(e => ({error:String(e)})));
    setGraph(await fetch(`${base}/hypergraph/genesis`).then(r => r.json()).catch(e => ({error:String(e)})));
  }

  useEffect(() => { load(); }, []);

  return (
    <main style={{padding:24, fontFamily:"system-ui"}}>
      <h1>Octopuce Medusa DAO Organism</h1>
      <p>Hyperledger · XRPL · EVM · Hypergraph · Factory UI</p>

      <section>
        <h2>Gateway</h2>
        <pre>{JSON.stringify(health, null, 2)}</pre>
      </section>

      <section>
        <h2>DAO Gated Sections</h2>
        <button>Request Whitelist</button>
        <button>Submit Proposal</button>
        <button>Review Contract</button>
        <button>Open Wallet Sandbox</button>
      </section>

      <section>
        <h2>Genesis Hypergraph</h2>
        <pre>{JSON.stringify(graph, null, 2)}</pre>
      </section>

      <section>
        <h2>Mendeleev Matter Lab</h2>
        <iframe src="/periodic-table-widget.html" style={{width:"100%",height:520,border:"1px solid #333"}} />
      </section>
    </main>
  );
}
