import { makeClockState } from './primeClock.js';

export function rk4Step(state, dt, deriv) {
  const k1 = deriv(state);
  const k2 = deriv(state.map((v, i) => v + k1[i] * dt * 0.5));
  const k3 = deriv(state.map((v, i) => v + k2[i] * dt * 0.5));
  const k4 = deriv(state.map((v, i) => v + k3[i] * dt));
  return state.map((v, i) => v + (dt / 6) * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]));
}

export function propellerDerivative({ damping = 0.035, stiffness = 0.11, drive = 1 } = {}) {
  return ([theta, omega]) => [
    omega,
    drive * Math.sin(theta * 3) - damping * omega - stiffness * Math.sin(theta)
  ];
}

export function generateMechanicsFrame({ tick = 0, blades = 12, torque = 1, dt = 1 / 60 } = {}) {
  const clock = makeClockState({ tick, blades, torque });
  const frames = clock.map((blade) => {
    const theta0 = blade.angle;
    const omega0 = blade.angularVelocity * 0.001;
    const [theta, omega] = rk4Step([theta0, omega0], dt, propellerDerivative({ drive: torque / blade.prime }));
    const lift = Math.sin(theta) * omega * blade.radius;
    const torsion = blade.torsion + Math.cos(theta * blade.prime) * 0.03;
    return { ...blade, theta, omega, lift, torsion };
  });
  return {
    tick,
    blades: frames,
    totalAngularMomentum: frames.reduce((s, b) => s + b.radius * b.radius * b.omega, 0),
    totalLift: frames.reduce((s, b) => s + b.lift, 0)
  };
}

export function makeTourbillonVertices(frame, coilTurns = 3) {
  const vertices = [];
  for (const blade of frame.blades) {
    const base = blade.theta;
    for (let j = 0; j < 16; j++) {
      const t = j / 15;
      const a = base + t * Math.PI * 2 * coilTurns;
      const r = blade.radius * (0.65 + 0.35 * t);
      vertices.push({
        x: Math.cos(a) * r,
        y: Math.sin(a) * r,
        z: Math.sin(t * Math.PI + blade.torsion) * 0.42,
        prime: blade.prime,
        lift: blade.lift,
        torsion: blade.torsion
      });
    }
  }
  return vertices;
}
