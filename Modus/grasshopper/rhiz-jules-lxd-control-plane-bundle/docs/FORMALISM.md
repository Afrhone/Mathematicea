# Formalism — bounded dynamical functor system

This bundle turns the poetic axiom layer into falsifiable engineering objects.

## 1. System object

Let a deployment state be:

```text
x_t = (G_t, S_t, M_t, C_t, R_t, Q_t)
```

Where:

- `G_t`: typed hypergraph of nodes, services, repos, tools, routes, secrets, and environments;
- `S_t`: state-space vector: health, pressure, trust, cost, time, risk;
- `M_t`: memory/provenance corpus;
- `C_t`: constraints and gates;
- `R_t`: routing/provider traces;
- `Q_t`: quasi-invariants.

A transition is:

```text
τ_a: x_t → x_{t+1}
```

for action `a`, such as `mirror`, `create_jules_session`, `launch_lxc`, `issue_gateway_token`, `validate`, `promote`, `rollback`.

## 2. Mixed geometry latent state

```text
z_t = [z_E, z_H, z_S]
```

- `z_E`: Euclidean operational variables: CPU, memory, ports, time, trust score.
- `z_H`: Hyperbolic hierarchy: abstraction tree, repo/module/service branching, plan expansion.
- `z_S`: Elliptic/spherical phase: cyclic routines, release loops, health heartbeat, approval cycles.

The controller score is:

```text
score(a) = progress(a)
         - α cost_E(a)
         - β branch_drift_H(a)
         - γ phase_error_S(a)
         - δ invariant_drift(a)
         - ρ blast_radius(a)
         - σ secret_risk(a)
```

## 3. Quasi-invariants

Quasi-invariants are observable quantities expected to drift slowly in normal operation:

```text
q_i(x_t) ≈ q_i(x_{t+1}), with tolerance ε_i
```

Concrete invariants in this bundle:

1. `authority_separation`: GitLab canonical, GitHub Jules mirror, gateway deploy boundary.
2. `no_secret_export`: no long-lived secrets in Git or generated public files.
3. `no_token_url`: bootstrap tokens only in Authorization headers.
4. `no_public_control_ports`: no public Docker socket/LXD/Ceph/Swarm/Ollama direct exposure.
5. `no_cutover_without_validation`: source authority remains until validation + gate.
6. `local_first_with_trace`: local model/provider preferred when healthy, fallback recorded.
7. `node_identity_stability`: node id = hostname + role + registry + gateway record.

## 4. Self-supervised / unsupervised block

The bundle does not ship a trained model. It defines the measurement interface for one.

Observation stream:

```text
o_t = {logs, health, git events, CI status, Jules session states, LXD inventory, gateway tokens, route traces}
```

Optional learned functions:

```text
encoder      f_θ(o_t) → z_t
transition   g_φ(z_t, a_t) → ẑ_{t+1}
quasi-inv    q_ψ(z_t) → Q_t
risk head    r_ω(z_t, a_t) → risk
```

Falsifiable losses:

```text
L = λ1 L_predictive
  + λ2 L_contrastive
  + λ3 L_topology
  + λ4 L_invariant_drift
  + λ5 L_recovery
  + λ6 L_security
```

Ablations:

- no graph;
- no quasi-invariants;
- no recovery;
- no provenance memory;
- Euclidean-only latent state;
- no gateway gate.

Expected measurable outcomes:

- fewer invalid promotions;
- fewer stale projections;
- faster rollback discovery;
- lower contradiction rate between tools and internal state;
- higher reproducibility of CI/Jules handoff.

## 5. Asimolotov Axiom mapping

The axiom poem is encoded as a transition ontology:

```text
Observations → probes → paradigms → experience → future scaffold
→ thought/precept → communication → group entropy → mesh
→ aligned goals → destiny/precept → heuristic action
```

Engineering translation:

```text
telemetry → diagnostic probes → state hypothesis → tested workflow
→ deploy envelope → operator narrative → auditable team state
→ constrained graph → approved action
```

The rule is not mystic authority. It is an operator grammar: observations create paradoxes only when they violate a quasi-invariant; probes are the falsification tools that decide whether a new paradigm/workflow is justified.
