/**
 * HabitatOptimalCurves.js
 * 
 * Post-Entwine habitat regeneration curve engine.
 * Applies FULL OSMIUM (dense, stable, coherent) growth curves per habitat type.
 * 
 * After Entwine Paradigm FLOWFIELD settles, this layer:
 * 1. Computes optimal growth curves per habitat (type-specific)
 * 2. Regenerates paths using Lagrangian manifold geometry
 * 3. Locks dense attractors (OSMIUM density state)
 */

import { Vec3 } from "../math/Vec3.js";

export class HabitatOptimalCurves {
  constructor(nodes, edges) {
    this.nodes = nodes;
    this.edges = edges;
    
    // Osmium densities per habitat (coherence locks)
    this.habitatConfigs = {
      leader: {
        radius: 110,
        osmiumDensity: 0.92,
        growthCurve: "exponential_saturation",
        harmonicFreq: 1.2,
        dampingFactor: 0.85,
        attractorStrength: 0.78
      },
      member: {
        radius: 260,
        osmiumDensity: 0.68,
        growthCurve: "logistic_cascade",
        harmonicFreq: 0.95,
        dampingFactor: 0.72,
        attractorStrength: 0.65
      },
      vm: {
        radius: 430,
        osmiumDensity: 0.74,
        growthCurve: "sigmoid_bloom",
        harmonicFreq: 0.88,
        dampingFactor: 0.78,
        attractorStrength: 0.70
      },
      container: {
        radius: 520,
        osmiumDensity: 0.61,
        growthCurve: "harmonic_spiral",
        harmonicFreq: 1.1,
        dampingFactor: 0.65,
        attractorStrength: 0.58
      },
      service: {
        radius: 260,
        osmiumDensity: 0.71,
        growthCurve: "fibonacci_expansion",
        harmonicFreq: 0.76,
        dampingFactor: 0.68,
        attractorStrength: 0.62
      },
      network: {
        radius: 540,
        osmiumDensity: 0.58,
        growthCurve: "geodesic_harmonic",
        harmonicFreq: 0.82,
        dampingFactor: 0.61,
        attractorStrength: 0.55
      },
      stopped: {
        radius: 520,
        osmiumDensity: 0.42,
        growthCurve: "decay_entropy",
        harmonicFreq: 0.45,
        dampingFactor: 0.48,
        attractorStrength: 0.35
      }
    };
  }

  /**
   * Apply optimal habitat curves with Entwine post-processing
   */
  applyEntwineRegeneration(params, t) {
    // Phase 1: Calculate osmium density locks per node
    this.calculateOsmiumStates(t);
    
    // Phase 2: Apply habitat-specific growth curves
    this.applyOptimalCurves(params, t);
    
    // Phase 3: Manifest FULL OSMIUM coherence
    this.manifestFullOsmium(params, t);
    
    // Phase 4: Regenerate Lagrangian manifold paths
    this.regenerateLagrangianPaths(t);
  }

  /**
   * Calculate osmium density state per node
   * Osmium = dense, heavy, ordered → coherence metric
   */
  calculateOsmiumStates(t) {
    for (const n of this.nodes) {
      const habitat = this.habitatConfigs[n.type] || this.habitatConfigs.stopped;
      
      // Osmium coherence = fn(position convergence + harmonic alignment)
      const distToCenter = Math.hypot(n.pos.x, n.pos.z);
      const positionCohesion = Math.exp(-distToCenter / (habitat.radius * 1.5));
      
      // Harmonic alignment = sin wave at optimal frequency
      const harmonicPhase = Math.sin(t * habitat.harmonicFreq + n.id * 0.1);
      const harmonicAlign = (harmonicPhase + 1) * 0.5; // [0..1]
      
      // Final osmium density
      n.osmiumDensity = (positionCohesion * 0.6 + harmonicAlign * 0.4) * habitat.osmiumDensity;
    }
  }

  /**
   * Apply optimal growth curve per habitat
   */
  applyOptimalCurves(params, t) {
    for (const n of this.nodes) {
      const habitat = this.habitatConfigs[n.type] || this.habitatConfigs.stopped;
      const curve = this.getCurveFunction(habitat.growthCurve);
      
      // Curve value at time t
      const curveVal = curve(t, habitat.harmonicFreq, n.id);
      
      // Apply curve as radial force (inward if converging, outward if blooming)
      const r = Math.hypot(n.pos.x, n.pos.z) || 1;
      const radialDir = new Vec3(n.pos.x / r, 0, n.pos.z / r);
      
      // Growth direction = inward toward habitat center
      const desiredRadius = habitat.radius * (0.8 + 0.2 * curveVal); // [0.8*r ... r]
      const radiusError = desiredRadius - r;
      
      const curveForce = radialDir.scale(radiusError * 0.001 * params.curveStrength * habitat.osmiumDensity);
      n.force.add(curveForce);
      
      // Damping respects osmium lock
      n.velocityDamp = habitat.dampingFactor;
    }
  }

