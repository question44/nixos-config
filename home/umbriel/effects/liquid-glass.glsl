// Liquid-glass window effect: refracts the (already blurred) backdrop in a
// band along the rounded edge, splits it slightly by colour, and adds a
// specular rim lit from the top-left. Only meaningful on translucent windows;
// see the window rule in config.toml.

const float R = 10.0;         // must match appearance.corner_radius (default 10)
const float RIM = 12.0;       // width of the refracting band, logical px
const float STRENGTH = 6.0;   // displacement at the very edge, logical px
const float DISPERSION = 0.08;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 window(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  vec2 p = uv * umbriel_size - halfSize;
  float d = sdRoundBox(p, halfSize, R);  // < 0 inside, 0 on the edge

  vec2 e = vec2(1.0, 0.0);
  vec2 g = vec2(
    sdRoundBox(p + e.xy, halfSize, R) - sdRoundBox(p - e.xy, halfSize, R),
    sdRoundBox(p + e.yx, halfSize, R) - sdRoundBox(p - e.yx, halfSize, R));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);

  float t = clamp(1.0 + d / RIM, 0.0, 1.0);  // 0 in the interior, 1 at the edge
  vec2 off = -n * (t * t * t) * STRENGTH / umbriel_size;

  float r = umbriel_sample(uv + off * (1.0 + DISPERSION)).r;
  vec4 c = umbriel_sample(uv + off);
  float b = umbriel_sample(uv + off * (1.0 - DISPERSION)).b;
  vec3 col = vec3(r, c.g, b);

  float edge = smoothstep(-3.0, -0.5, d);
  float spec = pow(max(dot(n, normalize(vec2(-1.0, -1.0))), 0.0), 2.0);
  col += c.a * (edge * (0.35 * spec + 0.08) + 0.06 * t * t);

  return vec4(min(col, vec3(c.a)), c.a);
}
