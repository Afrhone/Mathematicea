# Five-fold Quasicrystal Orbit

Given:

```math
x \dashv y = \tau^2 x - \tau y,\quad \tau = \Phi + \delta
```

At `δ=0`, `τ=Φ`, the orbit over a pentagon forms a visual quasicrystal toy model.

Implementation path:

1. Generate regular pentagon vertices.
2. Apply quasiaddition to adjacent pairs.
3. Iterate under small `δ` perturbations.
4. Use output as particle seeds in WebGL hypersphere projection.

This is implemented as `/api/functor/mendeleev` and intended as a visual/educational field generator.
