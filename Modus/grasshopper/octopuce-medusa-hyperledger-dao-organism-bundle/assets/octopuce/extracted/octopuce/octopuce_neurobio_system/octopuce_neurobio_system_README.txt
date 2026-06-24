Octopuce Neuro-Bio System — Organic Layered Creature
====================================================

Files:
  - octopuce_neurobio_system.obj  : Full 3D model with multiple named groups and materials.
  - octopuce_neurobio_system.mtl  : Material definitions (colors + alpha hints).

Groups / Materials (concept mapping)
------------------------------------
  - membrane_outer     : Outer blobby membrane, turquoise / cyan,
                         semi-transparent. Think: aura / energetic boundary.

  - shell_mid          : Inner shell, purple-toned. Represents mid-layer
                         "phenotype" where traits + behaviors emerge.

  - core_nucleus       : Dense inner blob, cyan / teal. Core consciousness,
                         altered state seed, highest opacity.

  - neural_fibers      : Radial tube network linking core to periphery.
                         Use for "neural links", oscillations, signal flow.

  - neuron_nodes       : Small spheres distributed in shells around the core,
                         hot pink / magenta. Treat as firing nodes / neurons.

  - halo_ring_outer    : Wobbly torus ring, blue-cyan; outer brainwave shell.
  - halo_ring_mid      : Wobbly torus ring, teal; mid brainwave band.
  - halo_ring_inner    : Wobbly torus ring, violet-blue; inner oscillation ring.

  - wave_field         : Radial rippled disk beneath the creature. Encodes
                         system energy, standing waves, "ground field" for
                         brainwave patterns.

Suggested usage in shaders / systems
------------------------------------
  - Morphing / Differential Growth:
      Animate vertices in shaders using noise fields modulated by group
      (outer membrane more fluid, core more stable, fibers wriggling).

  - Phenotype / Genetics:
      Store parameters per-instance (noise amplitude, hue shift,
      diffraction strength). These become the 'genome' controlling
      displacement + color for each agent.

  - Blending Gradients:
      Use the material base colors as anchors, then blend gradients in
      the shader based on world position, view angle, or group id.

  - Diffraction / Iridescence:
      Add a view-angle based rainbow edge (Fresnel) especially on
      membrane_outer and halo rings.

  - Zone Mapping:
      Use the named groups as functional zones (boundary, mid-layer,
      core, network, nodes, wave field) and assign different logic,
      brainwave bands, or data streams to each.

  - Neural Links / Brainwaves:
      Drive animation on neural_fibers and neuron_nodes from your
      agent system (e.g. intensity → emission, firing bursts, color
      pulses travelling along fibers).

This OBJ+MTL is static geometry; morphing, oscillation, and evolutive
behavior are meant to be driven by your rendering / agent logic on top.
