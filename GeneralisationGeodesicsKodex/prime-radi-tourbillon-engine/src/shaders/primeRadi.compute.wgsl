// Prime Radi Tourbillon compute shader skeleton.
// Mirrors the CPU kernel in src/engine/uvGrid.js for future WebGPU pipelines.
struct Params {
  tick: f32,
  torque: f32,
  thermal: f32,
  curvature: f32,
  smMix: f32,
  width: f32,
  height: f32,
  _pad: f32,
};

@group(0) @binding(0) var<storage, read_write> field: array<f32>;
@group(0) @binding(1) var<uniform> params: Params;

fn pseudoPrime(i: u32) -> f32 {
  let table = array<f32, 16>(2.0,3.0,5.0,7.0,11.0,13.0,17.0,19.0,23.0,29.0,31.0,37.0,41.0,43.0,47.0,53.0);
  return table[i % 16u];
}

@compute @workgroup_size(8, 8, 1)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
  if (id.x >= u32(params.width) || id.y >= u32(params.height)) { return; }
  let x = f32(id.x);
  let y = f32(id.y);
  let u = x / max(1.0, params.width - 1.0);
  let v = y / max(1.0, params.height - 1.0);
  let cu = (u - 0.5) * 2.0;
  let cv = (v - 0.5) * 2.0;
  let theta = atan2(cv, cu);
  let rad = sqrt(cu * cu + cv * cv) + 0.000001;
  var amp = 0.0;
  for (var k = 0u; k < 16u; k = k + 1u) {
    let q = pseudoPrime(k);
    let phase = params.tick * (0.013 + 1.0 / (q * 8.0)) + f32(k) * 2.399963;
    amp = amp + sin(theta * q + phase + params.curvature * sin(rad * q)) / q;
  }
  let mobius = sin(theta * 0.5 + params.tick * 0.006) * cos(rad * 3.14159265 * params.curvature);
  let higgsToy = 1.0 / (1.0 + exp(-4.0 * (amp - 0.12)));
  let thermalNoise = params.thermal * 0.05 * sin((x * 17.0 + y * 31.0 + params.tick) * 0.037);
  let value = params.torque * amp + params.smMix * higgsToy + mobius * 0.25 + thermalNoise;
  field[id.y * u32(params.width) + id.x] = value;
}
