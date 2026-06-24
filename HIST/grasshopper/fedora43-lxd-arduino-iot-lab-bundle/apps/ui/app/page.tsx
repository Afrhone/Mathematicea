'use client';
import React,{useEffect,useState} from 'react';
import {Cpu, Radio, Waves, CircuitBoard, Zap} from 'lucide-react';

const API = process.env.NEXT_PUBLIC_IOT_API || 'http://localhost:8060';

export default function Page(){
  const [data,setData]=useState<any>({});
  const [devices,setDevices]=useState<any>({});
  const [status,setStatus]=useState('connecting');
  useEffect(()=>{
    fetch(API+'/api/devices').then(r=>r.json()).then(setDevices).catch(()=>{});
    const wsurl=API.replace('http','ws')+'/ws';
    const ws=new WebSocket(wsurl);
    ws.onopen=()=>setStatus('live');
    ws.onmessage=(ev)=>{ const m=JSON.parse(ev.data); if(m.type==='sensor.tick') setData(m.data); };
    ws.onerror=()=>setStatus('ws-error');
    ws.onclose=()=>setStatus('closed');
    return()=>ws.close();
  },[]);
  const pixels=data?.amg8833?.pixels || Array.from({length:64},()=>20);
  return <main>
    <section className="card">
      <h1>Arduino IoT Lab</h1>
      <p className="muted">Fedora 43 · LXD · Ceph · USB/Wi-Fi sensors · KiCad MCP</p>
      <span className="pill"><Radio size={14}/> {status}</span>
      <span className="pill"><Cpu size={14}/> {devices?.serial?.length||0} serial</span>
      <h3>Latest</h3>
      <pre>{JSON.stringify(data?.bme280 || {},null,2)}</pre>
      <h3>Devices</h3>
      <pre>{JSON.stringify(devices,null,2)}</pre>
      <button onClick={()=>fetch(API+'/api/command',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({device:'lab',command:'ping'})})}>Send ping command</button>
    </section>
    <section className="canvas">
      <div className="node" style={{left:40,top:40}}><b><Waves size={16}/> BME280</b><small>temp · hum · pressure</small><pre>{JSON.stringify(data?.bme280||{},null,2)}</pre></div>
      <div className="node" style={{left:260,top:150}}><b><Zap size={16}/> BMM150</b><small>3-axis magnetometer</small><pre>{JSON.stringify(data?.bmm150||{},null,2)}</pre></div>
      <div className="node" style={{left:540,top:70,width:220}}><b>AMG8833 IR 8×8</b><div className="heat">{pixels.map((p:number,i:number)=><div className="px" key={i} style={{opacity:Math.min(1,Math.max(.15,(p-18)/12))}} />)}</div></div>
      <div className="node" style={{left:780,top:260}}><b>PN532 RFID</b><small>{data?.pn532?.uid || 'waiting'}</small></div>
      <div className="node" style={{left:420,top:430}}><b><CircuitBoard size={16}/> KiCad MCP</b><small>agent card design scaffold</small></div>
      <svg width="100%" height="100%" style={{position:'absolute',inset:0,pointerEvents:'none'}}>
        <defs><linearGradient id="g"><stop stopColor="#39d9ff"/><stop offset="1" stopColor="#ffb04a"/></linearGradient></defs>
        <path d="M190 100 C260 120 240 190 300 220 S500 120 550 145 S730 260 800 310 S590 440 500 470" fill="none" stroke="url(#g)" strokeWidth="3" opacity=".7"/>
      </svg>
    </section>
  </main>
}
