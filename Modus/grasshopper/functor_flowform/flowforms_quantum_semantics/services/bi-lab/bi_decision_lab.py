#!/usr/bin/env python3
import sys, json, csv, io
from pathlib import Path

def decide(data):
    m=data.get('metrics',{})
    ent=float(m.get('entropy',data.get('entropy',0)))
    coh=float(m.get('coherence',data.get('coherence',0)))
    dom=data.get('dominantState','')
    if ent > 2.5: action='ask-agent'
    elif 'Bridge' in dom or 'bridge' in dom: action='compose-ligature'
    elif coh > .72: action=data.get('action','export')
    else: action='sample-variant'
    return {'action':action,'confidence':round(max(coh,1-min(1,ent/3)),3),'explain':['entropy threshold','dominant semantic state','coherence score']}

def main():
    p=Path(sys.argv[1] if len(sys.argv)>1 else 'examples/quantum-inference-output-example.json')
    data=json.loads(p.read_text())
    d=decide(data)
    out=io.StringIO(); w=csv.writer(out); w.writerow(['metric','value'])
    for k,v in data.get('metrics',{}).items(): w.writerow([k,v])
    print(json.dumps({'input':data,'decision':d,'csv':out.getvalue()}, indent=2))
if __name__ == '__main__': main()
