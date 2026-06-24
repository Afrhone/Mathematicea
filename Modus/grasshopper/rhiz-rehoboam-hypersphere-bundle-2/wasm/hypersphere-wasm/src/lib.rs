use wasm_bindgen::prelude::*;
#[wasm_bindgen]
pub fn project8_to3(input: &[f32]) -> Vec<f32> {
    let mut v = [0.0f32; 8];
    for i in 0..8.min(input.len()) { v[i] = input[i]; }
    let norm = v.iter().map(|x| x*x).sum::<f32>().sqrt().max(1e-6);
    for x in &mut v { *x /= norm; }
    let a = v[0]*v[0]+v[1]*v[1]-v[2]*v[2]-v[3]*v[3];
    let b = 2.0*(v[0]*v[2]+v[1]*v[3]);
    let c = 2.0*(v[1]*v[2]-v[0]*v[3]);
    let d = v[4]*v[4]+v[5]*v[5]-v[6]*v[6]-v[7]*v[7];
    let mut x = [a, b, c + 0.16*d];
    let m = (x[0]*x[0]+x[1]*x[1]+x[2]*x[2]).sqrt().max(1e-6);
    x.iter_mut().for_each(|e| *e /= m);
    x.to_vec()
}
