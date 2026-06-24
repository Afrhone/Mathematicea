Octopuce Brain ProteinFold System — Image-Aligned High-Fidelity Model
=====================================================================

This model is designed to echo the aesthetics of the reference
fluorescent brain image: bright cyan / purple / yellow gradients,
heavy vascular branches on the left, and layered cortex on the right.

It also introduces a "protein-fold-like" lattice structure: chains
that weave and nest through the left hemisphere, inspired by how
protein backbones fold and pack in 3D, but generated procedurally
(not from biological prediction data).

Files
-----
- octopuce_brain_proteinfold_system_hires.obj   : Hi-res layered brain model with nested topology.
- octopuce_brain_proteinfold_system_hires.mtl   : Materials with emissive-friendly colors + alpha hints.

Main Groups / Zones
-------------------
- cortex_left, cortex_right
    Dense gyri / sulci with image-style color gradients
    (cyan-turquoise / yellow-green). Primary surface for
    morphing, diffraction edges, and gradient blending.

- limbic_core
    Central purple-magenta blob under the cortex. Good anchor
    for phenotype, genetics, and archetypal state variables.

- cerebellum
    Multilobed cyan / blue structure at the rear-bottom.

- brainstem
    Curved tube extending downward; base for I/O and systemic
    energy flow.

- neural_tree
    Branching tubular network connecting limbic_core to cortex.
    Use for neural links, oscillation propagation, and influx
    mapping.

- neuron_nodes
    Numerous small magenta spheres packed through cortex volume,
    acting as neuron / node markers.

- brainwave_shell_outer / mid / inner
    Concentric ellipsoids around the whole brain. Designed as
    carriers for banded oscillations, brainwaves, and altered
    state envelopes.

- energy_field
    Rippled radial field beneath the system. Represents global
    system energy and interference patterns.

- proteinfold_lattice_left
    Thick purple chain-lattice over the left hemisphere.
    Built from multiple "folded chains" guided by an
    energy-inspired process:
      * attraction toward a cortical target region,
      * repulsion from the centerline,
      * smoothed random walk for local irregularity.
    This approximates how a polymer chain seeks low-energy
    conformations while staying packed and nested.

Usage Notes
-----------
- Drive morphing + differential growth via vertex shaders using
  per-group noise fields modulated by your agent "genomes".

- Use the different groups as functional zones for:
      * phenotype & trait expression
      * brainwave / oscillation bands
      * data-driven activation and interactions

- For diffraction / iridescent effects, apply view-angle-based
  rainbow rims especially on cortex_*, brainwave_shell_*, and
  proteinfold_lattice_left.

This geometry is static; folding dynamics and state evolution
are intended to be layered on top via your simulation / shader
logic.
