# Uniphi Directives

## Data Packs
This app ships with a **minimal dataset**:
- element symbol/name
- periodic-table positions
- partial electronegativity values (common subset)

To unlock richer fields (shells, electron config, sources, etc.) click **Load Data Pack**
and select an advanced JSON file shaped like:
```json
{ "elements": [ { "number": 1, "symbol": "H", "name": "Hydrogen", ... }, ... ] }
```

Optionally, load an **isotope pack** shaped like:
```json
{ "elements": { "H": { "stable_isotopes":[1,2], "radioisotopes":[3] } } }
```

## Operating modes
- `TABLE`, `SPHERE`, `HELIX`, `GRID` (classic transforms)
- `QUADRATURE` (Z, group, period, entropy → 3D)
- `BOUNCE` (table + oscillatory offsets)
