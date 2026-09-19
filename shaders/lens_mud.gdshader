shader_type canvas_item;
render_mode unshaded;

uniform float age = 99.0;
uniform float power = 1.0;
uniform float seed = 0.0;
uniform bool calm = false;
uniform vec3 splats[12];

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
 vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
 vec4 mud = vec4(0.0);
 float fade = 1.0 - smoothstep(3.7, 5.7, age);
 for (int i = 0; i < 12; i++) {
  if (calm && i > 5) { continue; }
  float t = age - float(i) * 0.016;
  if (t < 0.0 || fade < 0.001) { continue; }
  float flight = pow(clamp(t / 0.24, 0.0, 1.0), 2.7);
  float stuck = max(0.0, t - 0.24);
  vec3 s = splats[i];
  vec2 target = s.xy + vec2(sin(seed + float(i) * 2.3) * 0.016, 0.0);
  vec2 origin = vec2(s.x < 0.5 ? 0.42 : 0.58, 0.79);
  vec2 center = mix(origin, target, flight);
  center.y += pow(stuck, 1.3) * 0.009;
  float radius = s.z * mix(0.06, 1.0, flight) * mix(0.7, 1.1, power) * (calm ? 0.73 : 1.0);
  vec2 q = (UV - center) * vec2(1.7777778, 1.0) / max(radius, 0.001);
  if (abs(q.x) > 1.5 || q.y < -1.5 || q.y > 2.3) { continue; }
  float angle = atan(q.y, q.x);
  float lobes = 1.0 + sin(angle * 2.0 + float(i)) * 0.13 + sin(angle * 3.0 + seed + float(i)) * 0.09 + sin(angle * 5.0 + float(i) * 0.8) * 0.035;
  float grain = noise2(q * 10.0 + float(i) * 9.1);
  float d = length(q * vec2(1.0, 0.87)) / lobes;
  float core = 1.0 - smoothstep(0.80, 1.00 + grain * 0.025, d);
  float rim = 1.0 - smoothstep(0.93, 1.06, d);
  float drip = min(stuck * 0.18, 0.8);
  float runner = (1.0 - smoothstep(0.045, 0.12, abs(q.x + 0.21 + sin(q.y * 2.0) * 0.035))) * smoothstep(0.3, 0.75, q.y) * (1.0 - smoothstep(0.8 + drip, 1.10 + drip, q.y));
  float opacity = max(core * 0.93 + (rim - core) * 0.23, runner * 0.68) * fade * (calm ? 0.75 : 1.0);
  vec3 clay = mix(vec3(0.25, 0.14, 0.068), vec3(0.57, 0.39, 0.21), noise2(q * 3.2 + seed));
  clay *= 0.88 + grain * 0.24;
  float shine = (1.0 - smoothstep(0.025, 0.08, abs(d - 0.89))) * (1.0 - smoothstep(-0.75, -0.2, q.y));
  clay += vec3(0.34, 0.32, 0.25) * shine * 0.5;
  mud.rgb = mix(mud.rgb, clay, opacity / max(mud.a + opacity, 0.001));
  mud.a = opacity + mud.a * (1.0 - opacity);
 }
 COLOR = mud;
}
