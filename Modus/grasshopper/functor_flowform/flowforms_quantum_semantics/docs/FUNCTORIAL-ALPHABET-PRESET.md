# Functorial Alphabet Preset

The regenerated playground includes a built-in preset named **Functorial Alphabet**. It is loaded by:

- `web/js/flowforms-presets.js`
- `web/assets/presets/functorial-alphabet.json`
- `services/api/data/presets/functorial-alphabet.json`
- MCP tool: `flowforms.functorialPreset`

## Category sketch

We model the drawing system as a small category and a functor into vector dynamics:

```text
Graphème → Phonème → Gesture → ControlGraph → BézierPath → ODEState → SVGPath → FontGlyph
```

The preset functor is:

```text
Φ : GraphèmePhonème → BezierODE
```

Objects are glyph identities, phonetic roles, control graphs, path states, and font exports. Morphisms are transformations such as `read`, `voice`, `gesture`, `sample`, `differentiate`, `integrate`, `morph`, and `export`.

## Active real-valued expression

```text
F_θ(s;g,p,a)=A_θ(Σ_i B_i(s)P_i(g)+Φ_root(s,g)+Φ_rhythm(s,p)+Φ_axiom(s,a))
```

The root glyph becomes a real function because every control point is a vector in `R²`, every stroke is a cubic Bézier map `B_i : [0,1] → R²`, and the whole glyph is a weighted curve graph with semantic fields.

## Preset families

- **Root**: anchored origin traces.
- **Bridge**: connecting morphisms and thresholds.
- **Form**: vessels and stable openings.
- **Rhythm**: oscillatory repetition and recurrence.
- **Nature**: branching growth and organic balance.
- **Momentum**: tangent flow and acceleration.
- **Axiom**: center marks, invariants, solar anchors.

## UI integration

Open `web/index.html`, then use the preset selector at the top of the left sidebar. The `Functor` tab opens a formal modal with the active graphème → phonème → morphism mapping.

## API integration

```bash
curl http://localhost:8080/api/presets
curl http://localhost:8080/api/presets/functorial-alphabet
```
