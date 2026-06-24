export const standardModelPrinciples = {
  gaugeGroups: ['U(1) hypercharge', 'SU(2) weak isospin', 'SU(3) color'],
  families: ['quarks', 'leptons', 'gauge bosons', 'Higgs scalar'],
  conservedToyQuantities: ['charge-like scalar', 'energy proxy', 'finite entropy proxy'],
  missingFromStandardModel: ['gravity', 'dark matter identity', 'dark energy mechanism'],
  caution: 'This library only maps Standard Model vocabulary to visual parameters; it does not simulate quantum field theory.'
};

export function smMixVector({ u = 0, v = 0, tick = 0, mix = 0.5 } = {}) {
  const hypercharge = Math.sin((u + tick * 0.001) * Math.PI * 2);
  const weak = Math.cos((v - tick * 0.0013) * Math.PI * 2);
  const color = Math.sin((u + v) * Math.PI * 3 + tick * 0.002);
  const higgs = 1 / (1 + Math.exp(-(hypercharge + weak + color) * mix));
  return { hypercharge, weak, color, higgs };
}

export function standardModelPalette(value, mix = 0.5) {
  const x = Math.max(0, Math.min(1, value * 0.5 + 0.5));
  return {
    r: 0.1 + x * (0.6 + 0.25 * mix),
    g: 0.08 + Math.sin(x * Math.PI) * 0.72,
    b: 0.28 + (1 - x) * 0.64
  };
}
