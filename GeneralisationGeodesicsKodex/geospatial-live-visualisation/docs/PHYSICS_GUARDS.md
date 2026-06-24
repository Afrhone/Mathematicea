# Physics-inspired guards

The bundle validates the live field with conservative toy guards:

1. **Thermodynamics:** temperature must remain positive in Kelvin and entropy proxy must remain non-negative.
2. **Kinetic:** kinetic energy is computed as `0.5 · mass · |v|²` for each event.
3. **Electrodynamic proxy:** curl is a signed velocity/charge twist used only for visualization.
4. **Finite field:** all raster cells must be finite numbers.
5. **Bounded signal quality:** quality is clamped to `[0, 1]`.

These are stability guards, not a complete physical law solver.
