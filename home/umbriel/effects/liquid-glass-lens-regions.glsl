// Liquid glass in the shapes a client names over umbriel_glass_v1
// (patches/umbriel-glass-regions.patch): each rounded rectangle is a lens of
// liquid-glass-lens.glsl's optics, with the same tuned constants (keep them
// in step), sized to the shape: the bevel is at most half the shorter half
// side, so small controls get a narrow rim. Outside every shape nothing is
// drawn, so the rest of the window shows the desktop unblurred. Shapes are
// window-geometry px; the nearest shape gives the edge and its direction.

uniform vec4 umbriel_glass_rect_a[8];   // shapes 0-7: x, y, width, height
uniform vec4 umbriel_glass_rect_b[8];   // shapes 8-15
uniform vec4 umbriel_glass_radius[4];   // corner radius of shape 4i+j in component j
uniform float umbriel_glass_count;

const float REFRACTION = 47.0; // bend at the very edge, logical px
const float BEZEL = 61.0;      // width of the curved rim, logical px
const float CURVATURE = 4.8;   // rim profile exponent: 2 circular, higher = steeper
const float IOR = 2.12;         // index of refraction
const float CHROMA = 0.8;     // blue bends (1 + CHROMA)x, green (1 + CHROMA/2)x as far as red
const float SPECULAR = 0.06;    // rim highlight strength
const float SPECULAR_W = 6.6;  // rim highlight width, px (glow reaches 5x this)
const float LIGHT = 41.0;    // light direction, degrees; 0 = from the right, -90 = from the top
// Coloured rim as kube.io/blog/liquid-glass-css-svg builds it: in a thin rim,
// lit on the side facing the light and the opposite side, the bent backdrop
// is shown heavily saturated, with a faint white line over it.
const float RIM_OPACITY = 0.48;     // how much the rim shows (kube.io: 0.2 to 0.5)
const float RIM_SATURATION = 3.5;  // saturation of the backdrop in the rim (kube.io: 4 to 9)
const float RIM_WHITE = 0.17;       // white over the rim, fraction of its opacity
const float RIM_W = 4.6;           // rim width, px
const float RIM_LIGHT = -53.0;     // rim light direction, degrees (kube.io default: up-right)

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


float pick(vec4 v, int c) { return c == 0 ? v.x : (c == 1 ? v.y : (c == 2 ? v.z : v.w)); }

// Nearest shape so far: signed distance, centre, half size, radius.
float gSd = 1e6;
vec2 gCentre = vec2(0.0);
vec2 gHalf = vec2(1.0);
float gR = 0.0;

void consider(vec2 px, vec4 rect, float radius) {
  vec2 h = rect.zw * 0.5;
  vec2 c = rect.xy + h;
  float r = min(radius, min(h.x, h.y));
  float d = sdRoundBox(px - c, h, r);
  if (d < gSd) {
    gSd = d;
    gCentre = c;
    gHalf = h;
    gR = r;
  }
}

vec4 backdrop(vec2 uv) {
  vec2 px = uv * umbriel_size;
  // GLSL ES 1.00 indexes uniform arrays only by loop indices, hence two loops.
  for (int i = 0; i < 8; i++) {
    if (float(i) >= umbriel_glass_count) {
      break;
    }
    consider(px, umbriel_glass_rect_a[i], pick(umbriel_glass_radius[i / 4], i - (i / 4) * 4));
  }
  for (int i = 0; i < 8; i++) {
    if (float(i + 8) >= umbriel_glass_count) {
      break;
    }
    consider(px, umbriel_glass_rect_b[i], pick(umbriel_glass_radius[2 + i / 4], i - (i / 4) * 4));
  }
  float sd = gSd;
  vec2 centre = gCentre;
  vec2 halfSize = gHalf;
  float r = gR;
  float cover = clamp(0.5 - sd, 0.0, 1.0);
  if (cover <= 0.0) {
    return vec4(0.0);
  }
  vec2 p = px - centre;
  float s = max(-sd, 0.0);  // px in from the edge

  // As liquid-glass-lens.glsl: bend direction from the shape rounded to at least the bevel.
  float bezel = min(BEZEL, min(halfSize.x, halfSize.y) * 0.5);
  float rn = min(max(r, bezel), min(halfSize.x, halfSize.y));
  float hh = 3.0;
  vec2 g = vec2(
    sdRoundBox(p + vec2(hh, 0.0), halfSize, rn) - sdRoundBox(p - vec2(hh, 0.0), halfSize, rn),
    sdRoundBox(p + vec2(0.0, hh), halfSize, rn) - sdRoundBox(p - vec2(0.0, hh), halfSize, rn));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);

  float m = profile(s / bezel);
  float bend = min(m * REFRACTION, min(halfSize.x, halfSize.y) / (1.0 + CHROMA));
  vec2 off = -n * bend / umbriel_size;  // inward: convex glass

  vec3 col = m > 0.0
    ? vec3(umbriel_sample(uv + off).r,
           umbriel_sample(uv + off * (1.0 + CHROMA * 0.5)).g,
           umbriel_sample(uv + off * (1.0 + CHROMA)).b)
    : umbriel_sample(uv).rgb;

  float la = radians(LIGHT);
  float facing = dot(n, vec2(cos(la), sin(la)));
  float shade = 0.12 + 0.88 * (facing > 0.0 ? facing : -0.4 * facing);
  float crisp = max(0.0, 1.0 - s / SPECULAR_W);
  float glow = max(0.0, 1.0 - s / (SPECULAR_W * 5.0));
  col += min(1.0, SPECULAR * (crisp * crisp + 0.3 * glow * glow) * shade);

  float ra = radians(RIM_LIGHT);
  float edge = max(0.0, 1.0 - s / RIM_W);
  float rim = RIM_OPACITY * edge * edge * abs(dot(n, vec2(cos(ra), sin(ra))));
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  vec3 vivid = max(mix(vec3(lum), col, RIM_SATURATION), 0.0);
  col = mix(col, vivid, rim);
  col = mix(col, vec3(1.0), rim * RIM_WHITE);

  return vec4(col * cover, cover);
}
