// Liquid glass for layer surfaces (Noctalia bar, dock, panels, OSD; Vicinae),
// lens variant: the optics of liquid-glass-lens.glsl (liquidglass.dev's
// refracting bevel plus kube.io's coloured rim) on the edge search of
// liquid-glass-layer.glsl. umbriel_shape(uv) is the coverage of the shape the
// client draws (its alpha past blur_ignore_alpha), so the rim follows the
// capsules and panels instead of the layer's rectangle.
//
// The edge search only reaches REACH px, so the bevel is at most that wide.
// Thin shapes (a bar capsule) get a narrower bevel and a smaller bend: the
// thickness along the normal is measured, and the bend never samples past
// half of it.
//
// The outline is antialiased from a box filter of the mask (cover), and the
// thickness is measured to a fraction of a pixel so the bevel does not jump.

const float REACH = 60.0;      // how far the edge search looks, logical px
const float REFRACTION = 60.0; // bend at the very edge, logical px
const float BEZEL = 120.0;      // width of the curved rim, px (at most REACH)
const float CURVATURE = 3.7;   // rim profile exponent
const float IOR = 1.91;         // index of refraction
const float CHROMA = 0.88;     // blue bends (1 + CHROMA)x, green (1 + CHROMA/2)x as far as red
const float SPECULAR = 0.16;    // white rim highlight strength
const float SPECULAR_W = 1.6;  // white rim width, px (glow reaches 5x this)
const float LIGHT = -120.0;    // white rim light direction, degrees
const float RIM_OPACITY = 0.4;     // coloured rim (kube.io): how much it shows
const float RIM_SATURATION = 6.0;  // saturation of the backdrop in it
const float RIM_WHITE = 0.16;       // white over it, fraction of its opacity
const float RIM_W = 2.0;           // its width, px
const float RIM_LIGHT = -60.0;     // its light direction, degrees
const float LIGHT_TINT = 1.0;      // edge light colour: 0 white, 1 the backdrop just outside the edge
const float LIGHT_OUT = 6.0;       // how far outside the edge that colour is taken, px (padding is 8)
const float LIGHT_WHITE = 0.25;    // white kept in the tinted light, so dark backdrops still give a highlight

bool outside(vec2 uv, vec2 dir, float px) {
  return umbriel_shape(uv + dir * px / umbriel_size) < 0.5;
}

// x: px from the nearest edge (REACH when none is closer); yz: outward normal.
vec3 edge(vec2 uv) {
  // Deep inside a large shape: no edge within REACH in 8 directions.
  bool near = false;
  for (int i = 0; i < 8; i++) {
    float a = float(i) * 0.785398;
    if (outside(uv, vec2(cos(a), sin(a)), REACH)) {
      near = true;
    }
  }
  if (!near) {
    return vec3(REACH, 0.0, 0.0);
  }
  float best = REACH;
  vec2 bestDir = vec2(0.0);
  vec2 normal = vec2(0.0);
  for (int i = 0; i < 16; i++) {
    float a = float(i) * 0.392699;
    vec2 d = vec2(cos(a), sin(a));
    for (int k = 1; k <= 14; k++) {
      float t = float(k) * 2.0;
      if (t > best + 2.0) {
        break;
      }
      if (outside(uv, d, t)) {
        normal += d / (t * t);
        if (t < best) {
          best = t;
          bestDir = d;
        }
        break;
      }
    }
  }
  if (best >= REACH) {
    return vec3(REACH, 0.0, 0.0);
  }
  // Refine the crossing along the nearest direction to a fraction of a pixel.
  float lo = max(best - 2.0, 0.0);
  float hi = best;
  for (int j = 0; j < 4; j++) {
    float mid = 0.5 * (lo + hi);
    if (outside(uv, bestDir, mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  vec2 n = length(normal) > 0.0 ? normalize(normal) : bestDir;
  return vec3(0.5 * (lo + hi), n);
}

// Thickness of the shape along -n from uv: px to the opposite edge, coarse
// 8 px steps refined to a fraction of a pixel (a coarse value makes the bevel
// width jump where the normal turns into a rounded end: a visible seam).
float depth(vec2 uv, vec2 n) {
  for (int k = 1; k <= 32; k++) {
    float t = float(k) * 8.0;
    if (outside(uv, -n, t)) {
      float lo = t - 8.0;
      float hi = t;
      for (int j = 0; j < 6; j++) {
        float mid = 0.5 * (lo + hi);
        if (outside(uv, -n, mid)) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      return 0.5 * (lo + hi);
    }
  }
  return 1000.0;
}

// Coverage of the pixel at uv by the shape, from a 5x5 box of the mask at
// 1 px spacing. Noctalia draws its capsules with hard edges and the layer is
// clipped by an on/off stencil, so the outline is a staircase; averaging the
// mask gives the outermost pixels fractional coverage along it. The mask
// reaches about 2 px past the stencil, so the visible outermost pixel averages
// only 0.82 to 0.87 (measured on the bar, 2026-11-10); COVER_LO..COVER_HI
// stretches that to roughly 0.3 there and 0.8 one pixel in.
const float COVER_LO = 0.74;
const float COVER_HI = 0.98;

float cover(vec2 uv) {
  float c = 0.0;
  for (int i = -2; i <= 2; i++) {
    for (int j = -2; j <= 2; j++) {
      c += umbriel_shape(uv + vec2(float(i), float(j)) / umbriel_size);
    }
  }
  return clamp((c / 25.0 - COVER_LO) / (COVER_HI - COVER_LO), 0.0, 1.0);
}

float profile(float s) {
  if (s >= 1.0) {
    return 0.0;
  }
  float a = pow(1.0 - s, CURVATURE);
  float slope = pow(1.0 - s, CURVATURE - 1.0) * pow(max(1.0 - a, 1e-6), 1.0 / CURVATURE - 1.0);
  float th = atan(slope);
  return tan(th - asin(sin(th) / IOR)) / tan(1.5707963 - asin(1.0 / IOR));
}

vec4 backdrop(vec2 uv) {
  vec3 e = edge(uv);
  float s = e.x;
  vec2 n = e.yz;
  if (s >= REACH) {
    return vec4(umbriel_sample(uv).rgb, 1.0);
  }

  float thick = s + depth(uv, n);
  float bezel = min(BEZEL, thick * 0.3);
  float m = profile(s / bezel);
  float px = min(m * REFRACTION, 0.5 * thick / (1.0 + CHROMA));
  vec2 off = -n * px / umbriel_size;
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
  // Edge light coloured by what is behind: the blurred backdrop just outside
  // the edge, brought up to full brightness so it still reads as light.
  vec3 around = umbriel_sample(uv + n * (s + LIGHT_OUT) / umbriel_size).rgb;
  vec3 hue = around / max(max(around.r, max(around.g, around.b)), 0.05);
  vec3 light = mix(vec3(1.0), mix(hue, vec3(1.0), LIGHT_WHITE), LIGHT_TINT);

  col += light * min(1.0, SPECULAR * (crisp * crisp + 0.3 * glow * glow) * shade);

  float ra = radians(RIM_LIGHT);
  float edgeW = max(0.0, 1.0 - s / RIM_W);
  float rim = RIM_OPACITY * edgeW * edgeW * abs(dot(n, vec2(cos(ra), sin(ra))));
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = mix(col, max(mix(vec3(lum), col, RIM_SATURATION), 0.0), rim);
  col = mix(col, light, rim * RIM_WHITE);

  float a = s < 5.0 ? cover(uv) : 1.0;
  return vec4(col * a, a);
}
