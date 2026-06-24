Octopuce Brainfield System — Organic Layered Brain Creature
===========================================================

Files
-----
- octopuce_brainfield_system.obj   : Full 3D brain model with multiple named groups and materials.
- octopuce_brainfield_system.mtl   : Materials with base colors + alpha hints for translucent shading.

Groups / Zones
--------------
- cortex_left, cortex_right
    Blobby, gyri-like hemispheres approximating cerebral cortex.
    Cyan / turquoise gradients, moderate opacity.
    Use as main surface for morphing, gradient blending, diffraction edges.

- limbic_core
    Inner blob nested between hemispheres.
    Purple / magenta tones.
    Encodes "phenotype" & emotional / archetypal traits.

- cerebellum
    Multi-lobed blob at the rear / lower part.
    Good candidate for fine motor / timing / coordination metaphors.

- brainstem
    Curved tube extending downward and slightly forward.
    Represents primary conduit / life-support channel / I/O trunk.

- neural_tree
    Branching tubular network from limbic_core out toward cortex.
    Use for neural links, signal influx, pulses travelling along fibers.

- neuron_nodes
    Numerous small spheres scattered through cortex volume.
    Represent firing neurons or local processing hubs.

- brainwave_shell_outer / mid / inner
    Ellipsoidal shells surrounding the brain at different radii.
    Map to brainwave bands (delta / theta / alpha / beta / gamma) or
    concentric fields of oscillation and altered state.

- energy_field
    Rippled radial field beneath the whole structure.
    Encodes system energy, standing waves, field interactions.

Phenotype & Genetics (design suggestion)
----------------------------------------
Per instance, store a "genome" (noise amplitudes, frequencies,
hue shifts, diffraction strength, firing thresholds). In your
shaders / simulation, map these genes to:

  - Morphing / differential growth:
      Noise-based vertex displacement varying by group.
      Cortex: strong slow undulations.
      Limbic_core: deeper breathing pulse.
      Neural_tree: wriggles + travelling waves.

  - Color gradients & blending:
      Use the material base color as a root, then shift hue
      based on agent state, brainwave band, or data streams.

  - Diffraction / iridescence:
      Add view-angle based rainbow rim (Fresnel) especially on
      cortex_* and brainwave_shell_* groups.

  - Zone mapping:
      Address groups as functional regions (cortex vs limbic vs
      cerebellum vs stem vs network vs field) and bind different
      interaction / behavior rules to each.

  - Brainwaves & oscillations:
      Drive amplitude / phase of morphing in brainwave_shell_*
      and energy_field from band-limited signals or LFOs.

This OBJ+MTL is static geometry; all oscillation, evolution,
altered states and genetic behaviors are intended to be driven
by your rendering + agent systems on top.
