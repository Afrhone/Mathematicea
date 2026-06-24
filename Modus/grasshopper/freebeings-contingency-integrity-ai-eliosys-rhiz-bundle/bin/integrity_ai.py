#!/usr/bin/env python3
import argparse, json, os, sys, time, hashlib, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parents[1]

def load_env(path):
    env = {}
    if path and pathlib.Path(path).exists():
        for line in pathlib.Path(path).read_text().splitlines():
            line=line.strip()
            if not line or line.startswith('#') or '=' not in line: continue
            k,v=line.split('=',1); env[k]=v.strip().strip('"').strip("'")
    return env

def event_hash(obj):
    return hashlib.sha256(json.dumps(obj, sort_keys=True).encode()).hexdigest()

def ledger_path(env):
    return pathlib.Path(env.get('LAMBDA_EXCEPTION_LEDGER') or ROOT/'data/ledger/lambda-exceptions.jsonl')

def write_ledger(env, event):
    event['timestamp']=time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    event['hash']=event_hash(event)
    p=ledger_path(env); p.parent.mkdir(parents=True, exist_ok=True)
    with p.open('a') as f: f.write(json.dumps(event, ensure_ascii=False)+'\n')
    return event

def stem_text(text):
    words = re.findall(r"[A-Za-zÀ-ÿ0-9_|/.-]+", text.lower())
    roots=[]
    for w in words:
        root=re.sub(r"(ing|tion|ment|ness|ité|ique|iques|ation|ations|ed|s)$", "", w)
        if len(root)>2: roots.append(root)
    return sorted(set(roots))[:80]

def score_file(path):
    s=pathlib.Path(path).read_text(errors='ignore')
    evidence=len(re.findall(r"(source|cite|hash|http|evidence|preuve|ledger)",s,re.I))
    risk=len(re.findall(r"(secret|token|password|wipe|delete|destroy|public|expose)",s,re.I))
    revers=len(re.findall(r"(rollback|restore|reversible|known-good|backup)",s,re.I))
    drift=len(re.findall(r"(absolute|always|never|guarantee|consciousness|instantané)",s,re.I))
    reward=min(len(s)/2000, 2.0)
    score=max(0.0, min(1.0, 0.45 + 0.08*evidence + 0.06*revers + 0.08*reward - 0.08*risk - 0.04*drift))
    return {'file':str(path),'score':round(score,3),'evidence':evidence,'risk':risk,'reversibility':revers,'drift_terms':drift}

def cmd_check(args):
    env=load_env(args.env)
    min_score=float(env.get('INTEGRITY_MIN_SCORE','0.72'))
    report={'env':args.env,'directive':args.directive,'checks':[]}
    directive = pathlib.Path(args.directive)
    text = directive.read_text(errors='ignore') if directive.exists() else ''
    checks = {
        'no_token_in_url': 'token_in_url: false' in text or 'no_token_in_url' in text,
        'nvme_wipe_gate': 'nvme_wipe_requires_explicit_gate' in text or env.get('ALLOW_NVME_WIPE','NO') != 'YES_I_UNDERSTAND',
        'direct_model_public_exposure_false': 'direct_model_public_exposure: false' in text or '11434/tcp' in text,
        'promotion_gate_present': 'promotion_requires_integrity_score' in text or 'INTEGRITY_MIN_SCORE' in env,
    }
    score=sum(1 for v in checks.values() if v)/len(checks)
    report.update({'score':round(score,3),'min_score':min_score,'pass':score>=min_score,'checks':checks})
    print(json.dumps(report, indent=2))
    write_ledger(env, {'type':'integrity_check','status':'pass' if report['pass'] else 'blocked','score':score,'directive':str(directive)})
    return 0 if report['pass'] else 1

def cmd_rank(args):
    rows=[score_file(p) for p in args.files]
    rows.sort(key=lambda r:r['score'], reverse=True)
    print(json.dumps(rows, indent=2, ensure_ascii=False))
    return 0

def cmd_ledger(args):
    env=load_env(args.env)
    ev={'type':'manual_event','event':args.event,'status':args.status,'operator':args.operator,'reason':args.reason,'scope':args.scope,'evidence':args.evidence,'rollback':args.rollback,'expiry':args.expiry}
    print(json.dumps(write_ledger(env, ev), indent=2, ensure_ascii=False))
    return 0

def cmd_stem(args):
    roots=stem_text(' '.join(args.text))
    print(json.dumps({'stem_roots':roots,'count':len(roots)}, indent=2, ensure_ascii=False))
    return 0

def cmd_panic(args):
    env=load_env(args.env)
    kg=pathlib.Path(args.known_good or env.get('PANIC_STATE_DIR','/opt/freebeings/state/known-good'))
    ev={'type':'panic_reset','reason':args.reason,'known_good':str(kg),'exists':kg.exists(),'status':'ready' if kg.exists() else 'missing_known_good'}
    print(json.dumps(write_ledger(env, ev), indent=2, ensure_ascii=False))
    return 0 if kg.exists() else 2

def cmd_interview(args):
    q=args.question
    roots=stem_text(q)
    print(json.dumps({
        'question':q,
        'stem_roots':roots,
        'answer_protocol':['cite evidence','name uncertainty','check reversibility','rank risk','write ledger'],
        'prompt':f"Answer using evidence, uncertainty, reversibility, and Stem roots: {', '.join(roots)}"
    }, indent=2, ensure_ascii=False))
    return 0

def main():
    ap=argparse.ArgumentParser(description='Integrity AI CLI: Lambda Ethos / Stem policy evaluator')
    sub=ap.add_subparsers(dest='cmd', required=True)
    p=sub.add_parser('check'); p.add_argument('--env',default=str(ROOT/'env/freebeings.env')); p.add_argument('--directive',default=str(ROOT/'directives/eliosys-rhiz.yml')); p.set_defaults(fn=cmd_check)
    p=sub.add_parser('rank'); p.add_argument('files', nargs='+'); p.set_defaults(fn=cmd_rank)
    p=sub.add_parser('ledger'); p.add_argument('--env',default=str(ROOT/'env/freebeings.env')); p.add_argument('--event',required=True); p.add_argument('--status',default='ok'); p.add_argument('--operator',default=os.getenv('USER','unknown')); p.add_argument('--reason',default=''); p.add_argument('--scope',default=''); p.add_argument('--evidence',default=''); p.add_argument('--rollback',default=''); p.add_argument('--expiry',default=''); p.set_defaults(fn=cmd_ledger)
    p=sub.add_parser('stem'); p.add_argument('text', nargs='+'); p.set_defaults(fn=cmd_stem)
    p=sub.add_parser('panic-reset'); p.add_argument('--env',default=str(ROOT/'env/freebeings.env')); p.add_argument('--reason',required=True); p.add_argument('--known-good',default=None); p.set_defaults(fn=cmd_panic)
    p=sub.add_parser('interview'); p.add_argument('--question',required=True); p.set_defaults(fn=cmd_interview)
    args=ap.parse_args(); return args.fn(args)
if __name__=='__main__': sys.exit(main())
