#!/usr/bin/env -S python3 -S
import json, os, sys, math, time

def f(name, default=0.0):
    try: return float(os.environ.get(name, default))
    except ValueError: return float(default)

def readiness():
    score = 100.0
    reasons = []
    def penalty(points, reason):
        nonlocal score
        score -= points
        reasons.append({"penalty": points, "reason": reason})
    if f('SWAP_USED_PCT') > f('MAX_SWAP_USED_PCT', 50): penalty(25, 'swap pressure')
    if f('IOWAIT_PCT') > f('MAX_IOWAIT_PCT', 30): penalty(25, 'iowait pressure')
    if f('LOAD_PER_CPU') > f('MAX_LOAD_PER_CPU', 2.5): penalty(15, 'load per cpu pressure')
    if f('FREE_GIB', 999) < f('MIN_FREE_GIB', 4): penalty(15, 'low free disk')
    if os.environ.get('IDENTITY_OK','0') != '1': penalty(20, 'identity not validated')
    if os.environ.get('ENDPOINT_OK','0') != '1': penalty(20, 'endpoint not validated')
    if os.environ.get('CONTROL_PORTS_PRIVATE','0') != '1': penalty(40, 'control ports privacy not proven')
    if os.environ.get('NO_SECRET_LEAK','1') != '1': penalty(60, 'secret leak risk')
    return {"score": max(0.0, min(100.0, score)), "reasons": reasons, "ts": int(time.time())}

def latent(action):
    phase = {'mirror':0.1,'create_session':0.25,'launch_lxc':0.40,'validate':0.65,'promote':0.85,'rollback':0.95}.get(action,0.5)
    branch = {'mirror':1,'create_session':3,'launch_lxc':2,'validate':1,'promote':1,'rollback':2}.get(action,2)
    cost = {'mirror':1,'create_session':2,'launch_lxc':3,'validate':1,'promote':5,'rollback':3}.get(action,2)
    return {"action": action, "z_E": [cost, f('LOAD_PER_CPU'), f('IOWAIT_PCT')], "z_H": [math.log1p(branch), branch/(branch+1)], "z_S": [math.cos(2*math.pi*phase), math.sin(2*math.pi*phase)]}

def main():
    cmd = sys.argv[1] if len(sys.argv)>1 else 'score'
    if cmd == 'score': print(json.dumps(readiness(), indent=2))
    elif cmd == 'latent': print(json.dumps(latent(sys.argv[2] if len(sys.argv)>2 else 'validate'), indent=2))
    else:
        print('usage: agent-graph-orchestrator.py score | latent <action>', file=sys.stderr)
        return 2
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