  /**
   * Manifest FULL OSMIUM state
   * At maximum osmium density, nodes "bloom" into tight attractors
   */
  manifestFullOsmium(params, t) {
    const fullOsmiumThreshold = 0.85; // Osmium density triggers full lock
    
    for (const n of this.nodes) {
      if (n.osmiumDensity >= fullOsmiumThreshold) {
        const habitat = this.habitatConfigs[n.type] || this.habitatConfigs.stopped;
        
        // Create attractor at habitat center
        const center = new Vec3(0, -270, 0);
        const toCenter = Vec3.sub(center, n.pos);
        const dist = toCenter.len();
        
        if (dist > 5) {
          const pullStrength = habitat.attractorStrength * 0.0025 * n.osmiumDensity;
          const pull = toCenter.normalize().scale(pullStrength);
          n.force.add(pull);
        }
      }
    }
  }

  /**
   * Regenerate Lagrangian paths post-Entwine
   * Ensures geodesic coherence on the manifold
   */
  regenerateLagrangianPaths(t) {
    for (const e of this.edges) {
      const a = e.source, b = e.target;
      
      // Lagrangian constraint: preserve edge length but optimize path
      const delta = Vec3.sub(b.pos, a.pos);
      const len = delta.len() || 1;
      
      // Desired edge length = compromise between osmium densities
      const avgOsmium = ((a.osmiumDensity || 0.5) + (b.osmiumDensity || 0.5)) * 0.5;
      const naturalLen = e.naturalLength || 100;
      const desiredLen = naturalLen * (0.7 + 0.3 * avgOsmium); // Tighter when high osmium
      
      const lenError = desiredLen - len;
      if (Math.abs(lenError) > 2) {
        const correction = delta.normalize().scale(lenError * 0.00025 * avgOsmium);
        a.force.sub(correction);
        b.force.add(correction);
      }
    }
  }

  /**
   * Growth curve functions per habitat
   */
  getCurveFunction(curveType) {
    switch (curveType) {
      case "exponential_saturation":
        return (t, freq, id) => {
          const x = Math.sin(t * freq + id * 0.1);
          return Math.tanh(x); // Saturates at ±1
        };
      
      case "logistic_cascade":
        return (t, freq, id) => {
          const x = 3 * Math.sin(t * freq + id * 0.1);
          return 1 / (1 + Math.exp(-x)); // Classic logistic
        };
      
      case "sigmoid_bloom":
        return (t, freq, id) => {
          const phase = Math.sin(t * freq * 1.5 + id * 0.2);
          return 0.5 * (1 + phase); // Smooth bloom [0..1]
        };
      
      case "harmonic_spiral":
        return (t, freq, id) => {
          const spiral = Math.cos(t * freq + id * 0.5);
          const modulation = Math.sin(t * freq * 0.3);
          return (spiral + 1) * 0.5 * (0.7 + 0.3 * modulation);
        };
      
      case "fibonacci_expansion":
        return (t, freq, id) => {
          const phi = 1.618;
          const fib = Math.sin(t * freq) + Math.sin(t * freq * phi) * 0.5;
          return (fib + 1) * 0.5;
        };
      
      case "geodesic_harmonic":
        return (t, freq, id) => {
          const geodesic = Math.cos(t * freq) * Math.cos(t * freq * 0.6);
          return (geodesic + 1) * 0.5;
        };
      
      case "decay_entropy":
        return (t, freq, id) => {
          const decay = Math.exp(-t * 0.1);
          return decay * Math.sin(t * freq);
        };
      
      default:
        return (t, freq, id) => Math.sin(t * freq);
    }
  }

  /**
   * Serialize habitat state for persistence
   */
  exportHabitatState() {
    const state = {};
    for (const n of this.nodes) {
      state[n.id] = {
        type: n.type,
        osmiumDensity: n.osmiumDensity || 0,
        pos: { x: n.pos.x, y: n.pos.y, z: n.pos.z }
      };
    }
    return state;
  }
}
