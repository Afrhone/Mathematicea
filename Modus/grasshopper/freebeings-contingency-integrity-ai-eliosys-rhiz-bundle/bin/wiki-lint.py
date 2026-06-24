#!/usr/bin/env python3
import json, pathlib, re, sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
WIKI=pathlib.Path('/opt/freebeings/knowledge/wiki') if pathlib.Path('/opt/freebeings/knowledge/wiki').exists() else ROOT/'data/wiki'
issues=[]
for p in WIKI.glob('*.md'):
    s=p.read_text(errors='ignore')
    if 'Provenance' not in s: issues.append({'file':str(p),'issue':'missing_provenance'})
    if re.search(r'\b(always|guaranteed|absolute truth|instantané de tout)\b',s,re.I): issues.append({'file':str(p),'issue':'overclaim_language'})
    if s.count('chunk:') < 1: issues.append({'file':str(p),'issue':'no_chunk_reference'})
print(json.dumps({'wiki':str(WIKI),'issues':issues,'issue_count':len(issues)},indent=2,ensure_ascii=False))
sys.exit(1 if issues else 0)
