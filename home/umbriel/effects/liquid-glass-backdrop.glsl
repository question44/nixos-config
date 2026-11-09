// Liquid-glass backdrop: drawn by the window's blur node, under the window.
// Needs Umbriel's backdrop effect kind (patches/umbriel-backdrop-effect.patch):
//   umbriel_sample(uv)      the blurred backdrop
//   umbriel_sample_raw(uv)  the unblurred backdrop
// both readable up to the preset's padding past the window edge.
//
// Thick convex slab: the flat body shows the frosted backdrop; the rim is a
// quarter-ellipse bevel that refracts (Snell's law) the sharp backdrop from
// the rim into the glass, with a per-channel colour split. A rim
// highlight lit from the top-left, a faint top sheen and a soft inner shadow
// along the bottom give it depth.

const float R = 18.0;          // must match the glass window rule's corner_radius
const float BEZEL = 26.0;      // rim width, logical px
const float HEIGHT = 30.0;     // glass thickness at the rim, logical px
const float IOR = 1.5;         // refractive index
const float SPREAD = 0.025;    // index spread between colour channels
const float REACH = 22.0;      // cap on the bend, logical px (keep <= preset padding)
const float SHARP = 0.85;      // how much of the rim shows the unblurred backdrop
const float VIBRANCY = 1.2;    // saturation of the frosted body
const float LIFT = 1.06;       // brightness of the body (multiplicative)
const float RIM = 0.55;        // specular rim line
const float GLOW = 0.16;       // bevel glow
const float SHEEN = 0.05;      // top sheen
const float SHADOW = 0.18;     // bottom inner shadow
const vec2 LIGHT = vec2(-0.5, -0.866);  // from the top-left (y down)

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Logical px the ray moves along the outward normal on its way through the rim:
// negative (inward) for a convex rim.
float bend(float u, float ior) {
  // u: 1 at the edge, 0 at the rim's inner side. Quarter-ellipse surface.
  float rise = sqrt(max(1.0 - u * u, 0.0));
  vec2 n = normalize(vec2(u / BEZEL, rise / HEIGHT));  // (outward, up)
  vec3 ray = refract(vec3(0.0, 0.0, -1.0), normalize(vec3(n.x, 0.0, n.y)), 1.0 / ior);
  float run = HEIGHT * rise * ray.x / max(-ray.z, 1e-3);
  return run / (1.0 + abs(run) / REACH);  // soft cap at REACH
}

vec3 tap(vec2 uv, vec2 dir, float px, float sharp) {
  vec2 o = dir * px / umbriel_size;
  return mix(umbriel_sample(uv + o).rgb, umbriel_sample_raw(uv + o).rgb, sharp);
}

vec4 backdrop(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  float r = min(R, min(halfSize.x, halfSize.y));
  vec2 p = uv * umbriel_size - halfSize;
  float d = sdRoundBox(p, halfSize, r);
  float s = max(-d, 0.0);

  float h = 2.0;
  vec2 g = vec2(
    sdRoundBox(p + vec2(h, 0.0), halfSize, r) - sdRoundBox(p - vec2(h, 0.0), halfSize, r),
    sdRoundBox(p + vec2(0.0, h), halfSize, r) - sdRoundBox(p - vec2(0.0, h), halfSize, r));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);  // outward

  vec3 col;
  float u = 1.0 - clamp(s / BEZEL, 0.0, 1.0);
  if (u > 0.0) {
    float sharp = SHARP * smoothstep(0.0, 0.6, u);
    col = vec3(
      tap(uv, n, bend(u, IOR - SPREAD), sharp).r,
      tap(uv, n, bend(u, IOR), sharp).g,
      tap(uv, n, bend(u, IOR + SPREAD), sharp).b);
  } else {
    col = umbriel_sample(uv).rgb;
  }

  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = max(mix(vec3(lum), col, VIBRANCY), 0.0) * LIFT;

  float facing = dot(n, LIGHT);
  float key = pow(max(facing, 0.0), 1.5);
  float back = 0.5 * pow(max(-facing, 0.0), 1.5);
  col += GLOW * (key + back + 0.1) * exp(-s / 6.0);
  col += RIM * (key + back + 0.2) * exp(-pow((s - 0.9) / 0.7, 2.0));
  col += SHEEN * smoothstep(0.35, 0.0, uv.y);
  col *= 1.0 - SHADOW * max(-facing, 0.0) * exp(-s / 14.0) * (1.0 - exp(-s / 2.0));

  return vec4(col, 1.0);
}
