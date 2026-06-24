'use client';

import { startAuthentication, startRegistration } from '@simplewebauthn/browser';
import React, { useState } from 'react';

type Json = any;

async function api<T>(path: string, body?: any): Promise<T> {
  const res = await fetch(path, {
    method: body ? 'POST' : 'GET',
    headers: body ? { 'Content-Type': 'application/json' } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
  const txt = await res.text();
  let data: any = null;
  try { data = txt ? JSON.parse(txt) : null; } catch { data = { raw: txt }; }
  if (!res.ok) throw new Error(data?.error || `HTTP ${res.status}`);
  return data as T;
}

export default function ClientPanel() {
  const [username, setUsername] = useState('phil');
  const [log, setLog] = useState('Ready.');
  const [status, setStatus] = useState<Json | null>(null);

  const [hash, setHash] = useState('');
  const [memo, setMemo] = useState('uniphi:immutable-registry');

  const [dest, setDest] = useState('');
  const [xrp, setXrp] = useState('0.000001');

  const append = (s: string) => setLog((p) => `${p}\n${s}`);

  const refresh = async () => {
    const st = await api<Json>('/api/xrpl/wallet/status');
    setStatus(st);
    append('Status refreshed.');
  };

  const register = async () => {
    append('Registration: fetching options...');
    const opts = await api<Json>('/api/webauthn/register/options', { username });
    const attResp = await startRegistration(opts);
    append('Registration: verifying...');
    const verified = await api<Json>('/api/webauthn/register/verify', { username, attResp });
    append(JSON.stringify(verified, null, 2));
    await refresh();
  };

  const login = async () => {
    append('Login: fetching options...');
    const opts = await api<Json>('/api/webauthn/auth/options', { username });
    const asseResp = await startAuthentication(opts);
    append('Login: verifying...');
    const verified = await api<Json>('/api/webauthn/auth/verify', { username, asseResp });
    append(JSON.stringify(verified, null, 2));
    await refresh();
  };

  const stepUp = async (op: string) => {
    append(`Step-up (${op}): fetching options...`);
    const opts = await api<Json>('/api/webauthn/operation/options', { op });
    const asseResp = await startAuthentication(opts);
    append(`Step-up (${op}): verifying...`);
    const verified = await api<Json>('/api/webauthn/operation/verify', { op, asseResp });
    append(`Step-up OK (${op}).`);
    return verified.op_token as string;
  };

  const createWallet = async () => {
    const op_token = await stepUp('create_wallet');
    const out = await api<Json>('/api/xrpl/wallet/create', { op_token });
    append(JSON.stringify(out, null, 2));
    await refresh();
  };

  const publishHash = async () => {
    const op_token = await stepUp('publish_hash');
    const out = await api<Json>('/api/xrpl/publish', { op_token, hash, memo });
    append(JSON.stringify(out, null, 2));
  };

  const pay = async () => {
    const op_token = await stepUp('sign_payment');
    const out = await api<Json>('/api/xrpl/pay', { op_token, destination: dest, xrp, memo });
    append(JSON.stringify(out, null, 2));
  };

  return (
    <div className="row">
      <div className="card">
        <h2>Passkeys</h2>
        <p><span className="badge">WebAuthn</span> Register once, then use passkey for login and for step-up approvals.</p>
        <div style={{display:'grid', gap: 10}}>
          <label>
            Username<br/>
            <input value={username} onChange={(e)=>setUsername(e.target.value)} placeholder="username" />
          </label>
          <div style={{display:'flex', gap: 10, flexWrap:'wrap'}}>
            <button onClick={register}>Register passkey</button>
            <button onClick={login}>Login</button>
            <button onClick={refresh}>Refresh status</button>
          </div>
        </div>

        <div className="hr" />

        <h2>Custody wallet (XRPL Testnet default)</h2>
        <p>The server holds the XRPL seed <b>encrypted</b> and only signs after a fresh passkey step-up.</p>
        <div style={{display:'flex', gap: 10, flexWrap:'wrap'}}>
          <button onClick={createWallet}>Create + fund custody wallet</button>
        </div>

        <div className="hr" />

        <h2>Immutable publish (Memo-as-registry)</h2>
        <label>
          Hash / payload<br/>
          <input value={hash} onChange={(e)=>setHash(e.target.value)} placeholder="sha256..., CID..., JSON..., poem..." />
        </label>
        <div style={{height:8}}/>
        <label>
          Memo label<br/>
          <input value={memo} onChange={(e)=>setMemo(e.target.value)} placeholder="memo type" />
        </label>
        <div style={{height:10}}/>
        <button onClick={publishHash}>Publish on XRPL (Payment Memo)</button>

        <div className="hr" />

        <h2>Send payment</h2>
        <label>
          Destination (r...)<br/>
          <input value={dest} onChange={(e)=>setDest(e.target.value)} placeholder="r..." />
        </label>
        <div style={{height:8}}/>
        <label>
          Amount XRP<br/>
          <input value={xrp} onChange={(e)=>setXrp(e.target.value)} />
        </label>
        <div style={{height:10}}/>
        <button onClick={pay}>Sign + submit Payment</button>

        <div className="hr" />
        <small>
          Reference build for experiments. For production custody: HSM / MPC, rate limits, audit logs, isolation, and a real threat model.
        </small>
      </div>

      <div className="card">
        <h2>Server state</h2>
        <p><span className="badge">SSR</span> Next.js App Router + Route Handlers (Node runtime).</p>
        <pre>{status ? JSON.stringify(status, null, 2) : 'No status yet.'}</pre>
        <h2>Console</h2>
        <pre>{log}</pre>
      </div>
    </div>
  );
}
