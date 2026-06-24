# Architecture

## Cascade orchestration

1. **Observe**: collector emits LXD, Docker, Ceph, journal, network and sinkhole events.
2. **Normalize**: Guardian API writes normalized event documents to MongoDB.
3. **Score**: severity base + rolling z-score + entropy/cyclic/burst heuristics produce risk.
4. **Interpret**: LLM gateway analyzes events with local-first provider priority.
5. **Compose**: UI hypernode composer generates dry-run LXD/container/module plans.
6. **Gate**: whitelist + admin allowlist + command dry-run before apply.
7. **Act**: operator-approved containment, DNS sinkhole update, quarantine network placement, or swarm service changes.

## Hypergraph meta-cluster

Nodes represent hosts, LXD instances, containers, services, models, projects, users, commands, events, and data products. Edges represent dependency, ownership, route, health, risk, and orchestration control.

## Predictive analysis

The first release includes deterministic features. It is intentionally auditable:

- EWMA and rolling z-score for metrics.
- Burst detection for short-window spikes.
- Hour-of-day cyclic baseline placeholders.
- DNS/domain entropy heuristic.
- Known RHIZ cascade patterns: Ceph auth drift, RBD map failures, LXD operation stalls, WireGuard mesh drift.

## Gated project lab

Whitelisted users can request a hypernode development lab. The API returns commands as a plan. Actual execution is deliberately separated into reviewed shell automation.
