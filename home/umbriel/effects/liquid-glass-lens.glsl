// Liquid-glass backdrop, lens variant: a port of liquidglass.dev's optics
// (lib/liquid-glass.js, renderLensMap) to Umbriel's backdrop effect kind
// (patches/umbriel-backdrop-effect.patch), tuned to
//   <lg-lens radius="21" refraction="60" bezel="0.3" curvature="3.5"
//            chroma="0.35" blur="4" specular="0.1">
// The rim is a rounded bevel of height h(s) = (1 - (1-s)^k)^(1/k); a ray
// through it refracts by Snell's law, so the edge shows the backdrop from
// further inside (a convex, magnifying rim). The frost is the compositor's
// blur ([appearance.blur]); the web version blurs first and then bends, so
// sampling umbriel_sample at the bent position is the same pipeline.
//
// Differences from the web version, on purpose:
// - BEZEL is a fixed width in px, not a fraction of the half-size, so large
//   windows don't get a 150 px rim (0.3 x 140 px = 42 px in the demo).
// - The normal is smoothed at the corners (no diagonal seams), and the bend
//   is continuous (the web map is 8-bit).
// - The window's own corner radius is used, not radius="21".

const float REFRACTION = 60.0; // bend at the very edge, logical px
const float BEZEL = 42.0;      // width of the curved rim, logical px
const float CURVATURE = 3.5;   // rim profile exponent: 2 circular, higher = steeper
const float IOR = 1.5;         // index of refraction
const float CHROMA = 0.35;     // blue bends (1 + CHROMA)x, green (1 + CHROMA/2)x as far as red
const float SPECULAR = 0.1;    // rim highlight strength
const float SPECULAR_W = 2.0;  // rim highlight width, px (glow reaches 5x this)
const float LIGHT = -120.0;    // light direction, degrees; 0 = from the right, -90 = from the top

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Normalised bend for s = depth / bezel in [0, 1]: 1 at the edge, 0 past the bezel.
float profile(float s) {
  if (s >= 1.0) {
    return 0.0;
  }
  float a = pow(1.0 - s, CURVATURE);
  float slope = pow(1.0 - s, CURVATURE - 1.0) * pow(max(1.0 - a, 1e-6), 1.0 / CURVATURE - 1.0);
  float th = atan(slope);
  float bend = tan(th - asin(sin(th) / IOR));
  // The bend grows with the tilt, so it peaks at the edge (tilt 90 degrees).
  return bend / tan(1.5707963 - asin(1.0 / IOR));
}

vec4 backdrop(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  vec2 p = uv * umbriel_size - halfSize;
  // The window's own corner radius (tl, tr, br, bl), as Umbriel rounds it.
  vec4 c = umbriel_corner_radius;
  float r = p.y < 0.0 ? (p.x < 0.0 ? c.x : c.y) : (p.x < 0.0 ? c.w : c.z);
  r = min(r, min(halfSize.x, halfSize.y));
  float s = max(-sdRoundBox(p, halfSize, r), 0.0);  // px in from the edge

  // Smooth outward direction: a wide difference keeps the corners from creasing.
  float h = 3.0;
  vec2 g = vec2(
    sdRoundBox(p + vec2(h, 0.0), halfSize, r) - sdRoundBox(p - vec2(h, 0.0), halfSize, r),
    sdRoundBox(p + vec2(0.0, h), halfSize, r) - sdRoundBox(p - vec2(0.0, h), halfSize, r));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);

  // Small windows: keep the rim within half the shorter side.
  float bezel = min(BEZEL, min(halfSize.x, halfSize.y) * 0.5);
  float m = profile(s / bezel);
  // Never bend past the centre line, so small windows don't sample outside.
  float px = min(m * REFRACTION, min(halfSize.x, halfSize.y) / (1.0 + CHROMA));
  vec2 off = -n * px / umbriel_size;  // inward: convex glass

  vec3 col = m > 0.0
    ? vec3(umbriel_sample(uv + off).r,
           umbriel_sample(uv + off * (1.0 + CHROMA * 0.5)).g,
           umbriel_sample(uv + off * (1.0 + CHROMA)).b)
    : umbriel_sample(uv).rgb;

  // Rim highlight: a crisp line and a softer glow, brightest where the edge
  // faces the light, a dim reflection on the far side.
  float la = radians(LIGHT);
  float facing = dot(n, vec2(cos(la), sin(la)));
  float shade = 0.12 + 0.88 * (facing > 0.0 ? facing : -0.4 * facing);
  float crisp = max(0.0, 1.0 - s / SPECULAR_W);
  float glow = max(0.0, 1.0 - s / (SPECULAR_W * 5.0));
  col += min(1.0, SPECULAR * (crisp * crisp + 0.3 * glow * glow) * shade);

  return vec4(col, 1.0);
}
