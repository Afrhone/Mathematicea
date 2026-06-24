\
precision highp float;

uniform vec2 u_res;
uniform float u_time;
uniform float u_zoom;
uniform float u_iters;
uniform float u_entropy;
uniform float u_pal;

float hash21(vec2 p) {
  p = fract(p*vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

vec3 pal(float t) {
  float a = 0.55 + 0.45*cos(t + u_pal);
  float b = 0.55 + 0.45*cos(t + 2.094 + u_pal);
  float c = 0.55 + 0.45*cos(t + 4.188 + u_pal);
  return vec3(a,b,c);
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5*u_res) / min(u_res.x, u_res.y);
  uv *= u_zoom;

  float t = u_time*0.12;
  uv += 0.03*vec2(sin(uv.y*2.2 + t), cos(uv.x*2.0 - t));

  float n = (hash21(gl_FragCoord.xy + u_time) - 0.5) * u_entropy * 0.15;

  vec2 z = uv;
  vec2 c = vec2(-0.12 + 0.15*sin(t*0.8), 0.68 + 0.18*cos(t*0.7));
  float it = 0.0;

  for (int i=0; i<512; i++) {
    if (float(i) >= u_iters) break;
    z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
    z += n * vec2(sin(z.y + t), cos(z.x - t));
    float r2 = dot(z,z);
    if (r2 > 16.0) { it = float(i); break; }
    it = float(i);
  }

  float mu = it - log2(log2(max(1.0001, dot(z,z)))) + 4.0;
  float col = mu / max(1.0, u_iters);

  vec3 base = pal(6.283*(col + 0.05*sin(t)));
  float v = smoothstep(1.3, 0.0, length(uv)/u_zoom);
  float glow = exp(-2.2*abs(col - 0.35));
  vec3 outc = base * (0.35 + 0.65*v) + glow*vec3(0.7,0.9,1.0)*0.15;

  float stars = step(0.9985, hash21(gl_FragCoord.xy*0.8 + 17.0));
  outc += stars*0.8;

  gl_FragColor = vec4(outc, 1.0);
}
