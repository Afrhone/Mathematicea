export function isPrime(n) {
  if (n < 2) return false;
  if (n === 2) return true;
  if (n % 2 === 0) return false;
  for (let d = 3; d * d <= n; d += 2) if (n % d === 0) return false;
  return true;
}

export function firstPrimes(count) {
  const primes = [];
  let n = 2;
  while (primes.length < count) {
    if (isPrime(n)) primes.push(n);
    n += 1;
  }
  return primes;
}

export function goldenAngle() {
  return Math.PI * (3 - Math.sqrt(5));
}

export function primeRadiPhase(index, tick, prime) {
  const phi = (1 + Math.sqrt(5)) / 2;
  const p = prime ?? firstPrimes(index + 1)[index];
  const wheel = (tick / (p + phi)) + index * goldenAngle();
  return {
    prime: p,
    angle: wheel % (Math.PI * 2),
    harmonic: Math.sin(wheel * phi) * Math.cos(tick / (p + 1)),
    gate: isPrime(Math.floor(tick) + index) ? 1 : 0
  };
}

export function makeClockState({ tick = 0, blades = 12, rpm = 9, torque = 1 } = {}) {
  const primes = firstPrimes(blades);
  const dt = 1 / 60;
  return primes.map((p, i) => {
    const phase = primeRadiPhase(i, tick * rpm, p);
    const radius = 0.38 + 0.038 * p;
    const torsion = Math.sin(phase.angle * 3 + tick * 0.15) * torque / Math.sqrt(p);
    return {
      id: i,
      prime: p,
      angle: phase.angle,
      radius,
      torsion,
      angularVelocity: rpm * (1 + phase.harmonic * 0.11) / (p * dt),
      gate: phase.gate
    };
  });
}
