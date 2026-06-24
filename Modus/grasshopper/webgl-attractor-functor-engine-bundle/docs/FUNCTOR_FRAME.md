# Functor Frame Mapping

Preserved symbolic frame:

```text
FUNCTOR: [f(Φ){4} df(N|R) {4,5}Z {ø,3,5}C g(f) KN|KT Kω
FRAME: R numeral; n règle {ø,0,1,2,…}; σ(n)=Re; σ(n+1)=Im
CYCLE k; P(n) immutable; 1 fongible; 1 binary
Operand/Lagrange: dXi/dt = Σ Xk
P(P|Q), P(n), P(k)
```

Engine mapping:

| Symbolic frame | Engine module |
|---|---|
| `R numeral` | real axis / real projection lane |
| `σ(n)=Re`, `σ(n+1)=Im` | alternating complex root mapping |
| `σ(n+1)=±σ(n)` | binary cycle sign flip |
| `{4}`, `{4,5}`, `{ø,3,5}` | projection basis presets |
| `f(Φ)` | phase field shader |
| `df(N|R)` | differential field / root force |
| `CYCLE k` | cyclic time operator |
| `P(n)` | identity magnitude potential |
| `P(k)` | functor potential / feedback strength |
| `dXi/dt = Σ Xk` | coupled attractor update |

Numerical core:

```text
dXᵢ/dt = α·root_force(Xᵢ, roots(P)) + β·ΣXₖ + γ·curl_noise + δ·lens_flux + ε·cycle(k,n)
P(z,t) = z^d + Σ a_j(t)z^j
```
