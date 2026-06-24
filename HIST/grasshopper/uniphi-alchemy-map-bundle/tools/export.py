#!/usr/bin/env python3
"""
Uniphi-Alchemy Map exporter

Usage:
  python3 export.py examples/example_alchemy_map.json > out.md
"""

import json
import sys

PHASE_NAMES = ["spark","calcination","dissolution","separation","conjunction","distillation","coagulation"]

NAME_MAP = {
  "aether":"Aether (Vision)",
  "mercurius":"Mercurius (Flow / Interoperability)",
  "sulfur":"Sulfur (Soul / Urgency)",
  "sal":"Sal (Structure / Truth)",
  "vessel":"Vessel (Infrastructure / Container)",
  "catalyst":"Catalyst (Play / Risk)",
  "noise":"Noise (Oracle / Randomness)",
  "guardian":"Guardian (Security / Boundaries)",
  "witness":"Witness (Story / Audience)",
}

OP_MAP = {
  "calcination":"Calcination",
  "dissolution":"Dissolution",
  "separation":"Separation",
  "conjunction":"Conjunction",
  "fermentation":"Fermentation",
  "distillation":"Distillation",
  "coagulation":"Coagulation",
}

ARCH_MAP = {
  "cosmic_chemist":"Cosmic Chemist",
  "net_weaver":"Net Weaver",
  "vault_guardian":"Vault Guardian",
  "trickster_debugger":"Trickster Debugger",
  "archivist":"Archivist",
  "poet_witness":"Poet-Witness",
}

def json_to_md(d: dict) -> str:
    ph = int(d.get("phase", 0))
    phase_label = PHASE_NAMES[ph] if 0 <= ph < len(PHASE_NAMES) else ""
    out = []
    out.append("# Uniphi-Alchemy Map\n")
    out.append(f"**Project / Work:** {d.get('project','')}\n")
    out.append(f"**Date:** {d.get('date','')}\n")
    out.append(f"**Phase (0–6):** {ph} ({phase_label})\n")
    out.append(f"**One-line intent:** {d.get('intent','')}\n")
    out.append("\n---\n")
    out.append("## Axioms\n")
    for ax in d.get("axioms", []):
        out.append(f"- {ax}")
    out.append("\n\n---\n")
    out.append("## 9 Ingredients\n")
    for ing in d.get("ingredients", []):
        k = ing.get("key","")
        out.append(f"### {NAME_MAP.get(k,k)} — {ing.get('rating','')}/5\n")
        out.append(ing.get("note",""))
        out.append("")
    out.append("\n---\n")
    out.append("## 7 Operations\n")
    for op in d.get("operations", []):
        k = op.get("key","")
        out.append(f"### {OP_MAP.get(k,k)}\n")
        out.append(op.get("notes",""))
        out.append("")
    out.append("\n---\n")
    out.append("## Archetypes\n")
    arch = d.get("archetypes", [])
    out.append(", ".join(ARCH_MAP.get(a,a) for a in arch) if arch else "(none)")
    out.append("\n\n### Shadow Loop\n")
    out.append(d.get("shadow_loop","none"))
    out.append("\n\n### Counter-spell\n")
    out.append(d.get("counter_spell",""))
    out.append("\n\n---\n")
    out.append("## Balance Next Step\n")
    out.append(d.get("balance_next_step",""))
    out.append("\n\n---\n")
    out.append("## 60-Second Ritual\n")
    r = d.get("ritual", {})
    out.append(f"**Anchor:** {r.get('anchor','')}")
    out.append(f"**Stake:** {r.get('stake','')}")
    out.append(f"**Spell:** {r.get('spell','')}\n")
    out.append(r.get("paragraph",""))
    out.append("")
    return "\n".join(out)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 export.py <map.json>", file=sys.stderr)
        sys.exit(2)
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        d = json.load(f)
    print(json_to_md(d))

if __name__ == "__main__":
    main()
