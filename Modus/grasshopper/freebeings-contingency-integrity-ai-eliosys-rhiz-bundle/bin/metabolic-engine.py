#!/usr/bin/env python3
import argparse, hashlib, json, os, pathlib, re, time, urllib.request
ROOT = pathlib.Path(__file__).resolve().parents[1]

def load_env(path):
    env={}
    p=pathlib.Path(path)
    if p.exists():
        for line in p.read_text().splitlines():
            if '=' in line and not line.strip().startswith('#'):
                k,v=line.split('=',1); env[k.strip()]=v.strip().strip('"').strip("'")
    return env

def paths(env):
    base=pathlib.Path(env.get('KNOWLEDGE_ROOT', ROOT/'data'))
    return {k:pathlib.Path(env.get(k.upper()+'_DIR', base/k.lower())) for k in ['raw','compost','ferment','wiki','canon','graph']}

def sha(s): return hashlib.sha256(s if isinstance(s,bytes) else s.encode()).hexdigest()

def chunks(text, n=1800):
    paras=re.split(r'\n\s*\n', text)
    out=[]; cur=''
    for p in paras:
        if len(cur)+len(p)>n and cur:
            out.append(cur.strip()); cur=p
        else: cur += '\n\n'+p
    if cur.strip(): out.append(cur.strip())
    return out

def concepts(text):
    words=re.findall(r"[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ0-9_|/-]{3,}", text.lower())
    stop=set('this that with from into pour avec dans comme plus moins data system node model graph workflow'.split())
    freq={}
    for w in words:
        if w in stop: continue
        freq[w]=freq.get(w,0)+1
    return [w for w,_ in sorted(freq.items(), key=lambda kv:(-kv[1],kv[0]))[:18]]

def ollama(env, prompt):
    host=env.get('OLLAMA_HOST','http://127.0.0.1:11434').rstrip('/')
    model=env.get('EDGE_MODEL','llama3.2:3b')
    data=json.dumps({'model':model,'prompt':prompt,'stream':False}).encode()
    req=urllib.request.Request(host+'/api/generate', data=data, headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read().decode()).get('response','')
    except Exception as e:
        return ''

def ingest(env):
    ps=paths(env); [p.mkdir(parents=True, exist_ok=True) for p in ps.values()]
    rows=[]
    for src in ps['raw'].glob('**/*'):
        if src.is_file() and src.suffix.lower() in ['.txt','.md','.log','.json','.yml','.yaml','.csv']:
            text=src.read_text(errors='ignore')
            h=sha(text)
            rows.append({'source':str(src),'hash':h,'bytes':len(text),'chunks':len(chunks(text))})
    manifest=ps['graph']/ 'raw_manifest.json'
    manifest.write_text(json.dumps(rows,indent=2,ensure_ascii=False))
    print(f'ingested {len(rows)} files -> {manifest}')

def compile_chunks(env):
    ps=paths(env); ps['compost'].mkdir(parents=True,exist_ok=True); ps['graph'].mkdir(parents=True,exist_ok=True)
    edges=[]; count=0
    for src in ps['raw'].glob('**/*'):
        if not src.is_file(): continue
        text=src.read_text(errors='ignore')
        for i,ch in enumerate(chunks(text)):
            h=sha(ch)[:16]
            out=ps['compost']/f'{src.stem}.{i:03d}.{h}.md'
            out.write_text(f"---\nsource: {src}\nchunk: {i}\nhash: {h}\n---\n\n{ch}\n", encoding='utf-8')
            edges.append({'src':str(src),'dst':str(out),'type':'contains','hash':h})
            count+=1
    (ps['graph']/ 'edges.jsonl').write_text('\n'.join(json.dumps(e,ensure_ascii=False) for e in edges)+'\n')
    print(f'compiled {count} chunks')

def ferment(env):
    ps=paths(env); ps['ferment'].mkdir(parents=True, exist_ok=True); ps['wiki'].mkdir(parents=True, exist_ok=True)
    index=[]
    for ch in ps['compost'].glob('*.md'):
        text=ch.read_text(errors='ignore')
        cons=concepts(text)
        summary=ollama(env, 'Summarize this chunk in 5 concise bullets with provenance preserved:\n\n'+text[:6000])
        if not summary:
            summary='\n'.join('- '+c for c in cons[:8])
        out=ps['ferment']/(ch.stem+'.summary.md')
        out.write_text(f"# Ferment: {ch.name}\n\nSource chunk: `{ch}`\n\n## Concepts\n\n" + '\n'.join(f'- [[{c}]]' for c in cons) + f"\n\n## Summary\n\n{summary}\n", encoding='utf-8')
        for c in cons: index.append((c,ch, out))
    pages={}
    for c,ch,out in index:
        pages.setdefault(c,[]).append((ch,out))
    for c,refs in pages.items():
        body=f"# {c}\n\n## Provenance\n" + ''.join(f"- chunk: `{ch}` → ferment: `{out}`\n" for ch,out in refs[:20]) + "\n## Notes\n\n- Pending human/agent synthesis.\n"
        (ps['wiki']/(c.replace('/','_')+'.md')).write_text(body, encoding='utf-8')
    print(f'fermented {len(index)} concept links into {len(pages)} wiki pages')

def promote(env):
    ps=paths(env); ps['canon'].mkdir(parents=True, exist_ok=True)
    promoted=[]
    for page in ps['wiki'].glob('*.md'):
        text=page.read_text(errors='ignore')
        evidence=text.count('chunk:')
        if evidence >= 2 and len(text)>80:
            dst=ps['canon']/page.name
            dst.write_text(text + f"\n---\nPromoted: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\nEvidence-links: {evidence}\n", encoding='utf-8')
            promoted.append(str(dst))
    print(json.dumps({'promoted':promoted,'count':len(promoted)},indent=2))

def cycle(env):
    ingest(env); compile_chunks(env); ferment(env); promote(env)

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['ingest','compile','ferment','promote','cycle'])
    ap.add_argument('--env', default=str(ROOT/'env/freebeings.env'))
    args=ap.parse_args(); env=load_env(args.env)
    {'ingest':ingest,'compile':compile_chunks,'ferment':ferment,'promote':promote,'cycle':cycle}[args.cmd](env)
